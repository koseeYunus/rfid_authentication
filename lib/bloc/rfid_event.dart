part of 'rfid_bloc.dart';

abstract class RfidEvent {}

// Port yönetimi event'leri
class LoadPorts extends RfidEvent {}

class SelectPort extends RfidEvent {
  final PortInfo port;
  SelectPort(this.port);
}

// Bağlantı durumu event'leri
class ConnectToPort extends RfidEvent {}
class DisconnectPort extends RfidEvent {}

// Kart okuma event'leri
class ProcessSerialData extends RfidEvent {
  final String data;
  ProcessSerialData(this.data);
}

class ResetRfid extends RfidEvent {}