abstract class FindBrokerState {}

class FindBrokerInitialState extends FindBrokerState {}

class FindBrokerLoadingState extends FindBrokerState {}

class FindBrokerLoadedState extends FindBrokerState {
  final List<Map<String, dynamic>> allBrokers;
  final List<Map<String, dynamic>> filteredBrokers;
  final Set<String> requestedBrokerIds;
  final String searchQuery;

  FindBrokerLoadedState({
    required this.allBrokers,
    required this.filteredBrokers,
    required this.requestedBrokerIds,
    this.searchQuery = '',
  });
}

class FindBrokerSendingRequestState extends FindBrokerState {
  final String targetBrokerId;
  FindBrokerSendingRequestState(this.targetBrokerId);
}

class FindBrokerSuccessState extends FindBrokerState {
  final String successMessage;
  FindBrokerSuccessState(this.successMessage);
}

class FindBrokerErrorState extends FindBrokerState {
  final String errorMessage;
  FindBrokerErrorState(this.errorMessage);
}
