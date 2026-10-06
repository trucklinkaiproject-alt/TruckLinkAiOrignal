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


  Future<void> fetchBrokers({required String driverId}) async {
    try {
      if (isClosed) return;
      emit(FindBrokerLoadingState());


      final QuerySnapshot snapshot = await _firestore.collection("Broker").get();

      _allBrokers = snapshot.docs
          .map((doc) => {
                "id": doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();


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


  Future<void> sendJoinRequest({
    required DriverModel driver,
    required Map<String, dynamic> broker,
  }) async {
    final String brokerId = (broker['id'] ?? broker['uid'] ?? '').toString().trim();
    final String brokerName = (broker['name'] ?? 'Broker').toString();


    if (!driver.isTruckDetailsComplete) {
      emit(FindBrokerErrorState(
        "Please complete your truck details before joining a Broker.",
      ));
      return;
    }


    if (driver.brokerId != null && driver.brokerId!.trim().isNotEmpty) {
      emit(FindBrokerErrorState(
        "You are already connected to a Broker network. You cannot request another Broker.",
      ));
      return;
    }


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


      if (brokerId == driver.uid || brokerId == driver.driverId) {
        emit(FindBrokerErrorState("You cannot select yourself as a Broker."));
        return;
      }


      if (driver.requestStatus == 'pending' || _requestedBrokerIds.isNotEmpty) {
        final String pendingName = driver.activeRequestBrokerName ?? 'a Broker';
        emit(FindBrokerErrorState(
          "You already have a pending join request sent to $pendingName. You cannot send another request while a request is pending.",
        ));
        return;
      }

      emit(FindBrokerSendingRequestState(brokerId));


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
