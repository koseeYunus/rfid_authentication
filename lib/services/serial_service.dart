import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/port_info.dart';


/// Seri port iletişimini yöneten servis sınıfı
class SerialService {
  /// Aktif seri port bağlantısı
  SerialPort? _port;

  /// Seri port okuyucu
  SerialPortReader? _reader;

  /// Bağlantı durumu
  bool _isConnected = false;

  /// Veri tamponu
  String _buffer = '';

  /// Son okunan kart numaraları
  List<int>? _lastReadNumbers;

  /// Son okuma zamanı
  DateTime? _lastReadTime;

  /// Mevcut portları listeler
  List<PortInfo> getPortsInfo() {
    try {
      final availablePorts = SerialPort.availablePorts;
      return availablePorts.map((portName) {
        final port = SerialPort(portName);

        PortInfo portInfo;
        try {
          portInfo = PortInfo(
            name: portName,
            description: port.description.toString(),
            manufacturer: port.manufacturer.toString(),
            productName: port.productName.toString(),
            serialNumber: port.serialNumber.toString(),
            vendorId: port.vendorId.toString(),
            productId: port.productId.toString(),
          );
        } catch (e) {
          print('Port bilgisi alınamadı: $e');
          portInfo = PortInfo(name: portName);
        } finally {
          port.dispose();
        }

        return portInfo;
      }).toList();
    } catch (e) {
      print('Port listesi alınamadı: $e');
      return [];
    }
  }

  /// Seri porta bağlanır
  Future<void> connect({
    required String portName,
    required Function(String) onDataReceived,
  }) async {
    try {
      // Yeni port bağlantısı oluştur
      _port = SerialPort(portName);

      // Portu aç
      if (!_port!.openReadWrite()) {
        throw Exception('Port açılamadı');
      }

      // Port ayarlarını yapılandır
      _port!.config = SerialPortConfig()
        ..baudRate = 9600
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      // Okuyucuyu başlat
      _reader = SerialPortReader(_port!);
      _isConnected = true;
      _buffer = '';

      // Veri dinlemeyi başlat
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

  /// Gelen veriyi işler
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

  /// Kart numaralarını parse eder
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

  /// Kartın işlenip işlenmemesi gerektiğini kontrol eder
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

  /// İki listenin eşitliğini kontrol eder
  bool listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Port bağlantısını kapatır
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

  /// Bağlantı durumunu döndürür
  bool isConnected() {
    return _isConnected;
  }
}