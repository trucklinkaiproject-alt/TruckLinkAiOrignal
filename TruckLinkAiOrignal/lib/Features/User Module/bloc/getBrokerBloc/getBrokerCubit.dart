import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/getBrokerBloc/getBrokerState.dart';

class GetBrokerCubit extends Cubit<GetBrokerState> {
  GetBrokerCubit() : super(GetBrokerInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> brokers = [];
  Map<String, dynamic> selectedBroker = {};
  StreamSubscription<QuerySnapshot>? _brokerSubscription;
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
    } catch (e) {
      debugPrint("GetBrokerCubit error checking broker network vehicles: $e");
    }

    return false;
  }

  /// Fetches and listens to brokers filtered by:
  /// 1. Broker is currently ONLINE
  /// 2. Broker has at least ONE driver in their network with the required vehicle type
  void listenToEligibleBrokers(String requiredVehicleType) {
    try {
      if (isClosed) return;
      _activeVehicleTypeFilter = requiredVehicleType.trim();
      emit(GetBrokerLoadingState());

      _brokerSubscription?.cancel();
      _brokerSubscription = _firestore.collection("Broker").snapshots().listen(
        (snapshot) async {
          if (isClosed) return;

          final allBrokers = snapshot.docs.map((doc) {
            return {
              "id": doc.id,
              "brokerId": doc.id,
              "uid": doc.id,
              ...doc.data(),
            };
          }).toList();

          final List<Map<String, dynamic>> eligibleBrokers = [];

          for (final broker in allBrokers) {
            // CONDITION 1: Broker must be currently Online
            if (!isBrokerOnline(broker)) {
              continue;
            }

            // CONDITION 2: Broker must have at least one driver with required vehicle type
            final String brokerId = (broker['brokerId'] ?? broker['uid'] ?? broker['id'] ?? '').toString();
            if (brokerId.isEmpty) continue;

            final bool hasVehicle = await brokerHasRequiredVehicle(
              firestore: _firestore,
              brokerId: brokerId,
              requiredVehicleType: _activeVehicleTypeFilter ?? requiredVehicleType,
            );

            if (hasVehicle) {
              eligibleBrokers.add({
                ...broker,
                'matched_vehicle_type': requiredVehicleType,
                'is_online': true,
              });
            }
          }

          if (isClosed) return;

          brokers = eligibleBrokers;
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

  @override
  Future<void> close() {
    _brokerSubscription?.cancel();
    return super.close();
  }
}
