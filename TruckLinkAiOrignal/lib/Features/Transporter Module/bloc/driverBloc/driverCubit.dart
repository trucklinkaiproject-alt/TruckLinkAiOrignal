import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/Models/driverModel.dart';
import 'package:trucklinkai_orignal/Features/Transporter%20Module/bloc/driverBloc/driverState.dart';

class DriverCubit extends Cubit<DriverState> {
  DriverCubit() : super(DriverInitialState());

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _driverSubscription;

  DriverModel? _currentDriver;
  String? _lastLocationStatus;


  Future<void> fetchDriverData() async {
    try {
      if (isClosed) return;

      emit(DriverLoadingState());

      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!isClosed) {
          emit(DriverErrorState("No authenticated driver found."));
        }
        return;
      }

      final String uid = currentUser.uid;

      _driverSubscription?.cancel();


      _driverSubscription = _firestore
          .collection("Driver")
          .doc(uid)
          .snapshots()
          .listen(
        (snapshot) async {
          if (isClosed) return;

          if (snapshot.exists && snapshot.data() != null) {
            _currentDriver = DriverModel.fromSnapshot(snapshot);
            await _evaluateAndEmitState();
          } else {

            final initialData = DriverModel.createInitialData(
              uid: uid,
              name: currentUser.displayName ?? '',
              email: currentUser.email ?? '',
              phone: currentUser.phoneNumber ?? '',
              role: 'Driver',
            );

            await _firestore.collection("Driver").doc(uid).set(initialData);
          }
        },
        onError: (error) {
          if (!isClosed) {
            emit(DriverErrorState(error.toString()));
          }
        },
      );


      updateDriverLocation();
    } catch (e) {
      if (!isClosed) {
        emit(DriverErrorState(e.toString()));
      }
    }
  }


  Future<void> _evaluateAndEmitState() async {
    if (isClosed || _currentDriver == null) return;

    final driver = _currentDriver!;
    DriverBrokerRelationshipStatus relationshipStatus =
        DriverBrokerRelationshipStatus.noBroker;
    String? brokerName;
    String? targetBrokerId;
    String? targetBrokerName;


    if (driver.brokerId != null && driver.brokerId!.trim().isNotEmpty) {
      relationshipStatus = DriverBrokerRelationshipStatus.connected;
      targetBrokerId = driver.brokerId;

      try {
        final brokerDoc =
            await _firestore.collection("Broker").doc(driver.brokerId).get();
        if (brokerDoc.exists) {
          brokerName = brokerDoc.data()?['name'] as String?;
          targetBrokerName = brokerName;
        }
      } catch (_) {}
    } else if (driver.requestStatus == 'pending' &&
        driver.activeRequestBrokerId != null &&
        driver.activeRequestBrokerId!.trim().isNotEmpty) {

      relationshipStatus = DriverBrokerRelationshipStatus.requestPending;
      targetBrokerId = driver.activeRequestBrokerId;
      targetBrokerName = driver.activeRequestBrokerName;

      if ((targetBrokerName == null || targetBrokerName.isEmpty) &&
          targetBrokerId != null) {
        try {
          final brokerDoc =
              await _firestore.collection("Broker").doc(targetBrokerId).get();
          if (brokerDoc.exists) {
            targetBrokerName = brokerDoc.data()?['name'] as String?;
          }
        } catch (_) {}
      }
    } else if (driver.requestStatus == 'rejected' &&
        driver.activeRequestBrokerId != null &&
        driver.activeRequestBrokerId!.trim().isNotEmpty) {

      relationshipStatus = DriverBrokerRelationshipStatus.requestRejected;
      targetBrokerId = driver.activeRequestBrokerId;
      targetBrokerName = driver.activeRequestBrokerName;

      if ((targetBrokerName == null || targetBrokerName.isEmpty) &&
          targetBrokerId != null) {
        try {
          final brokerDoc =
              await _firestore.collection("Broker").doc(targetBrokerId).get();
          if (brokerDoc.exists) {
            targetBrokerName = brokerDoc.data()?['name'] as String?;
          }
        } catch (_) {}
      }
    } else {

      relationshipStatus = DriverBrokerRelationshipStatus.noBroker;
    }

    if (!isClosed) {
      emit(DriverLoadedState(
        driver: driver,
        brokerName: brokerName,
        locationStatus: _lastLocationStatus,
        relationshipStatus: relationshipStatus,
        targetBrokerId: targetBrokerId,
        targetBrokerName: targetBrokerName,
      ));
    }
  }


  Future<void> updateDriverLocation() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      final String uid = currentUser.uid;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocalLocationStatus("Location services disabled");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setLocalLocationStatus("Location permission denied");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setLocalLocationStatus("Location permission permanently denied");
        return;
      }


      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );


      await _firestore.collection("Driver").doc(uid).update({
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
      });

      _setLocalLocationStatus("Location updated");
    } catch (e) {
      _setLocalLocationStatus("Location error: ${e.toString()}");
    }
  }


  Future<bool> saveTruckDetails({
    required String vehicleNumber,
    required String vehicleType,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        if (!isClosed) emit(DriverErrorState("No authenticated driver found."));
        return false;
      }
      final String uid = currentUser.uid;

      final trimmedNumber = vehicleNumber.trim();
      final trimmedType = vehicleType.trim();

      if (trimmedNumber.isEmpty || trimmedType.isEmpty) {
        if (!isClosed) emit(DriverErrorState("Both Vehicle Number and Vehicle Type are required."));
        return false;
      }

      await _firestore.collection("Driver").doc(uid).set({
        'vehicle_number': trimmedNumber,
        'vehicle_type': trimmedType,
        'truck_details_completed': true,
        'onboarding_completed': true,
        'vehicle_available': true,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      final effectiveBrokerId = _currentDriver?.brokerId;
      if (effectiveBrokerId != null && effectiveBrokerId.isNotEmpty) {
        try {
          await _firestore
              .collection("Broker")
              .doc(effectiveBrokerId)
              .collection("DriverNetwork")
              .doc(uid)
              .set({
            'vehicle_number': trimmedNumber,
            'vehicle_type': trimmedType,
            'truck_details_completed': true,
            'onboarding_completed': true,
            'vehicle_available': true,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }

      return true;
    } catch (e) {
      if (!isClosed) emit(DriverErrorState("Failed to save truck details: ${e.toString()}"));
      return false;
    }
  }


  Future<void> updateDriverAvailability(String status) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;
      final String uid = currentUser.uid;

      final bool isOnline = status == 'online';


      if (!isOnline && (_currentDriver?.isOnRide == true || _currentDriver?.availabilityStatus == 'on_ride')) {
        if (!isClosed) {
          emit(DriverErrorState("Cannot switch to offline while an active shipment ride is in progress."));
        }
        return;
      }

      await _firestore.collection("Driver").doc(uid).set({
        'availability_status': status,
        'status': isOnline ? 'active' : 'offline',
        'vehicle_available': isOnline,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      if (_currentDriver?.brokerId != null && _currentDriver!.brokerId!.isNotEmpty) {
        try {
          await _firestore
              .collection("Broker")
              .doc(_currentDriver!.brokerId)
              .collection("DriverNetwork")
              .doc(uid)
              .set({
            'availability_status': status,
            'status': isOnline ? 'active' : 'offline',
            'vehicle_available': isOnline,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }
    } catch (e) {
      if (!isClosed) emit(DriverErrorState("Failed to update availability: $e"));
    }
  }

  void _setLocalLocationStatus(String status) {
    _lastLocationStatus = status;
    _evaluateAndEmitState();
  }

  void stopListening() {
    _driverSubscription?.cancel();
    _driverSubscription = null;
  }

  @override
  Future<void> close() async {
    await _driverSubscription?.cancel();
    return super.close();
  }
}
