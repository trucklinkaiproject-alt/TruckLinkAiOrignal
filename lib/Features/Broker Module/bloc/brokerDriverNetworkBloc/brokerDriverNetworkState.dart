abstract class BrokerDriverNetworkState {}

class BrokerDriverNetworkInitialState extends BrokerDriverNetworkState {}

class BrokerDriverNetworkLoadingState extends BrokerDriverNetworkState {}

class BrokerDriverNetworkLoadedState extends BrokerDriverNetworkState {
  final List<Map<String, dynamic>> drivers;
  BrokerDriverNetworkLoadedState(this.drivers);
}

class BrokerDriverNetworkErrorState extends BrokerDriverNetworkState {
  final String errorMessage;
  BrokerDriverNetworkErrorState(this.errorMessage);
}
