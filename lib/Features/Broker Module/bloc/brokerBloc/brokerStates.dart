abstract class BrokerState {}

class BrokerInitialState extends BrokerState {}

class BrokerLoadingState extends BrokerState {}

class BrokerLoadedState extends BrokerState {
  final String userData;
  final String uid;

  BrokerLoadedState(this.userData, this.uid);
}

class BrokerErrorState extends BrokerState {
  final String errorMessage;

  BrokerErrorState(this.errorMessage);
}
