class PortInfo {
  /// Port adı
  final String name;

  /// Port açıklaması
  final String description;

  /// Üretici bilgisi
  final String manufacturer;

  /// Ürün adı
  final String productName;

  /// Seri numarası
  final String serialNumber;

  /// Vendor ID
  final String vendorId;

  /// Product ID
  final String productId;

  /// Constructor
  PortInfo({
    required this.name,
    this.description = '',
    this.manufacturer = '',
    this.productName = '',
    this.serialNumber = '',
    this.vendorId = '',
    this.productId = '0',
  });

  /// Port bilgisini string olarak formatlar
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
