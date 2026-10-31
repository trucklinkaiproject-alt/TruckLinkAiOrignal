// lib/Features/User Module/Models/brokerRecommendationModel.dart

class BrokerRecommendationModel {
  final int rank;
  final String brokerId;
  final String brokerName;
  final String brokerPhone;
  final double brokerRating;
  final int totalReviews;
  final double nearestDriverDistanceKm;
  final int activeDriversCount;
  final double recommendationScore;
  final String requiredVehicleType;
  final List<String> reasonCodes;
  final String modelVersion;

  BrokerRecommendationModel({
    required this.rank,
    required this.brokerId,
    required this.brokerName,
    this.brokerPhone = '',
    required this.brokerRating,
    this.totalReviews = 0,
    required this.nearestDriverDistanceKm,
    required this.activeDriversCount,
    required this.recommendationScore,
    required this.requiredVehicleType,
    required this.reasonCodes,
    required this.modelVersion,
  });

  factory BrokerRecommendationModel.fromJson(Map<String, dynamic> json) {
    return BrokerRecommendationModel(
      rank: (json['rank'] as num?)?.toInt() ?? 1,
      brokerId: json['broker_id']?.toString() ?? '',
      brokerName: json['broker_name']?.toString() ?? 'Broker',
      brokerPhone: json['broker_phone']?.toString() ?? '',
      brokerRating: (json['broker_rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
      nearestDriverDistanceKm: (json['nearest_driver_distance_km'] as num?)?.toDouble() ?? 0.0,
      activeDriversCount: (json['active_drivers_count'] as num?)?.toInt() ?? 0,
      recommendationScore: (json['recommendation_score'] as num?)?.toDouble() ?? 0.0,
      requiredVehicleType: json['required_vehicle_type']?.toString() ?? '',
      reasonCodes: (json['reason_codes'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      modelVersion: json['model_version']?.toString() ?? '1.0.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'broker_id': brokerId,
      'broker_name': brokerName,
      'broker_phone': brokerPhone,
      'broker_rating': brokerRating,
      'total_reviews': totalReviews,
      'nearest_driver_distance_km': nearestDriverDistanceKm,
      'active_drivers_count': activeDriversCount,
      'recommendation_score': recommendationScore,
      'required_vehicle_type': requiredVehicleType,
      'reason_codes': reasonCodes,
      'model_version': modelVersion,
    };
  }
}

