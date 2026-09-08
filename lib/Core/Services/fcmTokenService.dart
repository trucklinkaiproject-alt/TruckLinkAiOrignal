import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class FcmTokenService {
  static final FcmTokenService _instance = FcmTokenService._internal();
  factory FcmTokenService() => _instance;
  FcmTokenService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _currentUid;
  String? _currentRole;
  String? _cachedToken;
  String? _cachedDeviceId;
  bool _isListeningRefresh = false;

  /// Generate a deterministic, safe document ID from token or device ID
  String _generateTokenDocId(String token, String deviceId) {
    return 'token_${deviceId}_${token.hashCode.abs()}';
  }

  /// Retrieve device details safely across platforms
  Future<Map<String, String>> _getDeviceDetails() async {
    String platformName = 'unknown';
    String deviceId = 'unknown_device';
    String deviceModel = 'Unknown Device';

    try {
      if (kIsWeb) {
        platformName = 'web';
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceModel = webInfo.browserName.name;
        deviceId = 'web_${webInfo.userAgent.hashCode.abs()}';
      } else if (Platform.isAndroid) {
        platformName = 'android';
        final androidInfo = await _deviceInfo.androidInfo;
        deviceModel = '${androidInfo.manufacturer} ${androidInfo.model}';
        deviceId = androidInfo.id.isNotEmpty ? androidInfo.id : 'android_${androidInfo.model.hashCode.abs()}';
      } else if (Platform.isIOS) {
        platformName = 'ios';
        final iosInfo = await _deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
        deviceId = iosInfo.identifierForVendor ?? 'ios_${iosInfo.name.hashCode.abs()}';
      } else if (Platform.isWindows) {
        platformName = 'windows';
        final windowsInfo = await _deviceInfo.windowsInfo;
        deviceModel = windowsInfo.computerName;
        deviceId = windowsInfo.deviceId;
      } else if (Platform.isMacOS) {
        platformName = 'macos';
        final macInfo = await _deviceInfo.macOsInfo;
        deviceModel = macInfo.model;
        deviceId = macInfo.systemGUID ?? 'macos';
      } else if (Platform.isLinux) {
        platformName = 'linux';
        final linuxInfo = await _deviceInfo.linuxInfo;
        deviceModel = linuxInfo.name;
        deviceId = linuxInfo.machineId ?? 'linux';
      }
    } catch (e) {
      debugPrint('[FcmTokenService] Error retrieving device info: $e');
    }

    _cachedDeviceId = deviceId;
    return {
      'platform': platformName,
      'deviceId': deviceId,
      'deviceModel': deviceModel,
    };
  }

  /// Register current device FCM token in Firestore under:
  /// `{role}/{uid}/fcmTokens/{tokenId}`
  Future<void> registerToken({
    required String uid,
    required String role,
  }) async {
    if (uid.isEmpty || role.isEmpty) return;

    _currentUid = uid;
    _currentRole = role;

    try {
      // On platforms where FCM push is supported (Android, iOS, Web)
      String? token;
      try {
        token = await _messaging.getToken();
      } catch (e) {
        debugPrint('[FcmTokenService] FCM getToken error: $e');
      }

      if (token == null || token.isEmpty) {
        debugPrint('[FcmTokenService] No FCM token available for device');
        return;
      }

      _cachedToken = token;
      final deviceDetails = await _getDeviceDetails();
      final String docId = _generateTokenDocId(token, deviceDetails['deviceId']!);

      // Save token document under role collection (User, Broker, or Driver)
      await _firestore
          .collection(role)
          .doc(uid)
          .collection('fcmTokens')
          .doc(docId)
          .set({
        'token': token,
        'platform': deviceDetails['platform'],
        'device_id': deviceDetails['deviceId'],
        'device_model': deviceDetails['deviceModel'],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_seen_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('[FcmTokenService] Successfully registered FCM token for $role: $uid (Doc: $docId)');

      _startTokenRefreshListener();
    } catch (e) {
      debugPrint('[FcmTokenService] Failed to register FCM token: $e');
    }
  }

  /// Setup automatic token refresh listener
  void _startTokenRefreshListener() {
    if (_isListeningRefresh) return;
    _isListeningRefresh = true;

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FcmTokenService] FCM token refreshed');
      if (_currentUid == null || _currentRole == null || newToken.isEmpty) return;

      try {
        final deviceDetails = await _getDeviceDetails();
        final String oldDocId = _cachedToken != null
            ? _generateTokenDocId(_cachedToken!, deviceDetails['deviceId']!)
            : '';

        final String newDocId = _generateTokenDocId(newToken, deviceDetails['deviceId']!);

        // If docId changed, clean up old token doc
        if (oldDocId.isNotEmpty && oldDocId != newDocId) {
          try {
            await _firestore
                .collection(_currentRole!)
                .doc(_currentUid!)
                .collection('fcmTokens')
                .doc(oldDocId)
                .delete();
          } catch (_) {}
        }

        _cachedToken = newToken;

        // Register new token document
        await _firestore
            .collection(_currentRole!)
            .doc(_currentUid!)
            .collection('fcmTokens')
            .doc(newDocId)
            .set({
          'token': newToken,
          'platform': deviceDetails['platform'],
          'device_id': deviceDetails['deviceId'],
          'device_model': deviceDetails['deviceModel'],
          'updated_at': FieldValue.serverTimestamp(),
          'last_seen_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('[FcmTokenService] Token refresh updated in Firestore');
      } catch (e) {
        debugPrint('[FcmTokenService] Error updating refreshed token: $e');
      }
    });
  }

  /// Remove only the current device's FCM token document on user logout
  Future<void> removeCurrentDeviceToken({
    required String uid,
    required String role,
  }) async {
    if (uid.isEmpty || role.isEmpty) return;

    try {
      final token = _cachedToken ?? await _messaging.getToken().catchError((_) => null);
      final deviceId = _cachedDeviceId ?? (await _getDeviceDetails())['deviceId']!;

      if (token != null && token.isNotEmpty) {
        final docId = _generateTokenDocId(token, deviceId);
        await _firestore
            .collection(role)
            .doc(uid)
            .collection('fcmTokens')
            .doc(docId)
            .delete();
        debugPrint('[FcmTokenService] Deleted token document ($docId) for $role: $uid');
      }

      // Also clean up local token if supported
      try {
        await _messaging.deleteToken();
      } catch (_) {}

      _cachedToken = null;
      _currentUid = null;
      _currentRole = null;
    } catch (e) {
      debugPrint('[FcmTokenService] Error removing token on logout: $e');
    }
  }
}
