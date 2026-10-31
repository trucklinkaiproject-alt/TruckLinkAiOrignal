import 'package:flutter/foundation.dart';

/// Centralized, production-safe logger for TruckLink AI.
/// Prevents sensitive information leaks and provides structured tags and error reporting.
class AppLogger {
  static void debug(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[DEBUG]${tag != null ? " [$tag]" : ""}: $message');
    }
  }

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[INFO]${tag != null ? " [$tag]" : ""}: $message');
    }
  }

  static void warn(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[WARN]${tag != null ? " [$tag]" : ""}: $message');
    }
  }

  static void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (kDebugMode) {
      final errDetails = error != null ? ' | Error: $error' : '';
      debugPrint('[ERROR]${tag != null ? " [$tag]" : ""}: $message$errDetails');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
