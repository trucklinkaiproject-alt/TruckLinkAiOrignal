

abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadedState extends UserState {
  final String userName;
  final String uid;

  UserLoadedState(this.userName, this.uid);
}

class UserErrorState extends UserState {
  final String errorMessage;

  UserErrorState(this.errorMessage);
}


class BrokerOfferState extends UserState {
  final Map<String, dynamic> requestData;

  BrokerOfferState(this.requestData);
}