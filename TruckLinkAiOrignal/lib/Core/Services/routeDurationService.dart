import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;


class RouteDurationService {
  static final RouteDurationService _instance = RouteDurationService._internal();
  factory RouteDurationService() => _instance;
  RouteDurationService._internal();


  Future<String> calculateEstimatedDuration({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    String prefix = 'Estimated travel time',
  }) async {
    if (pickupLat == 0.0 || pickupLng == 0.0 || dropLat == 0.0 || dropLng == 0.0) {
      return 'Travel time unavailable';
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '$pickupLng,$pickupLat;$dropLng,$dropLat'
        '?overview=false',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final num durationSec = route['duration'] ?? 0;
          return formatDuration(durationSec.toDouble(), prefix: prefix);
        }
      }


      final distanceKm = _haversineDistance(pickupLat, pickupLng, dropLat, dropLng);
      if (distanceKm > 0) {
        final durationHours = distanceKm / 60.0;
        final durationSec = durationHours * 3600;
        return formatDuration(durationSec, prefix: prefix);
      }
    } catch (_) {

      try {
        final distanceKm = _haversineDistance(pickupLat, pickupLng, dropLat, dropLng);
        if (distanceKm > 0) {
          final durationSec = (distanceKm / 60.0) * 3600;
          return formatDuration(durationSec, prefix: prefix);
        }
      } catch (_) {}
    }

    return 'Travel time unavailable';
  }


  static String formatDuration(double totalSeconds, {String prefix = 'Estimated travel time'}) {
    if (totalSeconds <= 0) return 'Travel time unavailable';

    final int minutes = (totalSeconds / 60).round();
    final int hours = minutes ~/ 60;
    final int remMinutes = minutes % 60;

    String timeStr;
    if (hours > 0 && remMinutes > 0) {
      timeStr = '${hours}h ${remMinutes}m';
    } else if (hours > 0) {
      timeStr = '${hours}h';
    } else {
      timeStr = '${max(1, remMinutes)}m';
    }

    return prefix.isNotEmpty ? '$prefix: $timeStr' : timeStr;
  }


  static double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
