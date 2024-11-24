import 'package:bloc/bloc.dart';
import '../models/card_data.dart';

part 'rfid_event.dart';
part 'rfid_state.dart';

class RfidBloc extends Bloc<RfidEvent, RfidState> {
  RfidBloc() : super(RfidInitial()) {
    on<ProcessSerialData>((event, emit) {
      try {
        final cardData = CardData.fromSerialData(event.data);
        emit(RfidCardRead(cardData));
      } catch (e) {
        emit(RfidError('Veri işleme hatası: ${e.toString()}'));
      }
    });

    on<ResetRfid>((event, emit) {
      emit(RfidInitial());
    });
  }
}