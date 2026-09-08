abstract class OrderDetailState {}

class OrderDetailInitialState extends OrderDetailState {}

class OrderDetailLoadingState extends OrderDetailState {}

class OrderDetailLoadedState extends OrderDetailState {
  final List<Map<String, dynamic>> orderDetails;

  OrderDetailLoadedState(this.orderDetails);
}

class OrderDetailErrorState extends OrderDetailState {
  final String error;

  OrderDetailErrorState(this.error);
}
