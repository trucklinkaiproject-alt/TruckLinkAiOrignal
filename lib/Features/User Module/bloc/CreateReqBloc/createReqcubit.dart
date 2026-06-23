import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/Models/userRequestDataModel.dart';
import 'package:trucklinkai_orignal/Features/User%20Module/bloc/CreateReqBloc/createReqstate.dart';

class CreateReqCubit extends Cubit<CreateReqState> {
  CreateReqCubit() : super(CreateReqInitialState());
  final String orderNo = "1234";

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  UserRequestDataModel? currentRequest;
  String orderStatus = "Pending";

  Future<void> createInitialRequest(
    String userUid,
    String pickupCity,
    String dropCity,
    String pickupComp,
    String dropComp,
    String itemType,
    String additionalInfo,
    int weight,
    int quantity,
  ) async {
    try {
      emit(CreateReqLoadingState());
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
        additionalInfo: additionalInfo,
        weight: weight,
        quantity: quantity,
        orderId: orderId,
        orderNo: orderNo,
        status: orderStatus,
      );
      // If the request is successful, emit the success state
      emit(CreateReqSuccessState("Request created successfully!"));
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
