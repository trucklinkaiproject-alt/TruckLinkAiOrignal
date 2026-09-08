abstract class BrokerDriverRequestsState {}

class BrokerDriverRequestsInitialState extends BrokerDriverRequestsState {}

class BrokerDriverRequestsLoadingState extends BrokerDriverRequestsState {}

class BrokerDriverRequestsLoadedState extends BrokerDriverRequestsState {
  final List<Map<String, dynamic>> pendingRequests;
  BrokerDriverRequestsLoadedState(this.pendingRequests);
}

class BrokerDriverRequestsActionSuccessState extends BrokerDriverRequestsState {
  final String message;
  BrokerDriverRequestsActionSuccessState(this.message);
}

class BrokerDriverRequestsErrorState extends BrokerDriverRequestsState {
  final String errorMessage;
  BrokerDriverRequestsErrorState(this.errorMessage);
}
