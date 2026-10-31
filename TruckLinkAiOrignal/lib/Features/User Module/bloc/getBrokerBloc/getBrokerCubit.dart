import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerState.dart';

class GetBrokerCubit extends Cubit<GetBrokerState> {
  GetBrokerCubit() : super(GetBrokerInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> brokers = [];
  Map<String, dynamic> selectedBroker = {};
  StreamSubscription<QuerySnapshot>? _brokerSubscription;
  Timer? _debounceTimer;
  String? _activeVehicleTypeFilter;

  /// Helper to check if a broker is currently online
  static bool isBrokerOnline(Map<String, dynamic> brokerData) {
    final rawStatus = (brokerData['availability_status'] ??
            brokerData['status'] ??
            'online')
        .toString()
        .toLowerCase()
        .trim();

    final bool isOffline = rawStatus == 'offline' ||
        brokerData['is_online'] == false ||
        brokerData['isOnline'] == false;

    return !isOffline;
  }

  /// Normalizes vehicle type strings for safe case-insensitive comparison
  static bool matchesVehicleType(String? driverVehicleType, String requiredVehicleType) {
    if (driverVehicleType == null || driverVehicleType.trim().isEmpty) return false;
    final cleanDriver = driverVehicleType
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');
    final cleanReq = requiredVehicleType
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .replaceAll('-', '');

    if (cleanDriver == cleanReq) return true;

    // Handle compound names like "Trailer Truck" vs "Trailer"
    if (cleanDriver.contains(cleanReq) || cleanReq.contains(cleanDriver)) {
      // Ensure it's not a misleading partial match like "Van" in "Caravan"
      if (cleanDriver.startsWith(cleanReq) || cleanDriver.endsWith(cleanReq)) {
        return true;
      }
    }

    return false;
  }

  /// Checks if the Broker has at least one driver in their network with the required vehicle type
  static Future<bool> brokerHasRequiredVehicle({
    required FirebaseFirestore firestore,
    required String brokerId,
    required String requiredVehicleType,
  }) async {
    if (brokerId.isEmpty || requiredVehicleType.isEmpty) return false;

    try {
      // 1. Check Broker's DriverNetwork subcollection
      final networkSnap = await firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverNetwork")
          .get();

      for (final doc in networkSnap.docs) {
        final data = doc.data();
        final String vType = (data['vehicle_type'] ?? data['vehicleType'] ?? '').toString();
        if (matchesVehicleType(vType, requiredVehicleType)) {
          return true;
        }
      }

      // 2. Also check Driver collection where broker_id == brokerId
      final driversSnap = await firestore
          .collection("Driver")
          .where("broker_id", isEqualTo: brokerId)
          .get();

      for (final doc in driversSnap.docs) {
        final data = doc.data();
        final String vType = (data['vehicle_type'] ?? data['vehicleType'] ?? '').toString();
        if (matchesVehicleType(vType, requiredVehicleType)) {
          return true;
        }
      }
    } catch (e, stack) {
      AppLogger.error("GetBrokerCubit error checking broker network vehicles", e, stack, "GetBrokerCubit");
    }

    return false;
  }

  /// Fetches and listens to brokers filtered by:
  /// 1. Broker is currently ONLINE
  /// 2. Broker has at least ONE driver in their network with the required vehicle type
  /// Optimized (Phase 2.12):
  /// - Fast path: checks broker.vehicle_types array without secondary Firestore queries
  /// - Parallel resolution: uses Future.wait instead of sequential awaits
  /// - Debouncing: prevents UI thrashing on frequent broker updates
  void listenToEligibleBrokers(String requiredVehicleType) {
    try {
      if (isClosed) return;
      _activeVehicleTypeFilter = requiredVehicleType.trim();
      emit(GetBrokerLoadingState());

      _brokerSubscription?.cancel();
      _brokerSubscription = _firestore.collection("Broker").snapshots().listen(
        (snapshot) {
          if (isClosed) return;

          _debounceTimer?.cancel();
          _debounceTimer = Timer(const Duration(milliseconds: 250), () async {
            if (isClosed) return;

            final allBrokers = snapshot.docs.map((doc) {
              return {
                "id": doc.id,
                "brokerId": doc.id,
                "uid": doc.id,
                ...doc.data(),
              };
            }).toList();

            final targetVehicle = _activeVehicleTypeFilter ?? requiredVehicleType;

            // Resolve eligible brokers in parallel
            final checkResults = await Future.wait(allBrokers.map((broker) async {
              // CONDITION 1: Broker must be currently Online
              if (!isBrokerOnline(broker)) {
                return null;
              }

              final String brokerId = (broker['brokerId'] ?? broker['uid'] ?? broker['id'] ?? '').toString();
              if (brokerId.isEmpty) return null;

              // FAST PATH: Check maintained vehicle_types array on Broker doc
              final dynamic vTypesRaw = broker['vehicle_types'] ?? broker['vehicleTypes'];
              if (vTypesRaw is List && vTypesRaw.isNotEmpty) {
                final hasMatch = vTypesRaw.any((vt) => matchesVehicleType(vt?.toString(), targetVehicle));
                if (hasMatch) {
                  return {
                    ...broker,
                    'matched_vehicle_type': targetVehicle,
                    'is_online': true,
                  };
                }
                return null;
              }

              // FALLBACK: Query network if array is not populated yet
              final bool hasVehicle = await brokerHasRequiredVehicle(
                firestore: _firestore,
                brokerId: brokerId,
                requiredVehicleType: targetVehicle,
              );

              if (hasVehicle) {
                return {
                  ...broker,
                  'matched_vehicle_type': targetVehicle,
                  'is_online': true,
                };
              }

              return null;
            }));

            if (isClosed) return;

            final eligibleBrokers = checkResults.whereType<Map<String, dynamic>>().toList();
            brokers = eligibleBrokers;
            emit(GetBrokerLoadedState());
          });
        },
        onError: (e, stack) {
          AppLogger.error("Broker stream error", e, stack, "GetBrokerCubit");
          if (!isClosed) emit(GetBrokerErrorState(e.toString()));
        },
      );
    } catch (e, stack) {
      AppLogger.error("listenToEligibleBrokers error", e, stack, "GetBrokerCubit");
      if (!isClosed) emit(GetBrokerErrorState(e.toString()));
    }
  }

  /// Real-time stream of all Broker profiles from Firebase (for general browsing)
  void listenToBrokers() {
    try {
      if (isClosed) return;
      _activeVehicleTypeFilter = null;
      emit(GetBrokerLoadingState());

      _brokerSubscription?.cancel();
      _brokerSubscription = _firestore.collection("Broker").snapshots().listen(
        (snapshot) {
          if (isClosed) return;

          brokers = snapshot.docs
              .map((doc) => {
                    "id": doc.id,
                    "brokerId": doc.id,
                    "uid": doc.id,
                    ...doc.data(),
                  })
              .toList();

          emit(GetBrokerLoadedState());
        },
        onError: (e) {
          if (!isClosed) emit(GetBrokerErrorState(e.toString()));
        },
      );
    } catch (e) {
      if (!isClosed) emit(GetBrokerErrorState(e.toString()));
    }
  }

  Future<void> fetchAllBroker() async {
    listenToBrokers();
  }

  void stopListening() {
    _debounceTimer?.cancel();
    _brokerSubscription?.cancel();
    _brokerSubscription = null;
    brokers.clear();
    selectedBroker.clear();
    _activeVehicleTypeFilter = null;
    if (!isClosed) emit(GetBrokerInitialState());
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    _brokerSubscription?.cancel();
    return super.close();
  }
}

