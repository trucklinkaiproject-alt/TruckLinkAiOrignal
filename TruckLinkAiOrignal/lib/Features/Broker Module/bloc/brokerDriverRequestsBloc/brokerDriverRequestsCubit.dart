import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverRequestsBloc/brokerDriverRequestsState.dart';

class BrokerDriverRequestsCubit extends Cubit<BrokerDriverRequestsState> {
  BrokerDriverRequestsCubit() : super(BrokerDriverRequestsInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _requestsSubscription;
  List<Map<String, dynamic>> _pendingRequests = [];

  /// Fetches and listens to pending Driver join requests belonging strictly to the logged-in Broker.
  Future<void> fetchPendingRequests() async {
    try {
      if (isClosed) return;
      emit(BrokerDriverRequestsLoadingState());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!isClosed) {
          emit(BrokerDriverRequestsErrorState("No authenticated Broker found."));
        }
        return;
      }

      final String brokerId = currentUser.uid;

      _requestsSubscription?.cancel();
      _requestsSubscription = _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverRequests")
          .where("status", isEqualTo: "pending")
          .snapshots()
          .listen(
        (snapshot) {
          if (isClosed) return;

          _pendingRequests = snapshot.docs
              .map((doc) => {
                    "id": doc.id,
                    ...doc.data(),
                  })
              .toList();

          emit(BrokerDriverRequestsLoadedState(List.from(_pendingRequests)));
        },
        onError: (error) {
          if (!isClosed) {
            emit(BrokerDriverRequestsErrorState(error.toString()));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(BrokerDriverRequestsErrorState(e.toString()));
      }
    }
  }

  /// UI/State action to accept a pending Driver request using a Firestore transaction.
  Future<void> acceptRequest({
    required String requestId,
    required String driverId,
    required String driverName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(BrokerDriverRequestsErrorState("No authenticated Broker found."));
        return;
      }
      final String brokerId = currentUser.uid;

      await _firestore.runTransaction((transaction) async {
        // 1. Verify request is still pending
        final requestRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("DriverRequests")
            .doc(requestId);

        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          throw Exception("Join request does not exist.");
        }

        final reqData = requestSnap.data();
        final status = reqData?['status'];
        if (status != 'pending' && status != 'requested') {
          throw Exception("Join request is no longer pending.");
        }

        // 2. Verify Driver exists
        final driverRef = _firestore.collection("Driver").doc(driverId);
        final driverSnap = await transaction.get(driverRef);
        if (!driverSnap.exists) {
          throw Exception("Driver document does not exist.");
        }

        // 3. Verify Driver is not already connected to another Broker
        final driverData = driverSnap.data();
        final existingBrokerId =
            (driverData?['broker_id'] ?? driverData?['brokerId'])
                ?.toString()
                .trim();
        if (existingBrokerId != null &&
            existingBrokerId.isNotEmpty &&
            existingBrokerId != brokerId) {
          throw Exception(
              "Driver is already connected to another Broker network.");
        }

        // 4. Set request status to accepted
        transaction.update(requestRef, {
          'status': 'accepted',
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 5 & 6. Set Driver's broker_id to current Broker UID and update request fields
        transaction.update(driverRef, {
          'broker_id': brokerId,
          'brokerId': brokerId,
          'request_status': 'accepted',
          'active_request_broker_id': null,
          'active_request_broker_name': null,
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 7 & 8. Add Driver to Broker's actual Driver network (using driverId to prevent duplicate records)
        final networkRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("DriverNetwork")
            .doc(driverId);

        transaction.set(networkRef, {
          'driver_id': driverId,
          'driverId': driverId,
          'broker_id': brokerId,
          'brokerId': brokerId,
          'name': driverData?['name'] ?? driverName,
          'driver_name': driverData?['name'] ?? driverName,
          'email': driverData?['email'] ?? reqData?['email'] ?? '',
          'phone': driverData?['phone'] ?? reqData?['phone'] ?? '',
          'vehicle_number':
              driverData?['vehicle_number'] ?? reqData?['vehicle_number'],
          'vehicle_type':
              driverData?['vehicle_type'] ?? reqData?['vehicle_type'],
          'driver_rating':
              driverData?['driver_rating'] ?? reqData?['driver_rating'] ?? 0.0,
          'total_trips':
              driverData?['total_trips'] ?? reqData?['total_trips'] ?? 0,
          'completed_trips': driverData?['completed_trips'] ??
              reqData?['completed_trips'] ??
              0,
          'cancelled_trips': driverData?['cancelled_trips'] ??
              reqData?['cancelled_trips'] ??
              0,
          'addedAt': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active',
        });
      });

      if (!isClosed) {
        emit(BrokerDriverRequestsActionSuccessState(
          "Accepted join request from $driverName.",
        ));
        emit(BrokerDriverRequestsLoadedState(List.from(_pendingRequests)));
      }
    } catch (e) {
      if (!isClosed) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        emit(BrokerDriverRequestsErrorState("Failed to accept request: $errorMsg"));
      }
    }
  }

  /// UI/State action to reject a pending Driver request using a Firestore transaction.
  Future<void> rejectRequest({
    required String requestId,
    required String driverId,
    required String driverName,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        emit(BrokerDriverRequestsErrorState("No authenticated Broker found."));
        return;
      }
      final String brokerId = currentUser.uid;

      await _firestore.runTransaction((transaction) async {
        // 1. Verify request is pending
        final requestRef = _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("DriverRequests")
            .doc(requestId);

        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          throw Exception("Join request does not exist.");
        }

        final status = requestSnap.data()?['status'];
        if (status != 'pending' && status != 'requested') {
          throw Exception("Join request is no longer pending.");
        }

        // 2. Set request status to rejected
        transaction.update(requestRef, {
          'status': 'rejected',
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 3. Update Driver document request_status to rejected (do NOT set broker_id)
        final driverRef = _firestore.collection("Driver").doc(driverId);
        transaction.update(driverRef, {
          'request_status': 'rejected',
          'updated_at': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      if (!isClosed) {
        emit(BrokerDriverRequestsActionSuccessState(
          "Rejected join request from $driverName.",
        ));
        emit(BrokerDriverRequestsLoadedState(List.from(_pendingRequests)));
      }
    } catch (e) {
      if (!isClosed) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        emit(BrokerDriverRequestsErrorState("Failed to reject request: $errorMsg"));
      }
    }
  }

  void stopListening() {
    _requestsSubscription?.cancel();
    _requestsSubscription = null;
  }

  @override
  Future<void> close() async {
    await _requestsSubscription?.cancel();
    return super.close();
  }
}
