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
    this.brokerId = '',
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userUid': userUid,
      'pickupCity': pickupCity,
      'dropCity': dropCity,
      'pickupComp': pickupComp,
      'dropComp': dropComp,
      'itemType': itemType,
      'additionalInfo': additionalInfo,
      'weight': weight,
      'quantity': quantity,
      'orderId': orderId,
      'orderNo': orderNo,
      'brokerId': brokerId,
      'status':status
    };
  }
}
