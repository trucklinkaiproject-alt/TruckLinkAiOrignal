import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class DriverLocationService {
  static final DriverLocationService _instance = DriverLocationService._internal();
  factory DriverLocationService() => _instance;
  DriverLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicTimer;

  String? _activeOrderId;
  String? _activeDriverId;
  String? _activeBrokerId;
  String? _activeUserUid;
  String? _activeOrderNo;

  double? _pickupLat;
  double? _pickupLng;
  double? _dropLat;
  double? _dropLng;

  bool _isTracking = false;
  bool get isTracking => _isTracking;
  String? get activeOrderId => _activeOrderId;

  Position? _lastRecordedPosition;
  DateTime? _lastFirebaseUpdateTime;

  /// Arrival proximity threshold in meters (250m)
  static const double arrivalThresholdMeters = 250.0;

  /// Minimum interval between Firebase GPS writes to avoid excessive battery drain and writes (approx 60s)
  static const Duration minFirebaseUpdateInterval = Duration(seconds: 45);

  /// Starts real-time GPS tracking for an active ride.
  Future<bool> startTracking({
    required String orderId,
    required String driverId,
    required String brokerId,
    required String userUid,
    required String orderNo,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) async {
    try {
      // If already tracking another order, stop it first
      if (_isTracking) {
        await stopTracking();
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("DriverLocationService: Location service disabled");
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint("DriverLocationService: Location permission denied");
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("DriverLocationService: Location permission permanently denied");
        return false;
      }

      _activeOrderId = orderId;
      _activeDriverId = driverId;
      _activeBrokerId = brokerId;
      _activeUserUid = userUid;
      _activeOrderNo = orderNo;
      _pickupLat = pickupLat;
      _pickupLng = pickupLng;
      _dropLat = dropLat;
      _dropLng = dropLng;
      _isTracking = true;

      // Get initial position immediately
      try {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _lastRecordedPosition = initialPos;
        await _pushLocationToFirebase(initialPos, force: true);
        await _evaluateProximity(initialPos);
      } catch (e) {
        debugPrint("DriverLocationService: Initial pos error: $e");
      }

      // Listen to position stream with distance filter of 20 meters
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          _lastRecordedPosition = position;
          final now = DateTime.now();

          // Push to Firebase if interval has passed
          if (_lastFirebaseUpdateTime == null ||
              now.difference(_lastFirebaseUpdateTime!) >= minFirebaseUpdateInterval) {
            await _pushLocationToFirebase(position);
          }

          // Evaluate proximity to pickup or drop
          await _evaluateProximity(position);
        },
        onError: (error) {
          debugPrint("DriverLocationService: Stream error: $error");
        },
      );

      // Periodic timer ensuring coordinates push at least every 60 seconds even if stationary
      _periodicTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
        if (!_isTracking) {
          timer.cancel();
          return;
        }
        if (_lastRecordedPosition != null) {
          await _pushLocationToFirebase(_lastRecordedPosition!);
        } else {
          try {
            final pos = await Geolocator.getCurrentPosition();
            _lastRecordedPosition = pos;
            await _pushLocationToFirebase(pos);
            await _evaluateProximity(pos);
          } catch (_) {}
        }
      });

      return true;
    } catch (e) {
      debugPrint("DriverLocationService startTracking error: $e");
      return false;
    }
  }

  /// Pushes coordinates to Driver, Orders, Broker, and User documents
  Future<void> _pushLocationToFirebase(Position position, {bool force = false}) async {
    if (!_isTracking || _activeDriverId == null || _activeOrderId == null) return;

    final now = DateTime.now();
    if (!force && _lastFirebaseUpdateTime != null &&
        now.difference(_lastFirebaseUpdateTime!) < const Duration(seconds: 25)) {
      return;
    }

    _lastFirebaseUpdateTime = now;

    final locationPayload = {
      'driver_latitude': position.latitude,
      'driver_longitude': position.longitude,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'last_location_update': FieldValue.serverTimestamp(),
      'driver_id': _activeDriverId,
      'order_id': _activeOrderId,
    };

    try {
      // 1. Update Driver document
      await _firestore.collection("Driver").doc(_activeDriverId).update({
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
        'updated_at': FieldValue.serverTimestamp(),
      });

      // 2. Update Order under Orders
      await _firestore.collection("Orders").doc(_activeOrderId).set(
        locationPayload,
        SetOptions(merge: true),
      );

      // 3. Update Broker IncomingRequests
      if (_activeBrokerId != null && _activeBrokerId!.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(_activeBrokerId)
            .collection("IncomingRequests")
            .doc(_activeOrderId)
            .set(locationPayload, SetOptions(merge: true));
      }

      // 4. Update User Requests
      if (_activeUserUid != null && _activeUserUid!.isNotEmpty) {
        await _firestore
            .collection("User")
            .doc(_activeUserUid)
            .collection("Requests")
            .doc(_activeOrderId)
            .set(locationPayload, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("DriverLocationService _pushLocationToFirebase error: $e");
    }
  }

  /// Evaluates distance to Pickup and Drop and triggers one-time arrival events
  Future<void> _evaluateProximity(Position position) async {
    if (!_isTracking || _activeOrderId == null) return;

    try {
      final orderRef = _firestore.collection("Orders").doc(_activeOrderId);
      final orderSnap = await orderRef.get();
      if (!orderSnap.exists) return;

      final data = orderSnap.data() ?? {};
      final bool reachedPickupAlready = data['reached_pickup'] == true;
      final bool reachedDropAlready = data['reached_drop'] == true;

      // Check Pickup Arrival
      if (!reachedPickupAlready && _pickupLat != null && _pickupLng != null &&
          _pickupLat != 0.0 && _pickupLng != 0.0) {
        final double distToPickup = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _pickupLat!,
          _pickupLng!,
        );

        if (distToPickup <= arrivalThresholdMeters) {
          await _handlePickupArrival();
        }
      }

      // Check Drop Arrival
      if (!reachedDropAlready && _dropLat != null && _dropLng != null &&
          _dropLat != 0.0 && _dropLng != 0.0) {
        final double distToDrop = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _dropLat!,
          _dropLng!,
        );

        if (distToDrop <= arrivalThresholdMeters) {
          await _handleDropArrival();
        }
      }
    } catch (e) {
      debugPrint("DriverLocationService _evaluateProximity error: $e");
    }
  }

  /// One-time event when Driver reaches pickup
  Future<void> _handlePickupArrival() async {
    if (_activeOrderId == null) return;

    final orderId = _activeOrderId!;
    final orderNo = _activeOrderNo ?? orderId;
    final brokerId = _activeBrokerId;
    final userUid = _activeUserUid;
    final driverId = _activeDriverId ?? '';

    debugPrint("DriverLocationService: Reached Pickup for Order #$orderNo");

    final updateData = {
      'reached_pickup': true,
      'reached_pickup_at': FieldValue.serverTimestamp(),
      'pickup_arrived_at': FieldValue.serverTimestamp(),
      'ride_phase': 'at_pickup',
      'updated_at': FieldValue.serverTimestamp(),
    };

    // Update Firestore collections
    await _firestore.collection("Orders").doc(orderId).set(updateData, SetOptions(merge: true));

    if (brokerId != null && brokerId.isNotEmpty) {
      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // Broker Notification (one-time)
      final String notifId = "pickup_arr_${orderId}_$driverId";
      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("Notifications")
          .doc(notifId)
          .set({
        'id': notifId,
        'type': 'driver_at_pickup',
        'title': 'Driver Arrived at Pickup',
        'body': 'Assigned Driver has arrived at the pickup location for Order #$orderNo.',
        'order_id': orderId,
        'order_no': orderNo,
        'driver_id': driverId,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      }, SetOptions(merge: true));
    }

    if (userUid != null && userUid.isNotEmpty) {
      await _firestore
          .collection("User")
          .doc(userUid)
          .collection("Requests")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // User Notification (one-time)
      final String notifId = "pickup_arr_${orderId}_$driverId";
      await _firestore
          .collection("User")
          .doc(userUid)
          .collection("Notifications")
          .doc(notifId)
          .set({
        'id': notifId,
        'user_uid': userUid,
        'type': 'driver_at_pickup',
        'title': 'Driver Arrived at Pickup',
        'body': 'Your assigned driver has arrived at the pickup location for Order #$orderNo.',
        'order_id': orderId,
        'order_no': orderNo,
        'driver_id': driverId,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      }, SetOptions(merge: true));
    }
  }

  /// One-time event when Driver reaches drop location
  Future<void> _handleDropArrival() async {
    if (_activeOrderId == null) return;

    final orderId = _activeOrderId!;
    final orderNo = _activeOrderNo ?? orderId;
    final brokerId = _activeBrokerId;
    final userUid = _activeUserUid;
    final driverId = _activeDriverId ?? '';

    debugPrint("DriverLocationService: Reached Drop Location for Order #$orderNo");

    final updateData = {
      'reached_drop': true,
      'reached_drop_at': FieldValue.serverTimestamp(),
      'drop_arrived_at': FieldValue.serverTimestamp(),
      'ride_phase': 'at_drop',
      'updated_at': FieldValue.serverTimestamp(),
    };

    await _firestore.collection("Orders").doc(orderId).set(updateData, SetOptions(merge: true));

    if (brokerId != null && brokerId.isNotEmpty) {
      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // Broker Notification
      final String notifId = "drop_arr_${orderId}_$driverId";
      await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("Notifications")
          .doc(notifId)
          .set({
        'id': notifId,
        'type': 'driver_at_drop',
        'title': 'Driver Arrived at Drop Location',
        'body': 'Driver has reached the destination drop location for Order #$orderNo.',
        'order_id': orderId,
        'order_no': orderNo,
        'driver_id': driverId,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      }, SetOptions(merge: true));
    }

    if (userUid != null && userUid.isNotEmpty) {
      await _firestore
          .collection("User")
          .doc(userUid)
          .collection("Requests")
          .doc(orderId)
          .set(updateData, SetOptions(merge: true));

      // User Notification
      final String notifId = "drop_arr_${orderId}_$driverId";
      await _firestore
          .collection("User")
          .doc(userUid)
          .collection("Notifications")
          .doc(notifId)
          .set({
        'id': notifId,
        'user_uid': userUid,
        'type': 'driver_at_drop',
        'title': 'Driver Arrived at Drop Location',
        'body': 'Driver has reached your delivery destination for Order #$orderNo.',
        'order_id': orderId,
        'order_no': orderNo,
        'driver_id': driverId,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      }, SetOptions(merge: true));
    }
  }

  /// Stops tracking cleanly and cancels timers/listeners.
  Future<void> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _periodicTimer?.cancel();
    _periodicTimer = null;
    _activeOrderId = null;
    _activeDriverId = null;
    _activeBrokerId = null;
    _activeUserUid = null;
    _activeOrderNo = null;
    _lastRecordedPosition = null;
    _lastFirebaseUpdateTime = null;
    debugPrint("DriverLocationService: GPS tracking stopped and cleaned up.");
  }
}
