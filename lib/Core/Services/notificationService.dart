import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Deletes all notifications for a specific user/broker/driver in safe batches of up to 400 documents.
  Future<int> clearAllNotifications({
    required String collectionName, // e.g. "User", "Broker", "Driver"
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
    const int batchSize = 400; // Firestore limit is 500 ops per batch

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

  /// Marks all unread notifications as read for a specific user/broker/driver.
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
