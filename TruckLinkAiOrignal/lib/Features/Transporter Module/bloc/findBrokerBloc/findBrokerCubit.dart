import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Models/driverModel.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/findBrokerBloc/findBrokerState.dart';

class FindBrokerCubit extends Cubit<FindBrokerState> {
  FindBrokerCubit() : super(FindBrokerInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _allBrokers = [];
  Set<String> _requestedBrokerIds = {};
  String _currentQuery = '';

  /// Fetches available brokers from existing "Broker" collection and checks for pending join requests.
  Future<void> fetchBrokers({required String driverId}) async {
    try {
      if (isClosed) return;
      emit(FindBrokerLoadingState());

      // Fetch all brokers from the existing Broker collection
      final QuerySnapshot snapshot = await _firestore.collection("Broker").get();

      _allBrokers = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();

      // Check which brokers have pending requests from this driver
      _requestedBrokerIds = {};
      for (var broker in _allBrokers) {
        final String brokerId = broker["id"] as String;
        try {
          final requestDoc = await _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("DriverRequests")
              .doc(driverId)
              .get();

          if (requestDoc.exists) {
            final data = requestDoc.data();
            if (data != null && (data['status'] == 'pending' || data['status'] == 'requested')) {
              _requestedBrokerIds.add(brokerId);
            }
          }
        } catch (_) {}
      }

      _applyFilter();
    } catch (e) {
      if (!isClosed) {
        emit(FindBrokerErrorState("Failed to load brokers: ${e.toString()}"));
      }
    }
  }

  /// Filters brokers by name
  void searchBrokers(String query) {
    _currentQuery = query.trim().toLowerCase();
    _applyFilter();
  }

  void _applyFilter() {
    if (isClosed) return;

    List<Map<String, dynamic>> filtered = _allBrokers.where((b) {
      final name = (b['name'] ?? '').toString().toLowerCase();
      return _currentQuery.isEmpty || name.contains(_currentQuery);
    }).toList();

    emit(FindBrokerLoadedState(
      allBrokers: List.from(_allBrokers),
      filteredBrokers: filtered,
      requestedBrokerIds: Set.from(_requestedBrokerIds),
      searchQuery: _currentQuery,
    ));
  }

  /// Sends a join request from a Driver to a Broker following all business rules.
  /// IMPORTANT: Sending a request DOES NOT add the Driver to the Broker's network.
  /// The request is created in Firestore with status = "pending".
  Future<void> sendJoinRequest({
    required DriverModel driver,
    required Map<String, dynamic> broker,
  }) async {
    final String brokerId = (broker['id'] ?? broker['uid'] ?? '').toString().trim();
    final String brokerName = (broker['name'] ?? 'Broker').toString();

    // STRICT BUSINESS RULE: Driver MUST complete Truck details before requesting a Broker
    if (!driver.isTruckDetailsComplete) {
      emit(FindBrokerErrorState(
        "Please complete your truck details before joining a Broker.",
      ));
      return;
    }

    // RULE 1: Driver already connected to a Broker cannot request another Broker
    if (driver.brokerId != null && driver.brokerId!.trim().isNotEmpty) {
      emit(FindBrokerErrorState(
        "You are already connected to a Broker network. You cannot request another Broker.",
      ));
      return;
    }

    // RULE 2: Validate Broker ID
    if (brokerId.isEmpty) {
      emit(FindBrokerErrorState("Invalid Broker ID."));
      return;
    }

    try {
      final brokerDoc = await _firestore.collection("Broker").doc(brokerId).get();
      if (!brokerDoc.exists) {
        emit(FindBrokerErrorState("Broker does not exist or has an invalid ID."));
        return;
      }

      // RULE 3: Driver cannot select himself as a Broker
      if (brokerId == driver.uid || brokerId == driver.driverId) {
        emit(FindBrokerErrorState("You cannot select yourself as a Broker."));
        return;
      }

      // RULE 4: Prevent duplicate active requests
      if (driver.requestStatus == 'pending' || _requestedBrokerIds.isNotEmpty) {
        final String pendingName = driver.activeRequestBrokerName ?? 'a Broker';
        emit(FindBrokerErrorState(
          "You already have a pending join request sent to $pendingName. You cannot send another request while a request is pending.",
        ));
        return;
      }

      emit(FindBrokerSendingRequestState(brokerId));

      // Create Join Request document in Firestore under Broker/{brokerId}/DriverRequests/{requestId}
      // Status is set to "pending". Note: driver.brokerId remains null/unchanged.
      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverRequests")
          .doc(driver.uid)
          .set({
        'driver_id': driver.uid,
        'broker_id': brokerId,
        'driverId': driver.uid,
        'brokerId': brokerId,
        'broker_name': brokerName,
        'brokerName': brokerName,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'name': driver.name,
        'driver_name': driver.name,
        'email': driver.email,
        'driver_email': driver.email,
        'phone': driver.phone,
        'driver_phone': driver.phone,
        'vehicle_number': driver.vehicleNumber,
        'vehicle_type': driver.vehicleType,
        'driver_rating': driver.driverRating,
        'total_trips': driver.totalTrips,
        'completed_trips': driver.completedTrips,
        'cancelled_trips': driver.cancelledTrips,
      });

      // Update Driver document with active request info (without setting broker_id)
      await _firestore.collection("Driver").doc(driver.uid).update({
        'active_request_broker_id': brokerId,
        'active_request_broker_name': brokerName,
        'request_status': 'pending',
      });

      _requestedBrokerIds.add(brokerId);

      emit(FindBrokerSuccessState(
        "Join request sent successfully to $brokerName!",
      ));

      _applyFilter();
    } catch (e) {
      emit(FindBrokerErrorState("Failed to send join request: ${e.toString()}"));
    }
  }
}
