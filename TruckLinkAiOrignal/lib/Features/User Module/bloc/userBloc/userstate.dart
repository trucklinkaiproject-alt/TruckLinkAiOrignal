// lib/Features/User Module/bloc/userBloc/userstate.dart
abstract class UserState {}

class UserInitialState extends UserState {}

class UserLoadingState extends UserState {}

class UserLoadedState extends UserState {
  final String userName;
  final String uid;
  final List<Map<String, dynamic>> pendingOffers;

  UserLoadedState(this.userName, this.uid, {this.pendingOffers = const []});
}

class UserErrorState extends UserState {
  final String errorMessage;

  UserErrorState(this.errorMessage);
}

/// Fired when one or more brokers submit fares (Phase 2.8).
/// Maintains all pending offers in [offers] without clobbering user identity.
class BrokerOfferState extends UserState {
  final String userName;
  final String uid;
  final List<Map<String, dynamic>> offers;
  final Map<String, dynamic> requestData;

  BrokerOfferState({
    required this.userName,
    required this.uid,
    required this.offers,
    required this.requestData,
  });
}