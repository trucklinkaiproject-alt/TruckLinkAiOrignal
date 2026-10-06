import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class NotificationTypes {
  static const String newMessage = 'chat';
  static const String newRequest = 'new_request';
  static const String requestAccepted = 'request_accepted';
  static const String requestRejected = 'request_rejected';
  static const String requestCancelled = 'request_cancelled';
  static const String counterQuote = 'counter_quote';
  static const String driverAssigned = 'driver_assigned';
  static const String driverAccepted = 'driver_accepted';
  static const String driverRejected = 'driver_rejected';
  static const String driverAtPickup = 'driver_at_pickup';
  static const String tripStarted = 'trip_started';
  static const String tripCompleted = 'trip_completed';
  static const String newReview = 'new_review';
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


  Future<String?> sendNotification({
    required String targetCollection,
    required String recipientId,
    required String type,
    required String title,
    required String body,
    String? notificationId,
    String? orderId,
    String? orderNo,
    String? chatId,
    String? senderId,
    String? senderName,
    String? receiverRole,
    Map<String, dynamic>? additionalData,
  }) async {
    if (recipientId.isEmpty || targetCollection.isEmpty) return null;

    try {
      final String notifId = notificationId != null && notificationId.isNotEmpty
          ? notificationId
          : 'notif_${DateTime.now().millisecondsSinceEpoch}_${recipientId.hashCode.abs()}';

      final Map<String, dynamic> docData = {
        'id': notifId,
        'title': title,
        'body': body,
        'subtitle': body,
        'type': type,
        'order_id': orderId ?? '',
        'order_no': orderNo ?? '',
        'chat_id': chatId ?? '',
        'sender_id': senderId ?? '',
        'sender_name': senderName ?? '',
        'recipient_id': recipientId,
        'recipient_role': targetCollection,
        'is_read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      };

      if (additionalData != null && additionalData.isNotEmpty) {
        docData.addAll(additionalData);
      }

      await _firestore
          .collection(targetCollection)
          .doc(recipientId)
          .collection('Notifications')
          .doc(notifId)
          .set(docData, SetOptions(merge: true));

      debugPrint('[NotificationService] Created notification [$notifId] for $targetCollection: $recipientId ($type)');
      return notifId;
    } catch (e) {
      debugPrint('[NotificationService] Failed to create notification: $e');
      return null;
    }
  }


  Future<void> markAsRead({
    required String collectionName,
    required String uid,
    required String notificationId,
  }) async {
    if (uid.isEmpty || notificationId.isEmpty) return;

    try {
      await _firestore
          .collection(collectionName)
          .doc(uid)
          .collection('Notifications')
          .doc(notificationId)
          .update({'is_read': true});
    } catch (e) {
      debugPrint('[NotificationService] Error marking notification as read: $e');
    }
  }


  Future<int> clearAllNotifications({
    required String collectionName,
    required String uid,
    List<QueryDocumentSnapshot>? existingDocs,
  }) async {
    if (uid.isEmpty) return 0;

    List<QueryDocumentSnapshot> docs = existingDocs ?? [];
    if (docs.isEmpty) {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .doc(uid)
          .collection("Notifications")
          .get();
      docs = querySnapshot.docs;
    }

    if (docs.isEmpty) return 0;

    int totalDeleted = 0;
    const int batchSize = 400;

    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = docs.sublist(
        i,
        i + batchSize > docs.length ? docs.length : i + batchSize,
      );

      for (var doc in chunk) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      totalDeleted += chunk.length;
    }

    return totalDeleted;
  }


  Future<void> markAllAsRead({
    required String collectionName,
    required String uid,
    List<QueryDocumentSnapshot>? existingDocs,
  }) async {
    if (uid.isEmpty) return;

    List<QueryDocumentSnapshot> docs = existingDocs ?? [];
    if (docs.isEmpty) {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .doc(uid)
          .collection("Notifications")
          .where("is_read", isEqualTo: false)
          .get();
      docs = querySnapshot.docs;
    }

    if (docs.isEmpty) return;

    const int batchSize = 400;
    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = _firestore.batch();
      final chunk = docs.sublist(
        i,
        i + batchSize > docs.length ? docs.length : i + batchSize,
      );

      for (var doc in chunk) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['is_read'] != true) {
          batch.update(doc.reference, {'is_read': true});
        }
      }

      await batch.commit();
    }
  }
}
