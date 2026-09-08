import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/Broker%20Module/bloc/brokerQuoteBloc/brokerQuoteStates.dart';

class BrokerQuoteCubit extends Cubit<BrokerQuoteState> {
  BrokerQuoteCubit() : super(BrokerQuoteInitial());

  Future<void> submitQuote({
    required String userUid,
    required String orderId,
    required String brokerId,
    required double amount,
  }) async {
    emit(BrokerQuoteLoading());

    try {
      // 1. Fetch real Broker details
      String brokerName = "Broker";
      String brokerPhone = "";
      String brokerAvatar = "";
      double brokerRating = 0.0;
      int brokerReviewCount = 0;

      try {
        final brokerDoc = await FirebaseFirestore.instance.collection("Broker").doc(brokerId).get();
        if (brokerDoc.exists && brokerDoc.data() != null) {
          final bData = brokerDoc.data()!;
          brokerName = bData['name'] ?? bData['broker_name'] ?? bData['brokerName'] ?? "Broker";
          brokerPhone = bData['phone'] ?? bData['phone_number'] ?? "";
          brokerAvatar = bData['profile_image'] ?? bData['profileImage'] ?? bData['avatar'] ?? "";
          brokerRating = (bData['rating'] as num?)?.toDouble() ?? (bData['overall_rating'] as num?)?.toDouble() ?? 0.0;
          brokerReviewCount = (bData['review_count'] as num?)?.toInt() ?? (bData['total_reviews'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {}

      final updateData = {
        "brokerOffer": amount,
        "quoteAmount": amount,
        "customer_fare": amount,
        "customerFare": amount,
        "accepted_fare": amount,
        "fare": amount,
        "brokerId": brokerId,
        "brokerName": brokerName,
        "brokerPhone": brokerPhone,
        "brokerRating": brokerRating,
        "status": "fare_offered",
        "quote_submitted_at": FieldValue.serverTimestamp(),
      };

      // 2. Update User Request
      await FirebaseFirestore.instance
          .collection("User")
          .doc(userUid)
          .collection("Requests")
          .doc(orderId)
          .update(updateData);

      // 3. Update Broker Incoming Request
      await FirebaseFirestore.instance
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update(updateData);

      // 4. Send Real Notification to User
      final notifId = 'broker_offer_$orderId';
      await NotificationService().sendNotification(
        targetCollection: 'User',
        recipientId: userUid,
        type: NotificationTypes.counterQuote,
        title: 'New Quote from $brokerName',
        body: '$brokerName has offered PKR ${amount.toStringAsFixed(0)} for Order #$orderId',
        notificationId: notifId,
        orderId: orderId,
        senderId: brokerId,
        senderName: brokerName,
        receiverRole: 'User',
        additionalData: {
          'brokerId': brokerId,
          'brokerName': brokerName,
          'brokerPhone': brokerPhone,
          'brokerAvatar': brokerAvatar,
          'brokerRating': brokerRating,
          'brokerReviewCount': brokerReviewCount,
          'brokerOffer': amount,
        },
      );

      emit(BrokerQuoteSuccess(amount));
    } catch (e) {
      emit(BrokerQuoteError(e.toString()));
    }
  }
}