// lib/Core/Services/reviewService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submits a review for a Broker by a User.
  /// Enforces unique review per order (deterministic ID: review_order_{orderId}_user_{userId}_broker_{brokerId}).
  /// Automatically recalculates the Broker's overall rating, broker_rating, review count, and star distribution
  /// using an incremental aggregate inside a transaction (Phase 2.3).
  Future<bool> submitBrokerReview({
    required String orderId,
    required String brokerId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    if (orderId.isEmpty || brokerId.isEmpty || userId.isEmpty) {
      debugPrint("ReviewService: Invalid arguments for submitBrokerReview");
      return false;
    }

    try {
      final String reviewDocId = "review_order_${orderId}_user_${userId}_broker_$brokerId";
      final reviewRef = _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("Reviews")
          .doc(reviewDocId);
      final brokerRef = _firestore.collection("Broker").doc(brokerId);
      final orderRef = _firestore.collection("Orders").doc(orderId);

      // Check if review already exists
      final existingDoc = await reviewRef.get();
      if (existingDoc.exists) {
        debugPrint("ReviewService: Broker review already submitted for order #$orderId");
        return false;
      }

      final reviewData = {
        'review_id': reviewDocId,
        'order_id': orderId,
        'reviewer_id': userId,
        'reviewer_name': userName,
        'reviewer_role': 'user',
        'reviewee_id': brokerId,
        'reviewee_role': 'broker',
        'rating': rating,
        'comment': comment.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      // 1. Save the review document
      await reviewRef.set(reviewData);

      // Also store in root Reviews collection for public/admin auditability
      await _firestore.collection("Reviews").doc(reviewDocId).set(reviewData, SetOptions(merge: true));

      // 2. Incremental aggregation inside transaction (Phase 2.3: no reading ALL reviews)
      await _firestore.runTransaction((txn) async {
        final brokerSnap = await txn.get(brokerRef);
        final brokerData = brokerSnap.data() ?? {};

        final int prevCount = (brokerData['total_reviews'] as num?)?.toInt() ??
            (brokerData['review_count'] as num?)?.toInt() ??
            0;
        final double prevTotalRating = (brokerData['rating_sum'] as num?)?.toDouble() ??
            (((brokerData['rating'] as num?)?.toDouble() ?? 0.0) * prevCount);

        final int newCount = prevCount + 1;
        final double newTotalRating = prevTotalRating + rating;
        final double avgRating = double.parse((newTotalRating / newCount).toStringAsFixed(1));

        final rounded = rating.round();
        final int s5 = ((brokerData['star_5'] as num?)?.toInt() ?? 0) + (rounded >= 5 ? 1 : 0);
        final int s4 = ((brokerData['star_4'] as num?)?.toInt() ?? 0) + (rounded == 4 ? 1 : 0);
        final int s3 = ((brokerData['star_3'] as num?)?.toInt() ?? 0) + (rounded == 3 ? 1 : 0);
        final int s2 = ((brokerData['star_2'] as num?)?.toInt() ?? 0) + (rounded == 2 ? 1 : 0);
        final int s1 = ((brokerData['star_1'] as num?)?.toInt() ?? 0) + (rounded <= 1 ? 1 : 0);

        txn.set(brokerRef, {
          'rating': avgRating,
          'overall_rating': avgRating,
          'broker_rating': avgRating, // Phase 2.3: Synchronized broker_rating
          'rating_sum': newTotalRating,
          'total_reviews': newCount,
          'reviews': newCount,
          'review_count': newCount,
          'star_5': s5,
          'star_4': s4,
          'star_3': s3,
          'star_2': s2,
          'star_1': s1,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // 3. Update order flags to mark reviewed
      final orderUpdate = {
        'user_reviewed_broker': true,
        'broker_user_rating': rating,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await orderRef.set(orderUpdate, SetOptions(merge: true));

      try {
        await _firestore
            .collection("User")
            .doc(userId)
            .collection("Requests")
            .doc(orderId)
            .set(orderUpdate, SetOptions(merge: true));
      } catch (e) {
        debugPrint("ReviewService: Failed to update User/Requests flag: $e");
      }

      try {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .set(orderUpdate, SetOptions(merge: true));
      } catch (e) {
        debugPrint("ReviewService: Failed to update Broker/IncomingRequests flag: $e");
      }

      // 4. Send real-time notification to Broker
      final String notifId = "notif_brk_rev_${orderId}_$userId";
      await NotificationService().sendNotification(
        targetCollection: 'Broker',
        recipientId: brokerId,
        type: NotificationTypes.newReview,
        title: 'New Broker Review',
        body: '$userName rated you $rating stars: "${comment.isNotEmpty ? comment : 'No comment'}"',
        notificationId: notifId,
        orderId: orderId,
        senderId: userId,
        senderName: userName,
        receiverRole: 'Broker',
        additionalData: {
          'rating': rating,
          'comment': comment,
        },
      );

      return true;
    } catch (e) {
      debugPrint("ReviewService submitBrokerReview error: $e");
      return false;
    }
  }

  /// Submits a review for a Driver by either a User or a Broker.
  /// Enforces unique review per order/role (deterministic ID: review_order_{orderId}_{reviewerRole}_{reviewerId}_driver_{driverId}).
  /// Recalculates Driver's overall rating and total review count incrementally (Phase 2.3).
  Future<bool> submitDriverReview({
    required String orderId,
    required String driverId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerRole, // 'user' or 'broker'
    required double rating,
    required String comment,
    String? brokerId,
  }) async {
    if (orderId.isEmpty || driverId.isEmpty || reviewerId.isEmpty) {
      debugPrint("ReviewService: Invalid arguments for submitDriverReview");
      return false;
    }

    try {
      final String reviewDocId = "review_order_${orderId}_${reviewerRole}_${reviewerId}_driver_$driverId";
      final reviewRef = _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("Reviews")
          .doc(reviewDocId);
      final driverRef = _firestore.collection("Driver").doc(driverId);

      final existingDoc = await reviewRef.get();
      if (existingDoc.exists) {
        debugPrint("ReviewService: Driver review already submitted by $reviewerRole for order #$orderId");
        return false;
      }

      final reviewData = {
        'review_id': reviewDocId,
        'order_id': orderId,
        'reviewer_id': reviewerId,
        'reviewer_name': reviewerName,
        'reviewer_role': reviewerRole,
        'reviewee_id': driverId,
        'reviewee_role': 'driver',
        'rating': rating,
        'comment': comment.trim(),
        'created_at': FieldValue.serverTimestamp(),
      };

      // 1. Save the review
      await reviewRef.set(reviewData);

      // Also store in root Reviews collection
      await _firestore.collection("Reviews").doc(reviewDocId).set(reviewData, SetOptions(merge: true));

      // 2. Incremental aggregate in transaction (Phase 2.3)
      double avgRating = rating;
      int count = 1;

      await _firestore.runTransaction((txn) async {
        final driverSnap = await txn.get(driverRef);
        final driverData = driverSnap.data() ?? {};

        final int prevCount = (driverData['total_reviews'] as num?)?.toInt() ??
            (driverData['reviews'] as num?)?.toInt() ??
            0;
        final double prevTotalRating = (driverData['rating_sum'] as num?)?.toDouble() ??
            (((driverData['driver_rating'] as num?)?.toDouble() ??
                (driverData['rating'] as num?)?.toDouble() ??
                0.0) * prevCount);

        count = prevCount + 1;
        final double newTotalRating = prevTotalRating + rating;
        avgRating = double.parse((newTotalRating / count).toStringAsFixed(1));

        txn.set(driverRef, {
          'driver_rating': avgRating,
          'rating': avgRating,
          'rating_sum': newTotalRating,
          'total_reviews': count,
          'reviews': count,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      // 3. Sync rating to Broker's DriverNetwork mirror (Phase 2.3)
      String targetBrokerId = brokerId ?? '';
      if (targetBrokerId.isEmpty) {
        try {
          final orderSnap = await _firestore.collection("Orders").doc(orderId).get();
          targetBrokerId = (orderSnap.data()?['broker_id'] ?? orderSnap.data()?['brokerId'] ?? '').toString();
        } catch (e) {
          debugPrint("ReviewService: Could not resolve brokerId from Orders: $e");
        }
      }

      if (targetBrokerId.isNotEmpty) {
        try {
          await _firestore
              .collection("Broker")
              .doc(targetBrokerId)
              .collection("DriverNetwork")
              .doc(driverId)
              .set({
            'driver_rating': avgRating,
            'rating': avgRating,
            'total_reviews': count,
            'reviews': count,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("ReviewService: Failed to sync DriverNetwork rating: $e");
        }
      }

      // 4. Update order flag
      final String flagKey = reviewerRole == 'broker' ? 'broker_reviewed_driver' : 'user_reviewed_driver';
      final orderUpdate = {
        flagKey: true,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection("Orders").doc(orderId).set(orderUpdate, SetOptions(merge: true));

      if (reviewerRole == 'user') {
        try {
          await _firestore
              .collection("User")
              .doc(reviewerId)
              .collection("Requests")
              .doc(orderId)
              .set(orderUpdate, SetOptions(merge: true));
        } catch (e) {
          debugPrint("ReviewService: Failed to update User/Requests flag: $e");
        }
      } else if (reviewerRole == 'broker') {
        try {
          await _firestore
              .collection("Broker")
              .doc(reviewerId)
              .collection("IncomingRequests")
              .doc(orderId)
              .set(orderUpdate, SetOptions(merge: true));
        } catch (e) {
          debugPrint("ReviewService: Failed to update Broker/IncomingRequests flag: $e");
        }
      }

      // 5. Send notification to Driver
      final String notifId = "notif_drv_rev_${orderId}_$reviewerId";
      await NotificationService().sendNotification(
        targetCollection: 'Driver',
        recipientId: driverId,
        type: NotificationTypes.newReview,
        title: 'New Rating Received',
        body: '$reviewerName rated your trip $rating stars: "${comment.isNotEmpty ? comment : 'Good trip'}"',
        notificationId: notifId,
        orderId: orderId,
        senderId: reviewerId,
        senderName: reviewerName,
        receiverRole: 'Driver',
        additionalData: {
          'rating': rating,
          'comment': comment,
          'reviewer_role': reviewerRole,
        },
      );

      return true;
    } catch (e) {
      debugPrint("ReviewService submitDriverReview error: $e");
      return false;
    }
  }
}
