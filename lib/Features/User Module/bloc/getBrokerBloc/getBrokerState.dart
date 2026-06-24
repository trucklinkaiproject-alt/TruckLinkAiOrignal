abstract class GetBrokerState {}

class GetBrokerInitialState extends GetBrokerState {}

class GetBrokerLoadingState extends GetBrokerState {}

class GetBrokerLoadedState extends GetBrokerState {}

class GetBrokerErrorState extends GetBrokerState {
  final String error;
  GetBrokerErrorState(this.error);
}
