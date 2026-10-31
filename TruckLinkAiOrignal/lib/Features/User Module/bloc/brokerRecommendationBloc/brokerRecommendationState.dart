// lib/Features/User Module/bloc/brokerRecommendationBloc/brokerRecommendationState.dart
import 'package:trucklinkai_orignal/Features/User%20Module/Models/brokerRecommendationModel.dart';

abstract class BrokerRecommendationState {}

class BrokerRecommendationInitialState extends BrokerRecommendationState {}

class BrokerRecommendationLoadingState extends BrokerRecommendationState {
  final String message;

  BrokerRecommendationLoadingState({
    this.message = "Finding the best brokers (connecting to AI engine)...",
  });
}

class BrokerRecommendationLoadedState extends BrokerRecommendationState {
  final List<BrokerRecommendationModel> recommendations;
  final String? infoMessage;

  BrokerRecommendationLoadedState({
    required this.recommendations,
    this.infoMessage,
  });
}

class BrokerRecommendationEmptyState extends BrokerRecommendationState {
  final String message;

  BrokerRecommendationEmptyState({required this.message});
}

class BrokerRecommendationErrorState extends BrokerRecommendationState {
  final String error;
  final bool canRetry;

  BrokerRecommendationErrorState({
    required this.error,
    this.canRetry = true,
  });
}

