import 'package:bloc/bloc.dart';
import '../models/card_data.dart';
import '../models/port_info.dart';
import '../services/serial_service.dart';

part 'rfid_event.dart';
part 'rfid_state.dart';

/// RFID kartlarının okunması ve işlenmesi için BLoC yapısı.
/// Bu BLoC, seri porttan gelen verileri işler ve kart okuma durumlarını yönetir.
class RfidBloc extends Bloc<RfidEvent, RfidState> {
  final SerialService serialService;

  RfidBloc({required this.serialService}) : super(RfidInitial()) {
    // Port yönetimi event'leri
    on<LoadPorts>((event, emit) {
      final ports = serialService.getPortsInfo();
      emit(RfidPortsLoaded(
        ports: ports,
        selectedPort: ports.isNotEmpty ? ports.first : null,
      ));
    });

    on<SelectPort>((event, emit) {
      if (state is BasePortState) {
        final currentState = state as BasePortState;
        emit(RfidPortsLoaded(
          ports: currentState.ports,
          selectedPort: event.port,
          lastCardRead: currentState.lastCardRead,
        ));
      }
    });

    // Bağlantı durumu event'leri
    on<ConnectToPort>((event, emit) async {
      if (state is BasePortState) {
        final currentState = state as BasePortState;
        if (currentState.selectedPort == null) return;

        emit(RfidConnecting(
          ports: currentState.ports,
          selectedPort: currentState.selectedPort,
          lastCardRead: currentState.lastCardRead,
        ));

        try {
          await serialService.connect(
            portName: currentState.selectedPort!.name,
            onDataReceived: (data) => add(ProcessSerialData(data)),
          );

          emit(RfidConnected(
            ports: currentState.ports,
            selectedPort: currentState.selectedPort,
            lastCardRead: currentState.lastCardRead,
          ));
        } catch (e) {
          emit(RfidError(message: e.toString()));
          emit(RfidPortsLoaded(
            ports: currentState.ports,
            selectedPort: currentState.selectedPort,
            lastCardRead: currentState.lastCardRead,
          ));
        }
      }
    });

    on<DisconnectPort>((event, emit) {
      if (state is BasePortState) {
        final currentState = state as BasePortState;
        serialService.disconnect();
        emit(RfidPortsLoaded(
          ports: currentState.ports,
          selectedPort: currentState.selectedPort,
          lastCardRead: null, // Bağlantı kesildiğinde kart bilgisini temizle
        ));
      }
    });

    // Kart okuma event'leri
    on<ProcessSerialData>((event, emit) {
      try {
        if (state is BasePortState) {
          final currentState = state as BasePortState;
          final cardData = CardData.fromSerialData(event.data);

          // Mevcut bağlantı durumunu koru ve kart bilgisini güncelle
          if (state is RfidConnected) {
            emit(RfidConnected(
              ports: currentState.ports,
              selectedPort: currentState.selectedPort,
              lastCardRead: cardData,
            ));
          }
        }
      } catch (e) {
        emit(RfidError(message: e.toString()));
      }
    });

    on<ResetRfid>((event, emit) {
      emit(RfidInitial());
    });
  }
}