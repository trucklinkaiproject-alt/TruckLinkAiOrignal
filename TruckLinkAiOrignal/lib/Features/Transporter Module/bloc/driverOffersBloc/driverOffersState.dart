abstract class DriverOffersState {}

class DriverOffersInitialState extends DriverOffersState {}

class DriverOffersLoadingState extends DriverOffersState {}

class DriverOffersLoadedState extends DriverOffersState {
  final List<Map<String, dynamic>> offers;
  DriverOffersLoadedState(this.offers);
}

class DriverOffersActionSuccessState extends DriverOffersState {
  final String message;
  DriverOffersActionSuccessState(this.message);
}

class DriverOffersErrorState extends DriverOffersState {
  final String errorMessage;
  DriverOffersErrorState(this.errorMessage);
}
