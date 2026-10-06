import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';

class ReviewService {
  static final ReviewService _instance = ReviewService._internal();
  factory ReviewService() => _instance;
  ReviewService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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


      await reviewRef.set(reviewData);


      await _firestore.collection("Reviews").doc(reviewDocId).set(reviewData, SetOptions(merge: true));


      final allReviewsSnap = await _firestore
          .collection("Broker")
          .doc(brokerId)
          .collection("Reviews")
          .get();

      int count = 0;
      double totalRating = 0.0;
      int star5 = 0, star4 = 0, star3 = 0, star2 = 0, star1 = 0;

      for (var doc in allReviewsSnap.docs) {
        final data = doc.data();
        final r = (data['rating'] as num?)?.toDouble() ?? 0.0;
        if (r > 0) {
          count++;
          totalRating += r;

          final rounded = r.round();
          if (rounded >= 5) star5++;
          else if (rounded == 4) star4++;
          else if (rounded == 3) star3++;
          else if (rounded == 2) star2++;
          else if (rounded <= 1) star1++;
        }
      }

      final double avgRating = count > 0 ? double.parse((totalRating / count).toStringAsFixed(1)) : 0.0;


      await _firestore.collection("Broker").doc(brokerId).set({
        'rating': avgRating,
        'overall_rating': avgRating,
        'total_reviews': count,
        'reviews': count,
        'review_count': count,
        'star_5': star5,
        'star_4': star4,
        'star_3': star3,
        'star_2': star2,
        'star_1': star1,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      final orderUpdate = {
        'user_reviewed_broker': true,
        'broker_user_rating': rating,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection("Orders").doc(orderId).set(orderUpdate, SetOptions(merge: true));

      try {
        await _firestore
            .collection("User")
            .doc(userId)
            .collection("Requests")
            .doc(orderId)
            .set(orderUpdate, SetOptions(merge: true));
      } catch (_) {}

      try {
        await _firestore
            .collection("Broker")
            .doc(brokerId)
            .collection("IncomingRequests")
            .doc(orderId)
            .set(orderUpdate, SetOptions(merge: true));
      } catch (_) {}


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


  Future<bool> submitDriverReview({
    required String orderId,
    required String driverId,
    required String reviewerId,
    required String reviewerName,
    required String reviewerRole,
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


      await reviewRef.set(reviewData);


      await _firestore.collection("Reviews").doc(reviewDocId).set(reviewData, SetOptions(merge: true));


      final allDriverReviewsSnap = await _firestore
          .collection("Driver")
          .doc(driverId)
          .collection("Reviews")
          .get();

      int count = 0;
      double totalRating = 0.0;

      for (var doc in allDriverReviewsSnap.docs) {
        final data = doc.data();
        final r = (data['rating'] as num?)?.toDouble() ?? 0.0;
        if (r > 0) {
          count++;
          totalRating += r;
        }
      }

      final double avgRating = count > 0 ? double.parse((totalRating / count).toStringAsFixed(1)) : 0.0;


      await _firestore.collection("Driver").doc(driverId).set({
        'driver_rating': avgRating,
        'rating': avgRating,
        'total_reviews': count,
        'reviews': count,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      if (brokerId != null && brokerId.isNotEmpty) {
        try {
          await _firestore
              .collection("Broker")
              .doc(brokerId)
              .collection("DriverNetwork")
              .doc(driverId)
              .set({
            'driver_rating': avgRating,
            'rating': avgRating,
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (_) {}
      }


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
        } catch (_) {}
      } else if (reviewerRole == 'broker') {
        try {
          await _firestore
              .collection("Broker")
              .doc(reviewerId)
              .collection("IncomingRequests")
              .doc(orderId)
              .set(orderUpdate, SetOptions(merge: true));
        } catch (_) {}
      }


      final String notifId = "notif_drv_rev_${orderId}_$reviewerId";
      await NotificationService().sendNotification(
        targetCollection: 'Driver',
        recipientId: driverId,
        type: NotificationTypes.newReview,
        title: 'New Driver Review',
        body: '$reviewerName (${reviewerRole == 'broker' ? 'Broker' : 'User'}) rated you $rating stars.',
        notificationId: notifId,
        orderId: orderId,
        senderId: reviewerId,
        senderName: reviewerName,
        receiverRole: 'Driver',
        additionalData: {
          'rating': rating,
          'comment': comment,
        },
      );

      return true;
    } catch (e) {
      debugPrint("ReviewService submitDriverReview error: $e");
      return false;
    }
  }
}
