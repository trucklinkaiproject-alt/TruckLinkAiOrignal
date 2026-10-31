import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String driverId;
  final String? brokerId;
  final String? brokerName;
  final double? driverLatitude;
  final double? driverLongitude;
  final String? vehicleNumber;
  final String? vehicleType;
  final bool vehicleAvailable;
  final bool truckDetailsCompleted;
  final bool onboardingCompleted;
  final double driverRating;
  final int totalTrips;
  final int completedTrips;
  final int cancelledTrips;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String uid;
  final String? activeRequestBrokerId;
  final String? activeRequestBrokerName;
  final String? requestStatus;
  final String availabilityStatus; // 'online', 'offline', 'on_ride'

  DriverModel({
    required this.driverId,
    this.brokerId,
    this.brokerName,
    this.driverLatitude,
    this.driverLongitude,
    this.vehicleNumber,
    this.vehicleType,
    this.vehicleAvailable = false,
    this.truckDetailsCompleted = false,
    this.onboardingCompleted = false,
    this.driverRating = 0.0,
    this.totalTrips = 0,
    this.completedTrips = 0,
    this.cancelledTrips = 0,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'Driver',
    required this.uid,
    this.activeRequestBrokerId,
    this.activeRequestBrokerName,
    this.requestStatus,
    this.availabilityStatus = 'online',
  });

  /// Business rule: Truck details are complete only when both vehicleNumber and vehicleType are present and non-empty.
  bool get isTruckDetailsComplete =>
      (truckDetailsCompleted || onboardingCompleted) ||
      (vehicleNumber != null &&
          vehicleNumber!.trim().isNotEmpty &&
          vehicleType != null &&
          vehicleType!.trim().isNotEmpty);

  bool get isOnline => availabilityStatus == 'online';
  bool get isOnRide => availabilityStatus == 'on_ride';
  bool get isOffline => availabilityStatus == 'offline';

  factory DriverModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    final effectiveId = map['driver_id'] as String? ?? map['uid'] as String? ?? docId ?? '';
    final rawAvail = (map['availability_status'] ?? map['status'] ?? 'online').toString().toLowerCase();
    final String effectiveAvail = (rawAvail == 'offline' || rawAvail == 'on_ride') ? rawAvail : 'online';

    final bool isTruckCompleteExplicit = (map['truck_details_completed'] as bool?) ??
        (map['onboarding_completed'] as bool?) ??
        false;

    return DriverModel(
      driverId: effectiveId,
      brokerId: map['broker_id'] as String?,
      brokerName: map['broker_name'] as String?,
      driverLatitude: (map['driver_latitude'] as num?)?.toDouble(),
      driverLongitude: (map['driver_longitude'] as num?)?.toDouble(),
      vehicleNumber: map['vehicle_number'] as String? ?? map['vehicleNumber'] as String?,
      vehicleType: map['vehicle_type'] as String? ?? map['vehicleType'] as String?,
      vehicleAvailable: map['vehicle_available'] as bool? ?? (effectiveAvail == 'online'),
      truckDetailsCompleted: isTruckCompleteExplicit,
      onboardingCompleted: isTruckCompleteExplicit,
      driverRating: (map['driver_rating'] as num?)?.toDouble() ?? 0.0,
      totalTrips: (map['total_trips'] as num?)?.toInt() ?? 0,
      completedTrips: (map['completed_trips'] as num?)?.toInt() ?? 0,
      cancelledTrips: (map['cancelled_trips'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      role: map['role'] as String? ?? 'Driver',
      uid: map['uid'] as String? ?? effectiveId,
      activeRequestBrokerId: map['active_request_broker_id'] as String? ?? map['activeRequestBrokerId'] as String?,
      activeRequestBrokerName: map['active_request_broker_name'] as String? ?? map['activeRequestBrokerName'] as String?,
      requestStatus: map['request_status'] as String? ?? map['requestStatus'] as String?,
      availabilityStatus: effectiveAvail,
    );
  }

  factory DriverModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return DriverModel.fromMap(data, docId: snapshot.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'driver_id': driverId,
      'broker_id': brokerId,
      'broker_name': brokerName,
      'driver_latitude': driverLatitude,
      'driver_longitude': driverLongitude,
      'vehicle_number': vehicleNumber,
      'vehicle_type': vehicleType,
      'vehicle_available': vehicleAvailable,
      'truck_details_completed': truckDetailsCompleted,
      'onboarding_completed': onboardingCompleted,
      'driver_rating': driverRating,
      'total_trips': totalTrips,
      'completed_trips': completedTrips,
      'cancelled_trips': cancelledTrips,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'uid': uid,
      'active_request_broker_id': activeRequestBrokerId,
      'active_request_broker_name': activeRequestBrokerName,
      'request_status': requestStatus,
      'availability_status': availabilityStatus,
    };
  }

  /// Initial map structure when a new Driver document is created in Firestore
  static Map<String, dynamic> createInitialData({
    required String uid,
    required String name,
    required String email,
    required String phone,
    required String role,
  }) {
    return {
      'driver_id': uid,
      'broker_id': null,
      'broker_name': null,
      'driver_latitude': null,
      'driver_longitude': null,
      'vehicle_number': null,
      'vehicle_type': null,
      'vehicle_available': true,
      'truck_details_completed': false,
      'onboarding_completed': false,
      'availability_status': 'online',
      'driver_rating': 0.0,
      'total_trips': 0,
      'completed_trips': 0,
      'cancelled_trips': 0,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'uid': uid,
      'active_request_broker_id': null,
      'active_request_broker_name': null,
      'request_status': null,
    };
  }

  DriverModel copyWith({
    String? driverId,
    String? brokerId,
    String? brokerName,
    double? driverLatitude,
    double? driverLongitude,
    String? vehicleNumber,
    String? vehicleType,
    bool? vehicleAvailable,
    bool? truckDetailsCompleted,
    bool? onboardingCompleted,
    double? driverRating,
    int? totalTrips,
    int? completedTrips,
    int? cancelledTrips,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? uid,
    String? activeRequestBrokerId,
    String? activeRequestBrokerName,
    String? requestStatus,
    String? availabilityStatus,
  }) {
    return DriverModel(
      driverId: driverId ?? this.driverId,
      brokerId: brokerId ?? this.brokerId,
      brokerName: brokerName ?? this.brokerName,
      driverLatitude: driverLatitude ?? this.driverLatitude,
      driverLongitude: driverLongitude ?? this.driverLongitude,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleAvailable: vehicleAvailable ?? this.vehicleAvailable,
      truckDetailsCompleted: truckDetailsCompleted ?? this.truckDetailsCompleted,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      driverRating: driverRating ?? this.driverRating,
      totalTrips: totalTrips ?? this.totalTrips,
      completedTrips: completedTrips ?? this.completedTrips,
      cancelledTrips: cancelledTrips ?? this.cancelledTrips,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      uid: uid ?? this.uid,
      activeRequestBrokerId: activeRequestBrokerId ?? this.activeRequestBrokerId,
      activeRequestBrokerName: activeRequestBrokerName ?? this.activeRequestBrokerName,
      requestStatus: requestStatus ?? this.requestStatus,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
    );
  }
}
