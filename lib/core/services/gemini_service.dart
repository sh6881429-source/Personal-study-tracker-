import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:prep_tracker/core/config/env_config.dart';

/// ── Secure Gemini AI Service Engine ──
/// Communicates with Gemini API securely using HTTP REST endpoints.
/// Uses high-capacity free tier models (gemini-flash-latest, gemma-4-31b-it) to answer ANY query.
class GeminiService {
  static const List<String> _modelEndpoints = [
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemma-4-31b-it:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemma-4-26b-a4b-it:generateContent',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
  ];

  static Future<void> init() async {
    // No initialization needed
  }

  static bool get isConfigured {
    final apiKey = EnvConfig.geminiApiKey;
    return apiKey.isNotEmpty && !apiKey.contains('your_gemini_api_key');
  }

  /// Sends a prompt to Gemini REST API and returns the generated content.
  static Future<String> generateContent(String fullPrompt) async {
    final apiKey = EnvConfig.geminiApiKey;

    if (apiKey.isEmpty || apiKey.contains('your_gemini_api_key')) {
      return 'Yash Bot is offline. Please configure a valid Gemini API key in your `.env` file.';
    }

    // Try available model endpoints in order
    for (final baseUrl in _modelEndpoints) {
      try {
        final url = Uri.parse('$baseUrl?key=$apiKey');
        final headers = {'Content-Type': 'application/json'};

        final body = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2000,
          }
        });

        final response = await http.post(url, headers: headers, body: body).timeout(
          const Duration(seconds: 15),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final content = candidates[0]['content'] as Map<String, dynamic>?;
            final parts = content?['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              final text = parts[0]['text'] as String?;
              if (text != null && text.isNotEmpty) {
                return text.trim();
              }
            }
          }
        } else {
          debugPrint('Gemini Endpoint [$baseUrl] status ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini Service Endpoint Exception [$baseUrl]: $e');
      }
    }

    return 'Gemini API Service temporary error or quota limit reached. Please try again in a few moments.';
  }
}
