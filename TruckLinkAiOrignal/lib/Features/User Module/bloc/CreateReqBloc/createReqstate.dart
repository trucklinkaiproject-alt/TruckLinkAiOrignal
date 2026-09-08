abstract class CreateReqState {}

class CreateReqInitialState extends CreateReqState {}

class CreateReqLoadingState extends CreateReqState {}

class CreateReqUserDataState extends CreateReqState {
  late final String orderId;
  late final String userUid;
  late final String pickupCity;
  late final String dropCity;
  late final String pickupComp;
  late final String dropComp;
  late final String itemType;
  late final String additionalInfo;
  late final int weight;
  late final int quantity;
  late final String brokerId;
  CreateReqUserDataState(
    this.userUid,
    this.pickupCity,
    this.pickupComp,
    this.dropCity,
    this.dropComp,
    this.itemType,
    this.weight,
    this.quantity,
    this.additionalInfo,
    this.orderId,
    this.brokerId,
  );
}

class CreateReqSuccessState extends CreateReqState {
  final String successMessage;
  CreateReqSuccessState(this.successMessage);
}

class CreateReqErrorState extends CreateReqState {
  final String errorMessage;

  CreateReqErrorState(this.errorMessage);
}
