part of 'rfid_bloc.dart';

abstract class RfidState {}

class RfidInitial extends RfidState {}
class RfidLoading extends RfidState {}
class RfidCardRead extends RfidState {
  final CardData cardData;
  RfidCardRead(this.cardData);
}
class RfidError extends RfidState {
  final String message;
  RfidError(this.message);
}
