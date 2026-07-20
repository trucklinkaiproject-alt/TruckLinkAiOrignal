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
    this.brokerId = '',
    required this.status,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'pickupCity': pickupCity,
      'dropCity': dropCity,
      'pickupComp': pickupComp,
      'dropComp': dropComp,
      'itemType': itemType,
      'vehicleType': vehicleType,
      'additionalInfo': additionalInfo,
      'weight': weight,
      'quantity': quantity,
      'orderId': orderId,
      'orderNo': orderNo,
      'brokerId': brokerId,
      'status': status,
      'date': date,
    };
  }
}
