// lib/Features/User Module/bloc/brokerRecommendationBloc/brokerRecommendationCubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Core/Services/recommendationApiService.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/brokerRecommendationModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/userRequestDataModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/brokerRecommendationBloc/brokerRecommendationState.dart';

class BrokerRecommendationCubit extends Cubit<BrokerRecommendationState> {
  final RecommendationApiService _apiService;

  BrokerRecommendationCubit({RecommendationApiService? apiService})
      : _apiService = apiService ?? RecommendationApiService(),
        super(BrokerRecommendationInitialState());

  List<BrokerRecommendationModel> currentRecommendations = [];

  Future<void> fetchRecommendations({
    required UserRequestDataModel request,
  }) async {
    emit(BrokerRecommendationLoadingState(
      message: "Finding best brokers (scoring drivers & fleet readiness)...",
    ));

    try {
      final recs = await _apiService.getRecommendations(request: request);

      currentRecommendations = recs;

      if (recs.isEmpty) {
        emit(BrokerRecommendationEmptyState(
          message:
              "No eligible brokers currently have an active ${request.vehicleType} driver within 150 km.",
        ));
      } else {
        emit(BrokerRecommendationLoadedState(recommendations: recs));
      }
    } on TimeoutException catch (te) {
      AppLogger.warn(
        "BrokerRecommendationCubit timeout: $te (Render free tier cold start)",
        "BrokerRecommendationCubit",
      );
      emit(BrokerRecommendationErrorState(
        error: "AI engine is waking up from sleep. Please tap retry in a moment.",
        canRetry: true,
      ));
    } catch (e, stack) {
      AppLogger.error(
        "BrokerRecommendationCubit error fetching recommendations",
        e,
        stack,
        "BrokerRecommendationCubit",
      );
      emit(BrokerRecommendationErrorState(
        error: "AI recommendation service is unavailable. Showing all verified online brokers.",
        canRetry: true,
      ));
    }
  }

  void reset() {
    currentRecommendations = [];
    emit(BrokerRecommendationInitialState());
  }
}

