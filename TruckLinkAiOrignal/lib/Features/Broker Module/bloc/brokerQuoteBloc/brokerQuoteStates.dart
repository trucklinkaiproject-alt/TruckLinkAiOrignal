abstract class BrokerQuoteState {}

class BrokerQuoteInitial extends BrokerQuoteState {}

class BrokerQuoteLoading extends BrokerQuoteState {}

class BrokerQuoteSuccess extends BrokerQuoteState {
  final double amount;
  BrokerQuoteSuccess(this.amount);
}

class BrokerQuoteError extends BrokerQuoteState {
  final String error;
  BrokerQuoteError(this.error);
}