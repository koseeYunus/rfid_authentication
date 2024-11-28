class CardData {
  /// Kartın seri numaraları
  final List<int> serialNumbers;

  /// Kartın yetkilendirme durumu
  final bool isAuthorized;

  /// İşlem sonucu mesajı
  final String message;

  /// Kartın mevcut durumu
  final CardState state;

  /// Constructor - kart verilerini alır
  CardData({
    required this.serialNumbers,
    required this.isAuthorized,
    required this.message,
    required this.state,
  });

  /// Seri porttan gelen string veriyi CardData objesine dönüştürür
  factory CardData.fromSerialData(String data) {
    // "Kart ID:" ile başlayan verileri işle
    if (data.startsWith("Kart ID:")) {
      try {
        // Veriyi parse et ve seri numaralarını al
        final numbers = data
            .replaceAll("Kart ID:", "")
            .trim()
            .split(" ")
            .map(int.parse)
            .toList();

        // 5 haneli seri numarası kontrolü
        if (numbers.length == 5) {
          return CardData(
            serialNumbers: numbers,
            isAuthorized: false, // Yetkilendirme durumu daha sonra kontrol edilecek
            message: "Kart Okundu: ${numbers.join(' ')}",
            state: CardState.reading,
          );
        }
      } catch (e) {
        print('Kart ID parse hatası: $e');
      }
    }

    // Geçersiz veri durumunda boş CardData döndür
    return CardData(
      serialNumbers: [],
      isAuthorized: false,
      message: "Geçersiz veri formatı",
      state: CardState.error,
    );
  }
}

/// Kart durumlarını temsil eden enum
enum CardState {
  /// Kart okunuyor
  reading,

  /// Kart yetkili
  authorized,

  /// Kart yetkisiz
  unauthorized,

  /// Hata durumu
  error,
}