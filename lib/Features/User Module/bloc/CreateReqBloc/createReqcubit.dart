import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Services/notificationService.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/userRequestDataModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';

class CreateReqCubit extends Cubit<CreateReqState> {
  CreateReqCubit() : super(CreateReqInitialState());

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserRequestDataModel? currentRequest;
  String orderStatus = "Pending";
  String orderNo='notKnown';

  Future<void> createInitialRequest(
    String userUid,
    String pickupCity,
    String dropCity,
    String pickupComp,
    String dropComp,
    String itemType,
    String vehicleType,
    String additionalInfo,
    int weight,
    int quantity,
  ) async {
    try {
      emit(CreateReqLoadingState());
      await _firestore.collection("AppData").doc("appVariables").get().then((
        doc,
      ) {
        if (doc.exists) {
          orderNo = doc.data()?['orderNo'] ?? "1";
        } 
      });
      // Simulate a network request or any asynchronous operation
      String orderId = DateTime.now().millisecondsSinceEpoch.toString();
      //
      currentRequest = UserRequestDataModel(
        userUid: userUid,
        pickupCity: pickupCity,
        dropCity: dropCity,
        pickupComp: pickupComp,
        dropComp: dropComp,
        itemType: itemType,
        vehicleType: vehicleType,
        additionalInfo: additionalInfo,
        weight: weight,
        quantity: quantity,
        orderId: orderId,
        orderNo: orderNo,
        status: orderStatus,
        date: DateFormat('dd-MM-yyyy, hh:mm a').format(DateTime.now()),
      );
      // If the request is successful, emit the success state
      emit(CreateReqSuccessState("Request created successfully!"));
      await _firestore.collection("AppData").doc("appVariables").update({
        'orderNo': (int.parse(orderNo) + 1)
            .toString(), // Increment order number for next request
      });
    } catch (e) {
      // If there's an error, emit the error state with the error message
      emit(CreateReqErrorState("Failed to create request: ${e.toString()}"));
    }
  }

  Future<void> createRequestToBroker(String brokerId) async {
    try {
      emit(CreateReqLoadingState());
      if (currentRequest != null) {
        currentRequest!.brokerId = brokerId;

        await _firestore
            .collection('User')
            .doc(currentRequest!.userUid)
            .collection('Requests')
            .doc(currentRequest!.orderId)
            .set(currentRequest!.toMap());

        await _firestore
            .collection('Broker')
            .doc(currentRequest!.brokerId)
            .collection('IncomingRequests')
            .doc(currentRequest!.orderId)
            .set(currentRequest!.toMap());

        // Notify Broker of new shipment request
        try {
          final String notifId = "req_new_${currentRequest!.orderId}_${currentRequest!.userUid}";
          await NotificationService().sendNotification(
            targetCollection: 'Broker',
            recipientId: currentRequest!.brokerId,
            type: NotificationTypes.newRequest,
            title: 'New Shipment Request',
            body: 'New request for Order #${currentRequest!.orderNo}: ${currentRequest!.pickupCity} → ${currentRequest!.dropCity} (${currentRequest!.vehicleType})',
            notificationId: notifId,
            orderId: currentRequest!.orderId,
            orderNo: currentRequest!.orderNo,
            senderId: currentRequest!.userUid,
            receiverRole: 'Broker',
          );
        } catch (_) {}

        // ── AI STATS: increment total_requests atomically ──────────────────
        // Using a transaction guarantees idempotency even if the stream fires
        // multiple times; the counter only increments once per request write.
        await _firestore.runTransaction((txn) async {
          final brokerRef =
              _firestore.collection('Broker').doc(currentRequest!.brokerId);
          final snap = await txn.get(brokerRef);
          final data = snap.data() ?? {};

          final int total = ((data['total_requests'] as num?)?.toInt() ?? 0) + 1;
          final int accepted =
              (data['accepted_requests'] as num?)?.toInt() ?? 0;
          final int cancelled =
              (data['cancelled_requests'] as num?)?.toInt() ?? 0;

          final double acceptanceRate =
              total > 0 ? (accepted / total) * 100.0 : 0.0;
          final double cancellationRate =
              total > 0 ? (cancelled / total) * 100.0 : 0.0;

          txn.set(
            brokerRef,
            {
              'total_requests': total,
              'acceptance_rate': acceptanceRate,
              'cancellation_rate': cancellationRate,
              // Ensure field exists for new/existing brokers
              'accepted_requests': accepted,
              'cancelled_requests': cancelled,
              'completed_requests':
                  (data['completed_requests'] as num?)?.toInt() ?? 0,
              'completion_rate':
                  (data['completion_rate'] as num?)?.toDouble() ?? 0.0,
              'broker_rating':
                  (data['broker_rating'] as num?)?.toDouble() ?? 0.0,
              'broker_id': currentRequest!.brokerId,
            },
            SetOptions(merge: true),
          );
        });
        // ──────────────────────────────────────────────────────────────────
      } else {
        emit(CreateReqErrorState("No data available from user"));
      }
      // If the request is successful, emit the success state
      // emit(CreateReqSuccessState("Request created successfully!"));
    } catch (e) {
      // If there's an error, emit the error state with the error message
      emit(CreateReqErrorState("Failed to create request: ${e.toString()}"));
    }
  }
}
