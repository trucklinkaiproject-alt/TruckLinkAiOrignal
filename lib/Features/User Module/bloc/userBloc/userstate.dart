// abstract class UserState {}

// class UserInitialState extends UserState {}

// class UserLoadingState extends UserState {}

// class UserLoadedState extends UserState {
//   final String userData;
//   final String uid;

//   UserLoadedState(this.userData, this.uid);
// }

// class UserErrorState extends UserState {
//   final String errorMessage;

//   UserErrorState(this.errorMessage);
// }
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

/// Fired when a broker submits a fare.
class BrokerOfferState extends UserState {
  final Map<String, dynamic> requestData;

  BrokerOfferState(this.requestData);
}