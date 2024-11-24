// lib/services/serial_service.dart
import 'package:flutter_libserialport/flutter_libserialport.dart';

class SerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  bool _isConnected = false;
  String _buffer = '';
  List<int>? _lastReadNumbers; // Son okunan kart numaralarını tutmak için
  DateTime? _lastReadTime;     // Son okuma zamanını tutmak için

  List<String> getPorts() {
    try {
      return SerialPort.availablePorts;
    } catch (e) {
      print('Port listesi alınamadı: $e');
      return [];
    }
  }

  Future<void> connect({
    required String portName,
    required Function(String) onDataReceived,
  }) async {
    try {
      _port = SerialPort(portName);

      if (!_port!.openReadWrite()) {
        throw Exception('Port açılamadı');
      }

      _port!.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      _reader = SerialPortReader(_port!);
      _isConnected = true;
      _buffer = '';

      _reader!.stream.listen(
            (data) {
          _processData(data, onDataReceived);
        },
        onError: (error) {
          print('Okuma hatası: $error');
        },
        onDone: () {
          disconnect();
        },
      );
    } catch (e) {
      disconnect();
      throw Exception('Seri port bağlantı hatası: $e');
    }
  }

  void _processData(List<int> data, Function(String) onDataReceived) {
    try {
      // Gelen veriyi buffer'a ekle
      _buffer += String.fromCharCodes(data);

      // Satır sonlarını kontrol et
      while (_buffer.contains('\n')) {
        final index = _buffer.indexOf('\n');
        String message = _buffer.substring(0, index).trim();
        _buffer = _buffer.substring(index + 1);

        // Gelen veriyi parse et
        List<int>? numbers = _parseCardNumbers(message);
        if (numbers != null) {
          // Aynı kartın tekrar okunmasını önle
          if (_shouldProcessCard(numbers)) {
            _lastReadNumbers = numbers;
            _lastReadTime = DateTime.now();

            // Veriyi Kart ID formatına dönüştür
            final formattedMessage = "Kart ID: ${numbers.join(' ')}";
            print('İşlenen veri: $formattedMessage'); // Debug için
            onDataReceived(formattedMessage);
          }
        }
      }
    } catch (e) {
      print('Veri işleme hatası: $e');
    }
  }

  List<int>? _parseCardNumbers(String message) {
    try {
      // "195 , 148 , 169 , 13 , 243" formatındaki veriyi parse et
      final numbers = message
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map(int.parse)
          .toList();

      if (numbers.length == 5) {
        return numbers;
      }
    } catch (e) {
      print('Parse hatası: $e');
    }
    return null;
  }

  bool _shouldProcessCard(List<int> numbers) {
    // Eğer son okuma yoksa veya farklı bir kart okunduysa
    if (_lastReadNumbers == null ||
        !listEquals(_lastReadNumbers!, numbers)) {
      return true;
    }

    // Son okumadan bu yana 3 saniye geçtiyse
    if (_lastReadTime != null &&
        DateTime.now().difference(_lastReadTime!).inSeconds >= 3) {
      return true;
    }

    return false;
  }

  bool listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void disconnect() {
    _isConnected = false;
    try {
      _reader?.close();
      if (_port != null) {
        if (_port!.isOpen) {
          _port!.close();
        }
        _port!.dispose();
      }
    } catch (e) {
      print('Bağlantı kapatma hatası: $e');
    } finally {
      _buffer = '';
      _lastReadNumbers = null;
      _lastReadTime = null;
      _reader = null;
      _port = null;
    }
  }

  bool isConnected() {
    return _isConnected;
  }
}