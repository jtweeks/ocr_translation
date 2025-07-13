import 'package:flutter/foundation.dart'; // For @required if using older Flutter/Dart versions

class TranslationModel {
  final String originalText;
  final String translatedText;
  final String languageCode; // e.g., "en", "es", "fr" (ISO 639-1 code)
  final DateTime dateAndTime;

  TranslationModel({
    required this.originalText,
    required this.translatedText,
    required this.languageCode,
    required this.dateAndTime,
  });

  // Example static method to get a list of sample translations
  // In a real application, this data would likely come from a database,
  // API, or local storage.
  static List<TranslationModel> getTranslations() {
    return [
      TranslationModel(
        originalText: "Hello",
        translatedText: "Hola",
        languageCode: "es", // Spanish
        dateAndTime: DateTime.now().subtract(const Duration(days: 1)),
      ),
      TranslationModel(
        originalText: "How are you?",
        translatedText: "Comment ça va ?",
        languageCode: "fr", // French
        dateAndTime: DateTime.now().subtract(const Duration(hours: 5)),
      ),
      TranslationModel(
        originalText: "Good morning",
        translatedText: "Guten Morgen",
        languageCode: "de", // German
        dateAndTime: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      TranslationModel(
        originalText: "Thank you",
        translatedText: "ありがとう", // Arigato
        languageCode: "ja", // Japanese
        dateAndTime: DateTime.now(),
      ),
      TranslationModel(
        originalText: "Flutter is amazing",
        translatedText: "Flutter es increíble",
        languageCode: "es", // Spanish
        dateAndTime: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  // Optional: You might want to add methods for JSON serialization/deserialization
  // if you plan to store this data or send it over a network.

  // Example: Convert a TranslationModel instance to a Map (JSON)
  Map<String, dynamic> toJson() {
    return {
      'originalText': originalText,
      'translatedText': translatedText,
      'languageCode': languageCode,
      'dateAndTime': dateAndTime.toIso8601String(), // Store date as ISO 8601 string
    };
  }

  // Example: Create a TranslationModel instance from a Map (JSON)
  factory TranslationModel.fromJson(Map<String, dynamic> json) {
    return TranslationModel(
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      languageCode: json['languageCode'] as String,
      dateAndTime: DateTime.parse(json['dateAndTime'] as String),
    );
  }

  // Optional: Override toString for easier debugging
  @override
  String toString() {
    return 'TranslationModel(originalText: $originalText, translatedText: $translatedText, languageCode: $languageCode, dateAndTime: $dateAndTime)';
  }

  // Optional: Override == and hashCode for value comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TranslationModel &&
        other.originalText == originalText &&
        other.translatedText == translatedText &&
        other.languageCode == languageCode &&
        other.dateAndTime == dateAndTime;
  }

  @override
  int get hashCode {
    return originalText.hashCode ^
    translatedText.hashCode ^
    languageCode.hashCode ^
    dateAndTime.hashCode;
  }
}