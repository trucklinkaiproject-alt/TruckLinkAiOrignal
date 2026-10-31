// lib/Core/Services/orderService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:trucklinkai_orignal/Core/Services/brokerStatsService.dart';

/// Central Order Lifecycle & Status Transition Service (Phase 2.5 & 2.6).
///
/// Ensures atomic updates across all 3-4 mirrored Firestore locations:
/// - Orders/{orderId}
/// - User/{userUid}/Requests/{orderId}
/// - Broker/{brokerId}/IncomingRequests/{orderId}
/// - Driver/{driverId}/ReceivedOffers/{offerId}
///
/// Enforces valid status state machine transitions:
/// pending -> fare_offered -> accepted -> driver_offer_sent -> accepted_by_driver -> in_transit -> completed
class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const Map<String, List<String>> _allowedTransitions = {
    'pending': ['fare_offered', 'accepted', 'rejected', 'cancelled'],
    'fare_offered': ['accepted', 'rejected', 'cancelled'],
    'accepted': ['driver_offer_sent', 'cancelled'],
    'driver_offer_sent': ['accepted_by_driver', 'accepted', 'rejected_by_driver', 'cancelled'],
    'accepted_by_driver': ['in_transit', 'cancelled'],
    'in_transit': ['arrived_at_pickup', 'heading_to_drop', 'completed'],
    'arrived_at_pickup': ['heading_to_drop', 'completed'],
    'heading_to_drop': ['completed'],
  };

  /// Validates whether transitioning from [currentStatus] to [newStatus] is allowed.
  static bool isValidTransition(String currentStatus, String newStatus) {
    final curr = currentStatus.toLowerCase().trim();
    final next = newStatus.toLowerCase().trim();
    if (curr == next) return true; // Idempotent no-op

    final allowed = _allowedTransitions[curr];
    if (allowed == null) return false;
    return allowed.contains(next);
  }

  /// Atomically updates order status across Orders, User/Requests, Broker/IncomingRequests,
  /// and Driver/ReceivedOffers.
  Future<bool> updateOrderStatus({
    required String orderId,
    required String newStatus,
    String? userUid,
    String? brokerId,
    String? driverId,
    String? offerId,
    Map<String, dynamic>? extraData,
  }) async {
    if (orderId.isEmpty) return false;

    try {
      final orderRef = _firestore.collection('Orders').doc(orderId);
      final orderSnap = await orderRef.get();
      final currentData = orderSnap.data() ?? {};
      final currentStatus = (currentData['status'] ?? 'pending').toString().toLowerCase();

      // Guard: Check transition validity
      if (orderSnap.exists && !isValidTransition(currentStatus, newStatus)) {
        debugPrint('[OrderService] Invalid transition: $currentStatus -> $newStatus for order $orderId');
        return false;
      }

      // Resolve participant IDs if not provided
      final resolvedUserUid = userUid ?? currentData['user_uid'] ?? currentData['userUid'] ?? '';
      final resolvedBrokerId = brokerId ?? currentData['broker_id'] ?? currentData['brokerId'] ?? '';
      final resolvedDriverId = driverId ?? currentData['assigned_driver_id'] ?? currentData['driver_id'] ?? '';

      final Map<String, dynamic> updatePayload = {
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
        if (extraData != null) ...extraData,
      };

      if (newStatus == 'accepted') {
        updatePayload['accepted_at'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'in_transit') {
        updatePayload['ride_started_at'] ??= FieldValue.serverTimestamp();
      } else if (newStatus == 'completed') {
        updatePayload['completed_at'] = FieldValue.serverTimestamp();
      }

      final batch = _firestore.batch();

      // 1. Root Orders doc
      batch.set(orderRef, updatePayload, SetOptions(merge: true));

      // 2. User/Requests doc
      if (resolvedUserUid.isNotEmpty) {
        final userReqRef = _firestore
            .collection('User')
            .doc(resolvedUserUid)
            .collection('Requests')
            .doc(orderId);
        batch.set(userReqRef, updatePayload, SetOptions(merge: true));
      }

      // 3. Broker/IncomingRequests doc
      if (resolvedBrokerId.isNotEmpty) {
        final brokerReqRef = _firestore
            .collection('Broker')
            .doc(resolvedBrokerId)
            .collection('IncomingRequests')
            .doc(orderId);
        batch.set(brokerReqRef, updatePayload, SetOptions(merge: true));
      }

      // 4. Driver/ReceivedOffers doc
      if (resolvedDriverId.isNotEmpty && offerId != null && offerId.isNotEmpty) {
        final driverOfferRef = _firestore
            .collection('Driver')
            .doc(resolvedDriverId)
            .collection('ReceivedOffers')
            .doc(offerId);
        batch.set(driverOfferRef, updatePayload, SetOptions(merge: true));
      }

      // Commit all document updates atomically
      await batch.commit();

      // Update AI metrics idempotently via BrokerStatsService
      if (resolvedBrokerId.isNotEmpty) {
        if (newStatus == 'accepted') {
          await BrokerStatsService().recordAcceptedRequest(
            brokerId: resolvedBrokerId,
            orderId: orderId,
          );
        } else if (newStatus == 'completed') {
          await BrokerStatsService().recordCompletedRequest(
            brokerId: resolvedBrokerId,
            orderId: orderId,
            itemType: extraData?['itemType'] ?? currentData['itemType'],
          );
        } else if (newStatus == 'rejected' || newStatus == 'cancelled') {
          await BrokerStatsService().recordCancelledRequest(
            brokerId: resolvedBrokerId,
            orderId: orderId,
            reason: newStatus,
          );
        }
      }

      return true;
    } catch (e) {
      debugPrint('[OrderService] updateOrderStatus error: $e');
      return false;
    }
  }

  /// Driver rejects offer: Resets status across Broker, Orders, and User back to 'accepted'
  /// so shipper and broker see consistent state and broker can re-assign another driver.
  Future<bool> handleDriverOfferRejected({
    required String orderId,
    required String offerId,
    required String driverId,
    required String brokerId,
    String? userUid,
  }) async {
    try {
      final batch = _firestore.batch();

      final resetPayload = {
        'status': 'accepted',
        'driver_rejected': true,
        'assigned_driver_id': null,
        'assigned_driver_name': null,
        'updated_at': FieldValue.serverTimestamp(),
      };

      // 1. Orders
      batch.set(_firestore.collection('Orders').doc(orderId), resetPayload, SetOptions(merge: true));

      // 2. Broker IncomingRequests
      if (brokerId.isNotEmpty) {
        batch.set(
          _firestore.collection('Broker').doc(brokerId).collection('IncomingRequests').doc(orderId),
          resetPayload,
          SetOptions(merge: true),
        );
      }

      // 3. User Requests (fix 2.6: resets User/Requests so shipper does not see stuck driver_offer_sent)
      if (userUid != null && userUid.isNotEmpty) {
        batch.set(
          _firestore.collection('User').doc(userUid).collection('Requests').doc(orderId),
          resetPayload,
          SetOptions(merge: true),
        );
      }

      // 4. Mark Driver ReceivedOffers as rejected
      if (driverId.isNotEmpty && offerId.isNotEmpty) {
        batch.set(
          _firestore.collection('Driver').doc(driverId).collection('ReceivedOffers').doc(offerId),
          {
            'status': 'rejected',
            'rejected_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('[OrderService] handleDriverOfferRejected error: $e');
      return false;
    }
  }
}
