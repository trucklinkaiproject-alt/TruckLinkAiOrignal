// lib/Core/Services/recommendationApiService.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/brokerRecommendationModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/userRequestDataModel.dart';

class RecommendationApiService {
  static final RecommendationApiService _instance = RecommendationApiService._internal();
  factory RecommendationApiService() => _instance;
  RecommendationApiService._internal();

  /// Default production Render HTTPS endpoint
  static const String kDefaultProductionUrl =
      'https://trucklink-ai-recommendations.onrender.com';

  /// Compile-time environment override via `--dart-define=REC_API_URL=https://...`
  static const String _envApiUrl = String.fromEnvironment('REC_API_URL');

  /// Runtime custom base URL override (e.g. from user settings or local debug switch)
  static String? customBaseUrl;

  /// Flag indicating whether to route traffic to the deployed production HTTPS endpoint
  /// Defaults to true for production readiness; set to false for local loopback emulator testing.
  static bool useProduction = true;

  /// Configure the production Render endpoint URL dynamically
  static void configureProductionUrl(String renderHttpsUrl) {
    customBaseUrl = renderHttpsUrl.trim().replaceAll(RegExp(r'/+$'), '');
    useProduction = true;
    AppLogger.info("Configured recommendation API URL: $customBaseUrl", "RecommendationApiService");
  }

  /// Switch to local development server (10.0.2.2 on Android emulator, 127.0.0.1 on Desktop/Web)
  static void useLocalDevelopment() {
    useProduction = false;
    customBaseUrl = null;
    AppLogger.info("Switched recommendation API to local development mode", "RecommendationApiService");
  }

  /// Resolves the effective base URL
  static String get baseUrl {
    // 1. Explicit runtime override
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }
    // 2. Compile-time `--dart-define=REC_API_URL=...`
    if (_envApiUrl.isNotEmpty) {
      return _envApiUrl;
    }
    // 3. Production HTTPS endpoint (Render)
    if (useProduction || const bool.fromEnvironment('dart.vm.product')) {
      return kDefaultProductionUrl;
    }
    // 4. Local development fallback
    try {
      if (Platform.isAndroid) {
        // Android emulator loopback to host machine
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Fallback for Web/desktop
    }
    return 'http://127.0.0.1:8000';
  }

  /// Calls POST /recommend on the FastAPI recommendation microservice.
  /// Uses a 45-second timeout to gracefully handle Render free-tier cold starts
  /// (which take ~30-40 seconds when waking from idle sleep).
  Future<List<BrokerRecommendationModel>> getRecommendations({
    required UserRequestDataModel request,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final effectiveBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
    final url = Uri.parse('$effectiveBase/recommend');

    String? idToken;
    try {
      idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (e) {
      AppLogger.warn("Could not retrieve Firebase ID token: $e", "RecommendationApiService");
    }

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (idToken != null && idToken.isNotEmpty) 'Authorization': 'Bearer $idToken',
    };

    final body = jsonEncode({
      'user_uid': request.userUid,
      'pickup_lat': request.pickupLat,
      'pickup_lng': request.pickupLng,
      'drop_lat': request.dropLat,
      'drop_lng': request.dropLng,
      'required_vehicle_type': request.vehicleType,
      'cargo_type': request.itemType,
      'weight': request.weight > 0 ? request.weight : null,
      'quantity': request.quantity > 0 ? request.quantity : null,
      'request_id': request.orderId.isNotEmpty ? request.orderId : null,
    });

    try {
      AppLogger.info("Requesting AI recommendations from: $url", "RecommendationApiService");
      final response = await http.post(url, headers: headers, body: body).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> recsRaw = data['recommendations'] ?? [];
        return recsRaw.map((item) => BrokerRecommendationModel.fromJson(item)).toList();
      } else {
        AppLogger.error(
          "Recommendation API returned error: ${response.statusCode} - ${response.body}",
          response.body,
          null,
          "RecommendationApiService",
        );
        throw HttpException("Recommendation service returned ${response.statusCode}");
      }
    } on TimeoutException catch (te) {
      AppLogger.warn("Recommendation API timed out after $timeout. Likely Render cold-start wake up.", "RecommendationApiService");
      throw TimeoutException("Recommendation service cold start timed out. Please retry shortly: $te");
    } catch (e, stack) {
      AppLogger.error("Failed to connect to recommendation service", e, stack, "RecommendationApiService");
      rethrow;
    }
  }

  /// Checks if the backend recommendation microservice is online
  Future<bool> checkHealth() async {
    try {
      final effectiveBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
      final url = Uri.parse('$effectiveBase/health');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

