import 'package:prep_tracker/features/ask_yash_bot/data/models/ai_chat_model.dart';

/// ── AI Chat History Repository Contract ──
abstract interface class AiChatRepository {
  /// Fetch recent chat history matching [userId], capped to a reasonable count.
  Future<List<AiChatModel>> getChatHistory(String userId, {int limit = 20});

  /// Log a new chat message pair (question/answer) in history database.
  Future<AiChatModel> logChatMessage(String userId, String question, String response);

  /// Delete older chat logs to maintain size constraints.
  Future<void> pruneOldChats(String userId, {int keepLimit = 20});
}
