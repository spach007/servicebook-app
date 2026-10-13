import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // ОТРИМАЙТЕ БЕЗКОШТОВНИЙ КЛЮЧ НА ai.google.dev
  final String _apiKey = "AIzaSyBKMQS5sXZ7hDSMUVARt9DOmiAmvCqB260"; 

  Future<Map<String, dynamic>?> analyzeReceipt(Uint8List imageBytes) async {
    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
    
    final prompt = '''
    Ти — асистент автосервісу. Проаналізуй це фото чека/акту виконаних робіт з СТО.
    Знайди: 
    1. Назву головної сервісної роботи чи деталі (наприклад: "Заміна мастила" або "Комплект ГРМ").
    2. Загальну вартість (числом).
    Поверни відповідь СТРОГО у форматі JSON без зайвих слів, лапок макдауну чи коментарів:
    {"partName": "назва", "cost": 1500.0}
    ''';

    try {
      final response = await model.generateContent([
        Content.text(prompt),
        Content.data('image/jpeg', imageBytes),
      ]);

      if (response.text != null) {
        // Очищаємо текст від можливих маркдаун-тегів ```json ... ```
        String cleanJson = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
        return json.decode(cleanJson) as Map<String, dynamic>;
      }
    } catch (e) {
      // Log error using logging framework instead of print
      // print("Помилка Gemini AI: $e");
    }
    return null;
  }
}