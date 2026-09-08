class UserRequestDataModel {
  String userUid;
  String pickupCity;
  String dropCity;
  String pickupComp;
  String dropComp;
  String itemType;
  String additionalInfo;
  int weight;
  int quantity;
  String orderId;
  String orderNo;
  String brokerId;
  String status;
  String date;
  String vehicleType;
  double pickupLat;
  double pickupLng;
  double dropLat;
  double dropLng;

  UserRequestDataModel({
    required this.userUid,
    required this.pickupCity,
    required this.dropCity,
    required this.pickupComp,
    required this.dropComp,
    required this.itemType,
    required this.additionalInfo,
    required this.weight,
    required this.quantity,
    required this.orderId,
    required this.orderNo,
    required this.vehicleType,
    this.pickupLat = 0.0,
    this.pickupLng = 0.0,
    this.dropLat = 0.0,
    this.dropLng = 0.0,
    this.brokerId = '',
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'user_uid': userUid,
      'pickupCity': pickupCity,
      'pickup_city': pickupCity,
      'dropCity': dropCity,
      'drop_city': dropCity,
      'pickupComp': pickupComp,
      'pickup_comp': pickupComp,
      'dropComp': dropComp,
      'drop_comp': dropComp,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickupLatitude': pickupLat,
      'pickupLongitude': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'dropLatitude': dropLat,
      'dropLongitude': dropLng,
      'itemType': itemType,
      'item_type': itemType,
      'vehicleType': vehicleType,
      'vehicle_type': vehicleType,
      'additionalInfo': additionalInfo,
      'additional_info': additionalInfo,
      'weight': weight,
      'quantity': quantity,
      'orderId': orderId,
      'order_id': orderId,
      'orderNo': orderNo,
      'order_no': orderNo,
      'brokerId': brokerId,
      'broker_id': brokerId,
      'status': status,
      'date': date,
    };
  }
}

