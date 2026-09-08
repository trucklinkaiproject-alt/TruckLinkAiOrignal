abstract class BrokerAssignDriverState {}

class BrokerAssignDriverInitialState extends BrokerAssignDriverState {}

class BrokerAssignDriverLoadingState extends BrokerAssignDriverState {}

class BrokerAssignDriverLoadedState extends BrokerAssignDriverState {
  final List<Map<String, dynamic>> eligibleDrivers;
  final String requiredVehicleType;

  BrokerAssignDriverLoadedState({
    required this.eligibleDrivers,
    required this.requiredVehicleType,
  });
}

class BrokerAssignDriverSendingState extends BrokerAssignDriverState {
  final String driverId;
  BrokerAssignDriverSendingState(this.driverId);
}

class BrokerAssignDriverSuccessState extends BrokerAssignDriverState {
  final String message;
  BrokerAssignDriverSuccessState(this.message);
}

class BrokerAssignDriverErrorState extends BrokerAssignDriverState {
  final String errorMessage;
  BrokerAssignDriverErrorState(this.errorMessage);
}
