// lib/Core/Services/brokerStatsService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// BrokerStatsService
///
/// Shared, idempotent service for managing Broker performance metrics and
/// machine learning data readiness (Phase 2.1, 2.2, Phase 5).
///
/// Metric definitions:
/// - total_requests: Total initial shipment requests directed to this broker.
/// - accepted_requests: Requests accepted by broker (either directly or after quote).
/// - cancelled_requests: Requests rejected by broker, cancelled by shipper, or aborted.
/// - completed_requests: Successfully delivered shipments (cargo reached dropoff).
///
/// Rates (0.0 to 100.0%):
/// - acceptance_rate = (accepted_requests / total_requests) * 100
/// - cancellation_rate = (cancelled_requests / total_requests) * 100
/// - completion_rate = (completed_requests / accepted_requests) * 100
///
/// Guards against double counting using per-order flags:
/// - order.accepted_counted == true
/// - order.completed_counted == true
/// - order.cancelled_counted == true
/// - order.total_counted == true
class BrokerStatsService {
  static final BrokerStatsService _instance = BrokerStatsService._internal();
  factory BrokerStatsService() => _instance;
  BrokerStatsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Recalculates rates from base counters
  static Map<String, dynamic> computeRates({
    required int total,
    required int accepted,
    required int cancelled,
    required int completed,
  }) {
    final double acceptanceRate = total > 0 ? double.parse(((accepted / total) * 100.0).toStringAsFixed(1)) : 0.0;
    final double cancellationRate = total > 0 ? double.parse(((cancelled / total) * 100.0).toStringAsFixed(1)) : 0.0;
    final double completionRate = accepted > 0 ? double.parse(((completed / accepted) * 100.0).toStringAsFixed(1)) : 0.0;

    return {
      'total_requests': total,
      'accepted_requests': accepted,
      'cancelled_requests': cancelled,
      'completed_requests': completed,
      'acceptance_rate': acceptanceRate,
      'cancellation_rate': cancellationRate,
      'completion_rate': completionRate,
    };
  }

  /// Atomically increments accepted_requests if not already counted for [orderId].
  Future<void> recordAcceptedRequest({
    required String brokerId,
    required String orderId,
  }) async {
    if (brokerId.isEmpty || orderId.isEmpty) return;

    try {
      final orderRef = _firestore.collection('Orders').doc(orderId);
      final brokerRef = _firestore.collection('Broker').doc(brokerId);

      await _firestore.runTransaction((txn) async {
        final orderSnap = await txn.get(orderRef);
        final orderData = orderSnap.data() ?? {};

        // Guard: idempotent check
        if (orderData['accepted_counted'] == true) {
          debugPrint('[BrokerStatsService] Order $orderId already marked accepted_counted.');
          return;
        }

        final brokerSnap = await txn.get(brokerRef);
        final brokerData = brokerSnap.data() ?? {};

        final int total = (brokerData['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = ((brokerData['accepted_requests'] as num?)?.toInt() ?? 0) + 1;
        final int cancelled = (brokerData['cancelled_requests'] as num?)?.toInt() ?? 0;
        final int completed = (brokerData['completed_requests'] as num?)?.toInt() ?? 0;

        final rates = computeRates(
          total: total,
          accepted: accepted,
          cancelled: cancelled,
          completed: completed,
        );

        txn.set(brokerRef, {
          ...rates,
          'broker_id': brokerId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Mark flag on Order doc
        txn.set(orderRef, {
          'accepted_counted': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[BrokerStatsService] recordAcceptedRequest error: $e');
    }
  }

  /// Atomically increments completed_requests if not already counted for [orderId].
  /// Also updates Phase 5 item_type_counts on the Broker doc.
  Future<void> recordCompletedRequest({
    required String brokerId,
    required String orderId,
    String? itemType,
  }) async {
    if (brokerId.isEmpty || orderId.isEmpty) return;

    try {
      final orderRef = _firestore.collection('Orders').doc(orderId);
      final brokerRef = _firestore.collection('Broker').doc(brokerId);

      await _firestore.runTransaction((txn) async {
        final orderSnap = await txn.get(orderRef);
        final orderData = orderSnap.data() ?? {};

        // Guard: idempotent check prevents double counting
        if (orderData['completed_counted'] == true) {
          debugPrint('[BrokerStatsService] Order $orderId already marked completed_counted.');
          return;
        }

        final brokerSnap = await txn.get(brokerRef);
        final brokerData = brokerSnap.data() ?? {};

        final int total = (brokerData['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = (brokerData['accepted_requests'] as num?)?.toInt() ?? 0;
        final int cancelled = (brokerData['cancelled_requests'] as num?)?.toInt() ?? 0;
        final int completed = ((brokerData['completed_requests'] as num?)?.toInt() ?? 0) + 1;

        final rates = computeRates(
          total: total,
          accepted: accepted,
          cancelled: cancelled,
          completed: completed,
        );

        // Phase 5: Maintain item_type_counts map { "iron": 12, "cement": 3 }
        final resolvedItemType = (itemType ?? orderData['itemType'] ?? orderData['item_type'] ?? '').toString().trim().toLowerCase();
        Map<String, dynamic> itemTypeCounts = Map<String, dynamic>.from(brokerData['item_type_counts'] ?? {});
        if (resolvedItemType.isNotEmpty) {
          final int currentItemCount = (itemTypeCounts[resolvedItemType] as num?)?.toInt() ?? 0;
          itemTypeCounts[resolvedItemType] = currentItemCount + 1;
        }

        txn.set(brokerRef, {
          ...rates,
          'item_type_counts': itemTypeCounts,
          'broker_id': brokerId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Mark flag on Order doc
        txn.set(orderRef, {
          'completed_counted': true,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[BrokerStatsService] recordCompletedRequest error: $e');
    }
  }

  /// Atomically increments cancelled_requests if not already counted for [orderId].
  Future<void> recordCancelledRequest({
    required String brokerId,
    required String orderId,
    String? reason,
  }) async {
    if (brokerId.isEmpty || orderId.isEmpty) return;

    try {
      final orderRef = _firestore.collection('Orders').doc(orderId);
      final brokerRef = _firestore.collection('Broker').doc(brokerId);

      await _firestore.runTransaction((txn) async {
        final orderSnap = await txn.get(orderRef);
        final orderData = orderSnap.data() ?? {};

        if (orderData['cancelled_counted'] == true) {
          debugPrint('[BrokerStatsService] Order $orderId already marked cancelled_counted.');
          return;
        }

        final brokerSnap = await txn.get(brokerRef);
        final brokerData = brokerSnap.data() ?? {};

        final int total = (brokerData['total_requests'] as num?)?.toInt() ?? 0;
        final int accepted = (brokerData['accepted_requests'] as num?)?.toInt() ?? 0;
        final int cancelled = ((brokerData['cancelled_requests'] as num?)?.toInt() ?? 0) + 1;
        final int completed = (brokerData['completed_requests'] as num?)?.toInt() ?? 0;

        final rates = computeRates(
          total: total,
          accepted: accepted,
          cancelled: cancelled,
          completed: completed,
        );

        txn.set(brokerRef, {
          ...rates,
          'broker_id': brokerId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        txn.set(orderRef, {
          'cancelled_counted': true,
          'cancel_reason': reason ?? 'cancelled',
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('[BrokerStatsService] recordCancelledRequest error: $e');
    }
  }
}
