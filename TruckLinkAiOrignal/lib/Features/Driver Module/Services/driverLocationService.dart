import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';

/// DriverLocationService (Phase 2.9 & 2.10)
///
/// Features:
/// - Background GPS tracking with Android Foreground Service notification
/// - Resume-on-start after app restart if an active ride is in_transit
/// - Eliminated write amplification: Writes to Orders and Driver docs only
/// - Zero Firestore gets during movement by caching reached_pickup & reached_drop locally
/// - Unified 45-second minimum interval between Firebase GPS pushes
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

  // Locally cached arrival flags to prevent Firestore get() calls on every GPS event (Phase 2.10)
  bool _reachedPickup = false;
  bool _reachedDrop = false;

  /// Arrival proximity threshold in meters (250m)
  static const double arrivalThresholdMeters = 250.0;

  /// Unified interval between Firebase GPS writes (Phase 2.10)
  static const Duration minFirebaseUpdateInterval = Duration(seconds: 45);

  /// Resumes tracking on app startup if the driver has an active in_transit ride (Phase 2.9)
  Future<void> resumeIfActiveRide(String driverId) async {
    if (_isTracking || driverId.isEmpty) return;

    try {
      final activeRideSnap = await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("ReceivedOffers")
          .where("status", whereIn: ["in_transit", "arrived_at_pickup", "heading_to_drop"])
          .limit(1)
          .get();

      if (activeRideSnap.docs.isNotEmpty) {
        final data = activeRideSnap.docs.first.data();
        final String orderId = (data['order_id'] ?? data['orderId'] ?? '').toString();
        if (orderId.isNotEmpty) {
          debugPrint("[DriverLocationService] Resuming background tracking for active ride #$orderId");
          await startTracking(
            orderId: orderId,
            driverId: driverId,
            brokerId: (data['broker_id'] ?? data['brokerId'] ?? '').toString(),
            userUid: (data['user_uid'] ?? data['userUid'] ?? '').toString(),
            orderNo: (data['order_no'] ?? orderId).toString(),
            pickupLat: (data['pickup_lat'] ?? data['pickupLatitude'] as num?)?.toDouble(),
            pickupLng: (data['pickup_lng'] ?? data['pickupLongitude'] as num?)?.toDouble(),
            dropLat: (data['drop_lat'] ?? data['dropLatitude'] as num?)?.toDouble(),
            dropLng: (data['drop_lng'] ?? data['dropLongitude'] as num?)?.toDouble(),
            reachedPickup: data['reached_pickup'] == true,
            reachedDrop: data['reached_drop'] == true,
          );
        }
      }
    } catch (e) {
      debugPrint("[DriverLocationService] resumeIfActiveRide error: $e");
    }
  }

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
    bool reachedPickup = false,
    bool reachedDrop = false,
  }) async {
    try {
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
      _reachedPickup = reachedPickup;
      _reachedDrop = reachedDrop;
      _isTracking = true;

      // Initial position fetch
      try {
        final initialPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _lastRecordedPosition = initialPos;
        await _pushLocationToFirebase(initialPos, force: true);
        _evaluateProximity(initialPos);
      } catch (e) {
        debugPrint("DriverLocationService: Initial pos error: $e");
      }

      // Configure Android foreground service for persistent background tracking (Phase 2.9)
      final LocationSettings locationSettings;
      if (defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
          intervalDuration: minFirebaseUpdateInterval,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: "Active Trip Tracking Live",
            notificationText: "TruckLink AI is tracking your delivery route in the background.",
            enableWakeLock: true,
          ),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
        );
      }

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) async {
          _lastRecordedPosition = position;
          final now = DateTime.now();

          if (_lastFirebaseUpdateTime == null ||
              now.difference(_lastFirebaseUpdateTime!) >= minFirebaseUpdateInterval) {
            await _pushLocationToFirebase(position);
          }

          _evaluateProximity(position);
        },
        onError: (error) {
          debugPrint("DriverLocationService: Stream error: $error");
        },
      );

      // Heartbeat timer ensuring periodic location updates even when stationary
      _periodicTimer = Timer.periodic(minFirebaseUpdateInterval, (timer) async {
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
            _evaluateProximity(pos);
          } catch (e, stack) {
            AppLogger.error("Failed to get current GPS position in timer fallback", e, stack, "DriverLocationService");
          }
        }
      });

      return true;
    } catch (e, stack) {
      AppLogger.error("DriverLocationService startTracking error", e, stack, "DriverLocationService");
      return false;
    }
  }

  /// Pushes coordinates to Orders and Driver documents (Phase 2.10: avoids write amplification).
  Future<void> _pushLocationToFirebase(Position position, {bool force = false}) async {
    if (!_isTracking || _activeDriverId == null || _activeOrderId == null) return;

    final now = DateTime.now();
    if (!force &&
        _lastFirebaseUpdateTime != null &&
        now.difference(_lastFirebaseUpdateTime!) < minFirebaseUpdateInterval) {
      return;
    }

    _lastFirebaseUpdateTime = now;

    try {
      final batch = _firestore.batch();

      // 1. Primary real-time Tracking doc: Orders/{orderId}
      final orderRef = _firestore.collection("Orders").doc(_activeOrderId);
      batch.set(orderRef, {
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'last_location_update': FieldValue.serverTimestamp(),
        'driver_id': _activeDriverId,
      }, SetOptions(merge: true));

      // 2. Driver/{driverId} document
      final driverRef = _firestore.collection("Driver").doc(_activeDriverId);
      batch.update(driverRef, {
        'driver_latitude': position.latitude,
        'driver_longitude': position.longitude,
        'last_location_update': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      debugPrint("DriverLocationService _pushLocationToFirebase error: $e");
    }
  }

  /// Evaluates distance to Pickup and Drop using locally cached flags without Firestore gets (Phase 2.10)
  void _evaluateProximity(Position position) {
    if (!_isTracking || _activeOrderId == null) return;

    // Check Pickup Arrival
    if (!_reachedPickup &&
        _pickupLat != null &&
        _pickupLng != null &&
        _pickupLat != 0.0 &&
        _pickupLng != 0.0) {
      final double distToPickup = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _pickupLat!,
        _pickupLng!,
      );

      if (distToPickup <= arrivalThresholdMeters) {
        _reachedPickup = true;
        _onReachedPickup();
      }
    }

    // Check Drop Arrival
    if (!_reachedDrop &&
        _dropLat != null &&
        _dropLng != null &&
        _dropLat != 0.0 &&
        _dropLng != 0.0) {
      final double distToDrop = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _dropLat!,
        _dropLng!,
      );

      if (distToDrop <= arrivalThresholdMeters) {
        _reachedDrop = true;
        _onReachedDrop();
      }
    }
  }

  Future<void> _onReachedPickup() async {
    if (_activeOrderId == null) return;
    try {
      final payload = {
        'reached_pickup': true,
        'status': 'arrived_at_pickup',
        'reached_pickup_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection("Orders").doc(_activeOrderId).set(payload, SetOptions(merge: true));

      if (_activeBrokerId != null && _activeBrokerId!.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(_activeBrokerId)
            .collection("IncomingRequests")
            .doc(_activeOrderId)
            .set(payload, SetOptions(merge: true));
      }

      if (_activeUserUid != null && _activeUserUid!.isNotEmpty) {
        await _firestore
            .collection("User")
            .doc(_activeUserUid)
            .collection("Requests")
            .doc(_activeOrderId)
            .set(payload, SetOptions(merge: true));

        await NotificationService().sendNotification(
          targetCollection: 'User',
          recipientId: _activeUserUid!,
          type: NotificationTypes.driverArrived,
          title: 'Driver Arrived at Pickup',
          body: 'Your driver has arrived at the pickup location for Order #${_activeOrderNo ?? _activeOrderId}.',
          notificationId: "arr_pk_$_activeOrderId",
          orderId: _activeOrderId,
          orderNo: _activeOrderNo,
          senderId: _activeDriverId ?? '',
          receiverRole: 'User',
        );
      }
    } catch (e) {
      debugPrint("DriverLocationService _onReachedPickup error: $e");
    }
  }

  Future<void> _onReachedDrop() async {
    if (_activeOrderId == null) return;
    try {
      final payload = {
        'reached_drop': true,
        'reached_drop_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection("Orders").doc(_activeOrderId).set(payload, SetOptions(merge: true));

      if (_activeBrokerId != null && _activeBrokerId!.isNotEmpty) {
        await _firestore
            .collection("Broker")
            .doc(_activeBrokerId)
            .collection("IncomingRequests")
            .doc(_activeOrderId)
            .set(payload, SetOptions(merge: true));
      }

      if (_activeUserUid != null && _activeUserUid!.isNotEmpty) {
        await _firestore
            .collection("User")
            .doc(_activeUserUid)
            .collection("Requests")
            .doc(_activeOrderId)
            .set(payload, SetOptions(merge: true));

        await NotificationService().sendNotification(
          targetCollection: 'User',
          recipientId: _activeUserUid!,
          type: NotificationTypes.driverArrived,
          title: 'Driver Arrived at Destination',
          body: 'Your driver has reached the delivery drop destination for Order #${_activeOrderNo ?? _activeOrderId}.',
          notificationId: "arr_dp_$_activeOrderId",
          orderId: _activeOrderId,
          orderNo: _activeOrderNo,
          senderId: _activeDriverId ?? '',
          receiverRole: 'User',
        );
      }
    } catch (e) {
      debugPrint("DriverLocationService _onReachedDrop error: $e");
    }
  }

  /// Stops tracking and disposes all resources.
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
    _pickupLat = null;
    _pickupLng = null;
    _dropLat = null;
    _dropLng = null;
    _lastRecordedPosition = null;
    _lastFirebaseUpdateTime = null;
    _reachedPickup = false;
    _reachedDrop = false;
  }
}
