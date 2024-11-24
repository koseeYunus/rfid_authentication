part of 'rfid_bloc.dart';

abstract class RfidEvent {}

class ProcessSerialData extends RfidEvent {
  final String data;
  ProcessSerialData(this.data);
}

class ResetRfid extends RfidEvent {}
