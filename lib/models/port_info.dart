class PortInfo {

  final String name;          // Port adı
  final String description;   // Port açıklaması
  final String manufacturer;  // Üretici bilgisi
  final String productName;   // Ürün adı
  final String serialNumber;  // Seri numarası
  final int vendorId;
  final int productId;
  final bool hasDriver;      // Sürücü durumu
  final String portType;     // Port tipi (USB, COM, vb.)
  final String subsystem;    // Alt sistem bilgisi
  final String macAddress;   // MAC adresi (varsa)
  final int baudRate;        // Mevcut baud rate
  final bool isOpen;         // Port açık mı?
  final Map<String, String> additionalInfo; // Ek bilgiler

  PortInfo({
    required this.name,
    this.description = '',
    this.manufacturer = '',
    this.productName = '',
    this.serialNumber = '',
    this.vendorId = 0,
    this.productId = 0,
    this.hasDriver = false,
    this.portType = '',
    this.subsystem = '',
    this.macAddress = '',
    this.baudRate = 0,
    this.isOpen = false,
    this.additionalInfo = const {},
  });

  // Port detay metni oluşturma
  String getDetailedInfo() {
    final details = <String>[];

    if (description.isNotEmpty) details.add('Açıklama: $description');
    if (manufacturer.isNotEmpty) details.add('Üretici: $manufacturer');
    if (productName.isNotEmpty) details.add('Ürün: $productName');
    if (serialNumber.isNotEmpty) details.add('Seri No: $serialNumber');
    if (portType.isNotEmpty) details.add('Port Tipi: $portType');
    if (subsystem.isNotEmpty) details.add('Alt Sistem: $subsystem');
    if (macAddress.isNotEmpty) details.add('MAC: $macAddress');
    if (baudRate > 0) details.add('Baud Rate: $baudRate');
    details.add('VID: 0x${vendorId.toRadixString(16).padLeft(4, '0').toUpperCase()}');
    details.add('PID: 0x${productId.toRadixString(16).padLeft(4, '0').toUpperCase()}');
    details.add('Sürücü: ${hasDriver ? 'Yüklü' : 'Yüklü Değil'}');
    details.add('Durum: ${isOpen ? 'Açık' : 'Kapalı'}');

    // Ek bilgileri ekle
    additionalInfo.forEach((key, value) {
      if (value.isNotEmpty) details.add('$key: $value');
    });

    return details.join('\n');
  }

  @override
  String toString() {
    String displayText = name;
    if (productName.isNotEmpty) {
      displayText += ' - $productName';
      if (manufacturer.isNotEmpty) {
        displayText += ' ($manufacturer)';
      }
    }
    return displayText;
  }
}
