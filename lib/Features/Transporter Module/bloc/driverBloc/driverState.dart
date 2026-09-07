import 'package:trucklinkai_orignal/Features/Transporter%20Module/Models/driverModel.dart';

enum DriverBrokerRelationshipStatus {
  noBroker,
  requestPending,
  requestRejected,
  connected,
}

abstract class DriverState {}

class DriverInitialState extends DriverState {}

class DriverLoadingState extends DriverState {}

class DriverLoadedState extends DriverState {
  final DriverModel driver;
  final String? brokerName;
  final String? locationStatus;
  final DriverBrokerRelationshipStatus relationshipStatus;
  final String? targetBrokerId;
  final String? targetBrokerName;

  DriverLoadedState({
    required this.driver,
    this.brokerName,
    this.locationStatus,
    this.relationshipStatus = DriverBrokerRelationshipStatus.noBroker,
    this.targetBrokerId,
    this.targetBrokerName,
  });
}

class DriverErrorState extends DriverState {
  final String errorMessage;
  DriverErrorState(this.errorMessage);
}
