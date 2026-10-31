import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:trucklinkai_orignal/Core/Services/appLogger.dart';
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
    int quantity, {
    double pickupLat = 0.0,
    double pickupLng = 0.0,
    double dropLat = 0.0,
    double dropLng = 0.0,
  }) async {
    try {
      emit(CreateReqLoadingState());

      // Generate a time-based orderId (guaranteed unique per millisecond)
      final String orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Atomically reserve the next order number inside a transaction.
      // This prevents race conditions when multiple users create orders simultaneously.
      String allocatedOrderNo;
      try {
        allocatedOrderNo = await _firestore.runTransaction<String>((txn) async {
          final appVarsRef = _firestore.collection("AppData").doc("appVariables");
          final snap = await txn.get(appVarsRef);

          int current = 1;
          if (snap.exists) {
            final raw = snap.data()?['orderNo'];
            if (raw is int) {
              current = raw;
            } else if (raw is String) {
              current = int.tryParse(raw) ?? 1;
            }
          }

          // Increment counter atomically
          txn.set(appVarsRef, {'orderNo': current + 1}, SetOptions(merge: true));
          return current.toString();
        });
      } catch (txnError) {
        AppLogger.warn("Order counter transaction fallback: $txnError", "CreateReqCubit");
        allocatedOrderNo = (DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0');
      }

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
        orderNo: allocatedOrderNo,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropLat: dropLat,
        dropLng: dropLng,
        status: orderStatus,
        date: DateFormat('dd-MM-yyyy, hh:mm a').format(DateTime.now()),
      );

      emit(CreateReqSuccessState("Request created successfully!"));
    } catch (e) {
      emit(CreateReqErrorState("Failed to create request: ${e.toString()}"));
    }
  }

  Future<void> createRequestToBroker(String brokerId) async {
    try {
      emit(CreateReqLoadingState());
      if (currentRequest == null) {
        emit(CreateReqErrorState("No shipment order details available."));
        return;
      }

      currentRequest!.brokerId = brokerId;
      final requestMap = currentRequest!.toMap();
      final orderId = currentRequest!.orderId;
      final userUid = currentRequest!.userUid;

      // Atomically create order documents across all mirrored locations:
      // 1. User/{userUid}/Requests/{orderId}
      // 2. Broker/{brokerId}/IncomingRequests/{orderId}
      // 3. Root Orders/{orderId} (Central canonical document)
      final batch = _firestore.batch();

      final userReqRef = _firestore
          .collection('User')
          .doc(userUid)
          .collection('Requests')
          .doc(orderId);
      batch.set(userReqRef, requestMap);

      final brokerReqRef = _firestore
          .collection('Broker')
          .doc(brokerId)
          .collection('IncomingRequests')
          .doc(orderId);
      batch.set(brokerReqRef, requestMap);

      final rootOrderRef = _firestore.collection('Orders').doc(orderId);
      batch.set(rootOrderRef, requestMap);

      await batch.commit();

      // Notify Broker of new shipment request
      try {
        final String notifId = "req_new_${orderId}_$userUid";
        await NotificationService().sendNotification(
          targetCollection: 'Broker',
          recipientId: brokerId,
          type: NotificationTypes.newRequest,
          title: 'New Shipment Request',
          body: 'New request for Order #${currentRequest!.orderNo}: ${currentRequest!.pickupCity} → ${currentRequest!.dropCity} (${currentRequest!.vehicleType})',
          notificationId: notifId,
          orderId: orderId,
          orderNo: currentRequest!.orderNo,
          senderId: userUid,
          receiverRole: 'Broker',
        );
      } catch (e, stack) {
        AppLogger.error("Failed to send new shipment notification", e, stack, "CreateReqCubit");
      }

      // Safe non-blocking update of broker total request counter
      try {
        final brokerRef = _firestore.collection('Broker').doc(brokerId);
        final snap = await brokerRef.get();
        if (snap.exists) {
          final data = snap.data() ?? {};
          final int total = ((data['total_requests'] as num?)?.toInt() ?? 0) + 1;
          await brokerRef.set({'total_requests': total}, SetOptions(merge: true));
        }
      } catch (e) {
        AppLogger.warn("Broker total requests metric update skipped: $e", "CreateReqCubit");
      }

      emit(CreateReqSuccessState("Shipment request submitted successfully!"));
    } catch (e) {
      emit(CreateReqErrorState("Failed to create request: ${e.toString()}"));
    }
  }
}
