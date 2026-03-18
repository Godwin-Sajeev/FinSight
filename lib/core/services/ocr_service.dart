import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();

  static Future<Map<String, dynamic>?> scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return null;

    final InputImage inputImage = InputImage.fromFilePath(image.path);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

    return _parseReceipt(recognizedText.text);
  }

  static Map<String, dynamic> _parseReceipt(String text) {
    // Basic regex-based parsing for demo
    // In a real app, this would be more complex or use a specialized LLM
    double amount = 0.0;
    String merchant = "Unknown Merchant";

    final lines = text.split('\n');
    
    // Simple heuristic: look for numbers that look like currency
    final amountRegex = RegExp(r'(\d+[\.,]\d{2})');
    for (var line in lines) {
      final matches = amountRegex.allMatches(line);
      for (var match in matches) {
        final val = double.tryParse(match.group(0)!.replaceAll(',', ''));
        if (val != null && val > amount) {
          amount = val; // Often the largest number is the total
        }
      }
    }

    if (lines.isNotEmpty) {
      merchant = lines.first; // Usually merchant name is at the top
    }

    return {
      'amount': amount,
      'merchant': merchant,
      'rawText': text,
    };
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
