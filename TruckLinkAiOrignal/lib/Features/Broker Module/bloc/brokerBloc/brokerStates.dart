abstract class BrokerState {}

class BrokerInitialState extends BrokerState {}

class BrokerLoadingState extends BrokerState {}

class BrokerLoadedState extends BrokerState {
  final String ? userData;
  final String? uid;
  final List<Map<String, dynamic>>? incomingRequests;

  BrokerLoadedState({this.userData, this.uid, this.incomingRequests});
}

class BrokerErrorState extends BrokerState {
  final String errorMessage;

  BrokerErrorState(this.errorMessage);
}
