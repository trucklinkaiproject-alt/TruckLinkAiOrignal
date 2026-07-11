abstract class GetBrokerOrderDetailState {}

class GetBrokerOrderDetailInitialState extends GetBrokerOrderDetailState {}
class GetBrokerOrderDetailLoadingState extends GetBrokerOrderDetailState {}
class GetBrokerOrderDetailLoadedState extends GetBrokerOrderDetailState {
  final List<Map<String, dynamic>> orderDetails;

  GetBrokerOrderDetailLoadedState(this.orderDetails);
}
class GetBrokerOrderDetailErrorState extends GetBrokerOrderDetailState {
  final String error;

  GetBrokerOrderDetailErrorState(this.error);
}