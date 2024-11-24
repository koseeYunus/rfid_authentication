// lib/models/card_data.dart
class CardData {
  final List<int> serialNumbers;
  final bool isAuthorized;
  final String message;
  final CardState state;

  CardData({
    required this.serialNumbers,
    required this.isAuthorized,
    required this.message,
    required this.state,
  });

  factory CardData.fromSerialData(String data) {
    if (data.startsWith("Kart ID:")) {
      try {
        final numbers = data
            .replaceAll("Kart ID:", "")
            .trim()
            .split(" ")
            .map(int.parse)
            .toList();

        if (numbers.length == 5) {
          return CardData(
            serialNumbers: numbers,
            isAuthorized: false, // Bu durumu daha sonra kontrol edilebilir
            message: "Kart Okundu: ${numbers.join(' ')}",
            state: CardState.reading,
          );
        }
      } catch (e) {
        print('Kart ID parse hatası: $e');
      }
    }

    // Geçersiz veri durumu
    return CardData(
      serialNumbers: [],
      isAuthorized: false,
      message: "Geçersiz veri formatı",
      state: CardState.error,
    );
  }
}

enum CardState {
  reading,
  authorized,
  unauthorized,
  error,
}