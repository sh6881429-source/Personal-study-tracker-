import 'package:flutter/foundation.dart';
import 'package:prep_tracker/core/services/gemini_service.dart';
import 'package:prep_tracker/core/services/supabase_service.dart';
import 'package:prep_tracker/features/ask_yash_bot/domain/providers/ai_provider.dart';

/// Calls the authenticated server-side AI proxy. If edge function proxy is not reachable,
/// seamlessly falls back to direct Gemini REST API engine (gemini-flash-latest / gemma-4-31b-it).
class SupabaseEdgeAIProvider implements AIProvider {
  @override
  Future<String> generateContent(String promptPayload) async {
    // ── 1. Try Supabase Edge Function Proxy ──
    try {
      final response = await SupabaseService.client.functions.invoke(
        'yash-bot-ai-proxy',
        body: {'prompt': promptPayload},
      );

      final data = response.data;
      if (data is Map) {
        final text = data['response'];
        if (text is String && text.trim().isNotEmpty) {
          return text.trim();
        }
      }
    } catch (e) {
      debugPrint('Yash Bot AI proxy offline/failed, trying direct Gemini API: $e');
    }

    // ── 2. Direct Gemini REST API Execution (gemini-flash-latest / gemma-4-31b-it) ──
    try {
      final res = await GeminiService.generateContent(promptPayload);
      if (!res.contains('Yash Bot is offline') &&
          !res.contains('Service error') &&
          !res.contains('temporary error')) {
        return res;
      }
    } catch (e) {
      debugPrint('Gemini Direct API Exception: $e');
    }

    // ── 3. Offline Fallback Response ──
    return _fallbackLocalResponse(promptPayload);
  }

  @override
  Stream<String> streamContent(String promptPayload) async* {
    final fullText = await generateContent(promptPayload);
    final words = fullText.split(' ');
    String current = '';
    for (final word in words) {
      current += '$word ';
      yield current;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  /// Handles emergency offline cases cleanly without blocking general questions.
  String _fallbackLocalResponse(String prompt) {
    const userQuestionMarker = 'USER QUESTION:';
    final markerIndex = prompt.lastIndexOf(userQuestionMarker);
    final question = markerIndex == -1
        ? prompt
        : prompt.substring(markerIndex + userQuestionMarker.length).trim();
    final q = question.toLowerCase();

    // Attached PDF processing when offline
    if (prompt.contains('[ATTACHED PDF DOCUMENT:')) {
      if (prompt.contains('[ERROR:')) {
        return "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR.";
      }
      return 'I am currently operating in offline mode. Please check your network connection for full PDF document analysis.';
    }

    // Identity questions
    if (q.contains('who are you') ||
        q.contains('what is your name') ||
        q.contains('who made you') ||
        q.contains('who developed you')) {
      return "I'm Yash Bot, the official AI assistant of PrepTracker By Yash. I was developed by Yash Shukla to help you manage your studies, analyze your progress, and provide personalized guidance using your PrepTracker data.";
    }

    // Greetings
    if (q.contains('good morning') ||
        q.contains('good evening') ||
        q == 'hi' ||
        q == 'hello') {
      return 'Hello! I am Yash Bot 👋 How can I help you with your study schedule, subject revision, or exam preparation today?';
    }

    // General query default answer
    return "I'm Yash Bot! To maximize your productivity today, focus on 45-minute study blocks paired with active recall and regular progress tracking.";
  }
}
