import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerDriverNetworkBloc/brokerDriverNetworkState.dart';

class BrokerDriverNetworkCubit extends Cubit<BrokerDriverNetworkState> {
  BrokerDriverNetworkCubit() : super(BrokerDriverNetworkInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _networkSubscription;


  Future<void> fetchNetworkDrivers() async {
    try {
      if (isClosed) return;
      emit(BrokerDriverNetworkLoadingState());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!isClosed) {
          emit(BrokerDriverNetworkErrorState("No authenticated Broker found."));
        }
        return;
      }

      final String brokerId = currentUser.uid;

      _networkSubscription?.cancel();
      _networkSubscription = _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverNetwork")
          .snapshots()
          .listen(
        (snapshot) {
          if (isClosed) return;

          final networkDrivers = snapshot.docs
              .map((doc) => {
                    "id": doc.id,
                    ...doc.data(),
                  })
              .toList();

          emit(BrokerDriverNetworkLoadedState(List.from(networkDrivers)));
        },
        onError: (error) {
          if (!isClosed) {
            emit(BrokerDriverNetworkErrorState(error.toString()));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(BrokerDriverNetworkErrorState(e.toString()));
      }
    }
  }

  void stopListening() {
    _networkSubscription?.cancel();
    _networkSubscription = null;
  }

  bool _removing = false;


  static const List<String> _blockingOfferStatuses = [
    'pending',
    'driver_offer_sent',
    'accepted_by_driver',
    'accepted',
    'in_progress',
    'in_transit',
    'arrived_at_pickup',
    'heading_to_drop',
  ];


  Future<String?> removeDriverFromNetwork(String driverId) async {
    if (_removing) return "A removal is already in progress.";
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "No authenticated Broker found.";
    if (driverId.trim().isEmpty) return "Invalid driver.";

    _removing = true;
    try {
      final String brokerId = currentUser.uid;


      final offers = await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .where('status', whereIn: _blockingOfferStatuses)
          .get();
      final bool hasActive = offers.docs.any(
        (d) => (d.data()['broker_id'] ?? '').toString() == brokerId,
      );
      if (hasActive) {
        return "Driver cannot be removed while an active trip/order is in progress.";
      }

      final networkRef = _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("DriverNetwork")
          .doc(driverId);
      final driverRef = _firestore.collection("Driver").doc(driverId);

      await _firestore.runTransaction((txn) async {
        final driverSnap = await txn.get(driverRef);

        txn.delete(networkRef);

        if (driverSnap.exists) {
          final d = driverSnap.data() ?? {};
          final linked = (d['broker_id'] ?? d['brokerId'] ?? '').toString().trim();
          if (linked == brokerId) {
            txn.update(driverRef, {
              'broker_id': null,
              'brokerId': null,
              'broker_name': null,
              'request_status': null,
              'active_request_broker_id': null,
              'active_request_broker_name': null,
              'updated_at': FieldValue.serverTimestamp(),
            });
          }
        }
      });

      return null;
    } on FirebaseException catch (e) {
      return "Failed to remove driver: ${e.message ?? e.code}";
    } catch (e) {
      return "Failed to remove driver: $e";
    } finally {
      _removing = false;
    }
  }

  @override
  Future<void> close() async {
    await _networkSubscription?.cancel();
    return super.close();
  }
}
