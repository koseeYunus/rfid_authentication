import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../models/port_info.dart';

class OSDPSerialService {
  SerialPort? _port;
  SerialPortReader? _reader;
  bool _isConnected = false;
  List<int> _buffer = []; // Binary buffer
  List<int>? _lastReadCard;
  DateTime? _lastReadTime;

  List<PortInfo> getPortsInfo() {
    try {
      final availablePorts = SerialPort.availablePorts;
      return availablePorts.map((portName) {
        final port = SerialPort(portName);
        PortInfo portInfo;

        try {
          portInfo = PortInfo(
            name: portName,
            description: port.description ?? '',
            manufacturer: port.manufacturer ?? '',
            productName: port.productName ?? '',
            serialNumber: port.serialNumber ?? '',
            vendorId: int.tryParse(port.vendorId.toString()) ?? 0,
            productId: int.tryParse(port.productId.toString()) ?? 0,
            portType: port.transport.toString(),
            subsystem: '',
            baudRate: port.config.baudRate,
            isOpen: port.isOpen,
            additionalInfo: _getPortAdditionalInfo(port),
          );
        } catch (e) {
          print('Port bilgisi alınırken hata: $e');
          portInfo = PortInfo(name: portName);
        } finally {
          try {
            if (!port.isOpen) port.dispose();
          } catch (e) {
            print('Port dispose edilirken hata: $e');
          }
        }

        return portInfo;
      }).toList();
    } catch (e) {
      print('Port listesi alınamadı: $e');
      return [];
    }
  }

  Map<String, String> _getPortAdditionalInfo(SerialPort port) {
    final additionalInfo = <String, String>{};
    try {
      additionalInfo['Transport'] = port.transport.toString();
      if (port.transport == SerialPortTransport.usb) {
        additionalInfo['USB Bus'] = port.busNumber.toString();
        additionalInfo['USB Device'] = port.deviceNumber.toString();
      }
    } catch (e) {
      print('Port ek bilgileri alınamadı: $e');
    }
    return additionalInfo;
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

      // OSDP için standart konfigürasyon
      _port!.config = SerialPortConfig()
        ..baudRate = 38400
        ..bits = 8
        ..stopBits = 1
        ..parity = SerialPortParity.none
        ..setFlowControl(SerialPortFlowControl.none);

      // Debug bilgileri
      _printPortDetails();

      _reader = SerialPortReader(_port!);
      _isConnected = true;
      _buffer = [];

      _reader!.stream.listen(
            (data) {
          print('Raw Data (HEX): ${_bytesToHex(data)}');
          _processOSDPData(data, onDataReceived);
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
      throw Exception('OSDP port bağlantı hatası: $e');
    }
  }

  void _processOSDPData(List<int> data, Function(String) onDataReceived) {
    try {
      _buffer.addAll(data);
      print('Buffer (HEX): ${_bytesToHex(_buffer)}');

      while (_buffer.length >= 7) { // Minimum OSDP paket boyutu
        // OSDP SOM (0x53) kontrolü
        if (_buffer[0] != 0x53) {
          _buffer.removeAt(0);
          continue;
        }

        // Paket uzunluğu
        int length = _buffer[2];
        if (length > _buffer.length) break;

        // Tam paketi al
        List<int> packet = _buffer.sublist(0, length);
        _processOSDPPacket(packet, onDataReceived);

        // İşlenen paketi buffer'dan çıkar
        _buffer = _buffer.sublist(length);
      }
    } catch (e) {
      print('OSDP veri işleme hatası: $e');
      _buffer.clear();
    }
  }

  void _processOSDPPacket(List<int> packet, Function(String) onDataReceived) {
    try {
      print('Processing OSDP Packet: ${_bytesToHex(packet)}');

      // Paket tipi kontrolü (örnek)
      if (packet.length >= 5) {
        int cmd = packet[4];

        // Kart verisi kontrolü (komut kodları cihaza göre değişebilir)
        if (cmd == 0x80 || cmd == 0x45) {
          List<int> cardData = packet.sublist(5);

          if (_shouldProcessCard(cardData)) {
            _lastReadCard = cardData;
            _lastReadTime = DateTime.now();

            String cardId = _bytesToHex(cardData);
            final message = "OSDP Kart ID: $cardId";
            print(message);
            onDataReceived(message);
          }
        }
      }
    } catch (e) {
      print('OSDP paket işleme hatası: $e');
    }
  }

  bool _shouldProcessCard(List<int> cardData) {
    if (_lastReadCard == null || !_listEquals(_lastReadCard!, cardData)) {
      return true;
    }

    if (_lastReadTime != null &&
        DateTime.now().difference(_lastReadTime!).inSeconds >= 1) {
      return true;
    }

    return false;
  }

  void disconnect() {
    _isConnected = false;
    try {
      _reader?.close();
      if (_port != null) {
        if (_port!.isOpen) _port!.close();
        _port!.dispose();
      }
    } catch (e) {
      print('OSDP bağlantı kapatma hatası: $e');
    } finally {
      _buffer = [];
      _lastReadCard = null;
      _lastReadTime = null;
      _reader = null;
      _port = null;
    }
  }

  bool isConnected() => _isConnected;

  // Yardımcı metodlar
  void _printPortDetails() {
    print('\n=== OSDP Port Detayları ===');
    print('Port: ${_port?.name}');
    print('Baud Rate: ${_port?.config.baudRate}');
    print('Data Bits: ${_port?.config.bits}');
    print('Stop Bits: ${_port?.config.stopBits}');
    print('Parity: ${_port?.config.parity}');
    print('=========================\n');
  }

  String _bytesToHex(List<int> bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  bool _listEquals(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}