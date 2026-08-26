import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kuangan/features/auth/auth_provider.dart';
import 'package:kuangan/shared/models/ai_scan_result.dart';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum AiScanStatus { idle, picking, analyzingImage, uploading, success, error }

class AiScanState {
  final AiScanStatus status;
  final AiScanResult? result;
  final String? error;
  final File? image;

  AiScanState({
    required this.status,
    this.result,
    this.error,
    this.image,
  });

  factory AiScanState.idle() => AiScanState(status: AiScanStatus.idle);
}

final aiScanProvider =
    StateNotifierProvider<AiScanNotifier, AiScanState>((ref) {
  ref.watch(authProvider).user?.id;
  return AiScanNotifier();
});

class AiScanNotifier extends StateNotifier<AiScanState> {
  AiScanNotifier() : super(AiScanState.idle());

  void setImage(File file) {
    state = AiScanState(status: AiScanStatus.idle, image: file);
  }

  Future<void> process() async {
    if (state.image == null) return;

    try {
      state = AiScanState(
        status: AiScanStatus.analyzingImage,
        image: state.image,
      );

      final inputImage = InputImage.fromFile(state.image!);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);

      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      await textRecognizer.close();

      final String extractedText = recognizedText.text;

      if (extractedText.trim().isEmpty) {
        throw Exception('Tidak ada teks yang terdeteksi pada gambar struk.');
      }

      state = AiScanState(
        status: AiScanStatus.uploading,
        image: state.image,
      );

      final apiKey =
          dotenv.env['GROQ_API_KEY'] ?? dotenv.env['OPENROUTER_API_KEY'];
      final model = dotenv.env['GROQ_MODEL_FLUTTER'] ??
          dotenv.env['OPENROUTER_MODEL'] ??
          'llama-3.1-8b-instant';
      final baseUrl =
          dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai/v1';

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key tidak ditemukan di .env');
      }

      final dio = Dio();

      final payload = {
        'model': model,
        'max_tokens': 1000,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a receipt parser. Return only valid JSON. No markdown. No explanation.',
          },
          {
            'role': 'user',
            'content': '''Analyze this receipt OCR text.

Return ONLY valid JSON in this exact structure:
{
  "store": "Store name",
  "date": "YYYY-MM-DD",
  "total": 0,
  "suggestedCategory": "Category",
  "items": [
    {
      "name": "item",
      "price": 0,
      "quantity": 1
    }
  ],
  "type": "expense"
}

Rules:
- Return JSON only.
- Do not wrap JSON in markdown.
- The "total" must be the final grand total.
- Ignore cash/tunai, paid amount, change/kembali, subtotal, tax if grand total exists.
- If there are multiple totals, choose the final amount the customer paid.
- If the year is visible, use that year.
- If no year is visible, use the current year.
- Date format must be YYYY-MM-DD.
- Total and item prices must be numbers only.
- suggestedCategory should be one of: Makanan, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan, Pendidikan, Lainnya.
- type must be "expense".
- Store must be the real merchant/store name, not POS, cashier, waiter, order id, or receipt number.
- If items are unclear, return an empty items array.

OCR Text:
$extractedText'''
          }
        ],
      };

      final response = await dio.post(
        '$baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
        data: payload,
      );

      final responseText =
          response.data['choices'][0]['message']['content']?.toString() ?? '';

      String cleanJsonStr = responseText.trim();

      final int firstBrace = cleanJsonStr.indexOf('{');
      final int lastBrace = cleanJsonStr.lastIndexOf('}');

      if (firstBrace == -1 || lastBrace == -1 || lastBrace < firstBrace) {
        throw Exception(
          'AI tidak memberikan format data yang valid. Response: $responseText',
        );
      }

      cleanJsonStr = cleanJsonStr.substring(firstBrace, lastBrace + 1);

      final jsonMap = jsonDecode(cleanJsonStr);
      final result = AiScanResult.fromJson(jsonMap);

      state = AiScanState(
        status: AiScanStatus.success,
        result: result,
        image: state.image,
      );
    } on DioException catch (e) {
      debugPrint(
        'AI SCAN DIO ERROR: ${e.response?.statusCode} - ${e.response?.data}',
      );

      String errorMsg = 'Gagal memproses struk. Terjadi kesalahan jaringan.';

      if (e.response?.statusCode == 401) {
        errorMsg = 'API Key salah atau tidak valid.';
      } else if (e.response?.statusCode == 402) {
        errorMsg = 'Kuota/saldo API tidak cukup.';
      } else if (e.response?.statusCode == 404) {
        errorMsg =
            'Model AI tidak ditemukan. Cek GROQ_MODEL_FLUTTER di file .env.';
      } else if (e.response?.data != null) {
        errorMsg =
            'Upload gagal: ${e.response?.statusCode}. ${e.response?.data}';
      }

      state = AiScanState(
        status: AiScanStatus.error,
        error: errorMsg,
        image: state.image,
      );
    } catch (e) {
      debugPrint('AI SCAN ERROR: $e');

      state = AiScanState(
        status: AiScanStatus.error,
        error: 'Gagal memproses struk: ${e.toString()}',
        image: state.image,
      );
    }
  }

  void reset() {
    state = AiScanState.idle();
  }
}
