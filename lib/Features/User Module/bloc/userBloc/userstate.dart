abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadedState extends UserState {
  final String userData;
  final String uid;

  UserLoadedState(this.userData, this.uid);
}

class UserErrorState extends UserState {
  final String errorMessage;

  UserErrorState(this.errorMessage);
}
