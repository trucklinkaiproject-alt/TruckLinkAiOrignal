import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      await FirebaseFirestore.instance
          .collection("User")
          .doc(userUid)
          .collection("Requests")
          .doc(orderId)
          .update({"brokerOffer": amount, "status": "fare_offered"});

      await FirebaseFirestore.instance
          .collection("Broker")
          .doc(brokerId)
          .collection("IncomingRequests")
          .doc(orderId)
          .update({"brokerOffer": amount, "status": "fare_offered"});

      emit(BrokerQuoteSuccess(amount));
    } catch (e) {
      emit(BrokerQuoteError(e.toString()));
    }
  }
}