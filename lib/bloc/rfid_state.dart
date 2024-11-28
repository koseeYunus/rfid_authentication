part of 'rfid_bloc.dart';

abstract class RfidState {
  const RfidState();
}

class RfidInitial extends RfidState {
  const RfidInitial();
}

class RfidError extends RfidState {
  final String message;
  const RfidError({required this.message});
}

// BasePortState ekleyelim
abstract class BasePortState extends RfidState {
  final List<PortInfo> ports;
  final PortInfo? selectedPort;
  final CardData? lastCardRead; // Son okunan kart bilgisini ekleyelim

  const BasePortState({
    required this.ports,
    this.selectedPort,
    this.lastCardRead,
  });
}

class RfidPortsLoaded extends BasePortState {
  const RfidPortsLoaded({
    required super.ports,
    super.selectedPort,
    super.lastCardRead,
  });
}

class RfidConnecting extends BasePortState {
  const RfidConnecting({
    required super.ports,
    super.selectedPort,
    super.lastCardRead,
  });
}

class RfidConnected extends BasePortState {
  const RfidConnected({
    required super.ports,
    super.selectedPort,
    super.lastCardRead,
  });
}