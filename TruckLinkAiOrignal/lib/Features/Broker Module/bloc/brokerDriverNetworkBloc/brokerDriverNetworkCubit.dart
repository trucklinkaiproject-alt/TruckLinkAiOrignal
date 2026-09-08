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

  /// Fetches and listens in real-time to accepted network Drivers belonging ONLY to the currently logged-in Broker.
  /// Firestore Path: Broker/{currentBrokerId}/DriverNetwork
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

  @override
  Future<void> close() async {
    await _networkSubscription?.cancel();
    return super.close();
  }
}
