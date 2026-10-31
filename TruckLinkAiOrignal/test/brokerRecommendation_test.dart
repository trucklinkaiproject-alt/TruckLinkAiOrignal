// test/brokerRecommendation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:trucklinkai_orignal/Core/Services/recommendationApiService.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/brokerRecommendationModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/userRequestDataModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/brokerRecommendationBloc/brokerRecommendationCubit.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/brokerRecommendationBloc/brokerRecommendationState.dart';

class MockRecommendationApiService implements RecommendationApiService {
  List<BrokerRecommendationModel> mockResults = [];
  bool shouldThrow = false;

  @override
  Future<List<BrokerRecommendationModel>> getRecommendations({
    required UserRequestDataModel request,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (shouldThrow) {
      throw Exception("Network connection failed");
    }
    return mockResults;
  }

  @override
  Future<bool> checkHealth() async {
    return !shouldThrow;
  }
}

void main() {
  group('BrokerRecommendationModel Serialization', () {
    test('correctly parses JSON from FastAPI recommendation endpoint', () {
      final json = {
        'rank': 1,
        'broker_id': 'broker_001',
        'broker_name': 'Premier Logistics',
        'broker_phone': '+923001234567',
        'broker_rating': 4.85,
        'total_reviews': 42,
        'nearest_driver_distance_km': 8.5,
        'active_drivers_count': 3,
        'recommendation_score': 0.942,
        'required_vehicle_type': 'Shahzore',
        'reason_codes': ['DRIVER_CLOSE_PROXIMITY', 'HIGH_COMPLETION_RATE'],
        'model_version': '1.0.0',
      };

      final model = BrokerRecommendationModel.fromJson(json);

      expect(model.rank, 1);
      expect(model.brokerId, 'broker_001');
      expect(model.brokerName, 'Premier Logistics');
      expect(model.brokerRating, 4.85);
      expect(model.totalReviews, 42);
      expect(model.nearestDriverDistanceKm, 8.5);
      expect(model.activeDriversCount, 3);
      expect(model.recommendationScore, 0.942);
      expect(model.requiredVehicleType, 'Shahzore');
      expect(model.reasonCodes, contains('DRIVER_CLOSE_PROXIMITY'));
      expect(model.modelVersion, '1.0.0');

      final mapped = model.toMap();
      expect(mapped['broker_id'], 'broker_001');
      expect(mapped['rank'], 1);
    });

    test('handles missing or null values gracefully without throwing', () {
      final json = <String, dynamic>{};
      final model = BrokerRecommendationModel.fromJson(json);

      expect(model.rank, 1);
      expect(model.brokerId, '');
      expect(model.brokerName, 'Broker');
      expect(model.brokerRating, 0.0);
      expect(model.nearestDriverDistanceKm, 0.0);
      expect(model.reasonCodes, isEmpty);
    });
  });

  group('BrokerRecommendationCubit', () {
    late MockRecommendationApiService mockApi;
    late BrokerRecommendationCubit cubit;
    late UserRequestDataModel testRequest;

    setUp(() {
      mockApi = MockRecommendationApiService();
      cubit = BrokerRecommendationCubit(apiService: mockApi);
      testRequest = UserRequestDataModel(
        userUid: 'user_123',
        pickupCity: 'Lahore',
        dropCity: 'Islamabad',
        pickupComp: 'Gulberg III',
        dropComp: 'F-7 Markaz',
        itemType: 'Furniture',
        additionalInfo: '',
        weight: 500,
        quantity: 10,
        orderId: 'ord_123',
        orderNo: 'TL-100',
        vehicleType: 'Shahzore',
        pickupLat: 31.5204,
        pickupLng: 74.3587,
        dropLat: 33.6844,
        dropLng: 73.0479,
        status: 'pending',
        date: '2026-10-31',
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is BrokerRecommendationInitialState', () {
      expect(cubit.state, isA<BrokerRecommendationInitialState>());
    });

    test('emits LoadedState when recommendations are returned', () async {
      mockApi.mockResults = [
        BrokerRecommendationModel(
          rank: 1,
          brokerId: 'b_1',
          brokerName: 'Fast Cargo',
          brokerRating: 4.9,
          nearestDriverDistanceKm: 5.2,
          activeDriversCount: 2,
          recommendationScore: 0.96,
          requiredVehicleType: 'Shahzore',
          reasonCodes: ['DRIVER_CLOSE_PROXIMITY'],
          modelVersion: '1.0.0',
        ),
      ];

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<BrokerRecommendationLoadingState>(),
          isA<BrokerRecommendationLoadedState>(),
        ]),
      );

      await cubit.fetchRecommendations(request: testRequest);
      expect(cubit.currentRecommendations.length, 1);
    });

    test('emits EmptyState when API returns zero recommendations', () async {
      mockApi.mockResults = [];

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<BrokerRecommendationLoadingState>(),
          isA<BrokerRecommendationEmptyState>(),
        ]),
      );

      await cubit.fetchRecommendations(request: testRequest);
      expect(cubit.currentRecommendations, isEmpty);
    });

    test('emits ErrorState when network request fails', () async {
      mockApi.shouldThrow = true;

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<BrokerRecommendationLoadingState>(),
          isA<BrokerRecommendationErrorState>(),
        ]),
      );

      await cubit.fetchRecommendations(request: testRequest);
      expect(cubit.currentRecommendations, isEmpty);
    });
  });
}
