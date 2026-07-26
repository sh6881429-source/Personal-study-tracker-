import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/chat_message_model.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/client_action_model.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/providers/supabase_edge_ai_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/repositories/chat_history_repository_impl.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/context_builder_service.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/prompt_builder_service.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/smart_request_router.dart';
import 'package:prep_tracker/features/ask_yash_bot/domain/providers/ai_provider.dart';

class YashBotState {
  final List<ChatSessionModel> sessions;
  final ChatSessionModel? activeSession;
  final bool isLoading;
  final String searchQuery;
  final String? attachedPdfName;
  final String? attachedPdfText;
  final ClientActionModel? lastClientAction;

  YashBotState({
    this.sessions = const [],
    this.activeSession,
    this.isLoading = false,
    this.searchQuery = '',
    this.attachedPdfName,
    this.attachedPdfText,
    this.lastClientAction,
  });

  YashBotState copyWith({
    List<ChatSessionModel>? sessions,
    ChatSessionModel? activeSession,
    bool? isLoading,
    String? searchQuery,
    String? attachedPdfName,
    String? attachedPdfText,
    bool clearPdf = false,
    ClientActionModel? lastClientAction,
    bool clearAction = false,
  }) {
    return YashBotState(
      sessions: sessions ?? this.sessions,
      activeSession: activeSession ?? this.activeSession,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      attachedPdfName: clearPdf ? null : (attachedPdfName ?? this.attachedPdfName),
      attachedPdfText: clearPdf ? null : (attachedPdfText ?? this.attachedPdfText),
      lastClientAction: clearAction ? null : (lastClientAction ?? this.lastClientAction),
    );
  }

  List<ChatSessionModel> get filteredSessions {
    if (searchQuery.trim().isEmpty) return sessions;
    final q = searchQuery.toLowerCase();
    return sessions.where((s) => s.title.toLowerCase().contains(q)).toList();
  }

  List<ChatSessionModel> get pinnedSessions =>
      filteredSessions.where((s) => s.isPinned).toList();

  List<ChatSessionModel> get recentSessions =>
      filteredSessions.where((s) => !s.isPinned).toList();
}

class YashBotNotifier extends StateNotifier<YashBotState> {
  YashBotNotifier(this.ref, this._aiProvider) : super(YashBotState()) {
    initHistory();
  }

  final Ref ref;
  final AIProvider _aiProvider;

  Future<void> initHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final sessions = await ChatHistoryRepositoryImpl.loadSessions();
      if (sessions.isNotEmpty) {
        state = state.copyWith(
          sessions: sessions,
          activeSession: sessions.first,
          isLoading: false,
        );
      } else {
        createNewSession();
      }
    } catch (_) {
      createNewSession();
    }
  }

  void createNewSession({String? initialTitle}) {
    final newSession = ChatSessionModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'local',
      title: initialTitle ?? 'New Study Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
    );

    final updated = [newSession, ...state.sessions];
    state = state.copyWith(
      sessions: updated,
      activeSession: newSession,
      isLoading: false,
      clearPdf: true,
      clearAction: true,
    );
    ChatHistoryRepositoryImpl.saveSession(newSession);
  }

  void selectSession(ChatSessionModel session) {
    state = state.copyWith(activeSession: session, clearPdf: true, clearAction: true);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void attachPdf({required String name, required String textContent}) {
    state = state.copyWith(
      attachedPdfName: name,
      attachedPdfText: textContent,
    );
  }

  void clearAttachedPdf() {
    state = state.copyWith(clearPdf: true);
  }

  void clearLastClientAction() {
    state = state.copyWith(clearAction: true);
  }

  Future<void> sendMessage(String text, {String? customTitle}) async {
    if (text.trim().isEmpty) return;

    var active = state.activeSession;
    if (active == null) {
      createNewSession(initialTitle: customTitle ?? (text.length > 25 ? '${text.substring(0, 25)}...' : text));
      active = state.activeSession!;
    }

    final hasPdf = state.attachedPdfText != null && state.attachedPdfText!.isNotEmpty;

    final userMsg = ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: text.trim(),
      timestamp: DateTime.now(),
      pdfName: state.attachedPdfName,
      pdfTextSnippet: state.attachedPdfText,
    );

    final updatedMessages = [...active.messages, userMsg];
    final title = customTitle ?? ((active.messages.isEmpty && active.title == 'New Study Chat')
        ? (text.length > 25 ? '${text.substring(0, 25)}...' : text)
        : active.title);

    final updatedSession = active.copyWith(
      title: title,
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      activeSession: updatedSession,
      isLoading: true,
      clearPdf: true,
      clearAction: true,
    );

    await ChatHistoryRepositoryImpl.saveSession(updatedSession);

    // ── 1. Smart Request Router Evaluation (Client Actions / DB / Identity / AI / PDF) ──
    final userContext = await ContextBuilderService.buildContext(ref);
    final routeResult = SmartRequestRouter.routeQuery(
      query: text,
      context: userContext,
      hasAttachedPdf: hasPdf,
    );

    final clientAction = routeResult['clientAction'] as ClientActionModel?;
    if (clientAction != null) {
      state = state.copyWith(lastClientAction: clientAction);
    }

    if (routeResult['answer'] != null) {
      final dbAnswer = routeResult['answer'] as String;
      final botMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: MessageRole.assistant,
        content: dbAnswer,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedSession.messages, botMsg];
      final finalSession = updatedSession.copyWith(messages: finalMessages, updatedAt: DateTime.now());

      final sessionList = [...state.sessions];
      final sIdx = sessionList.indexWhere((s) => s.id == finalSession.id);
      if (sIdx >= 0) {
        sessionList[sIdx] = finalSession;
      } else {
        sessionList.insert(0, finalSession);
      }

      state = state.copyWith(
        sessions: sessionList,
        activeSession: finalSession,
        isLoading: false,
      );

      await ChatHistoryRepositoryImpl.saveSession(finalSession);
      return;
    }

    // ── 2. AI Question -> Direct AI Provider Call ──
    try {
      final fullPrompt = PromptBuilderService.buildUserPrompt(
        userQuery: text.trim(),
        context: userContext,
        pdfName: userMsg.pdfName,
        pdfTextContent: userMsg.pdfTextSnippet,
      );

      final responseText = await _aiProvider.generateContent(fullPrompt);

      final botMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: MessageRole.assistant,
        content: responseText,
        timestamp: DateTime.now(),
      );

      final finalMessages = [...updatedSession.messages, botMsg];
      final finalSession = updatedSession.copyWith(
        messages: finalMessages,
        updatedAt: DateTime.now(),
      );

      final sessionList = [...state.sessions];
      final sIdx = sessionList.indexWhere((s) => s.id == finalSession.id);
      if (sIdx >= 0) {
        sessionList[sIdx] = finalSession;
      } else {
        sessionList.insert(0, finalSession);
      }

      state = state.copyWith(
        sessions: sessionList,
        activeSession: finalSession,
        isLoading: false,
      );

      await ChatHistoryRepositoryImpl.saveSession(finalSession);
    } catch (e) {
      final errorMsg = ChatMessageModel(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        role: MessageRole.assistant,
        content: 'Failed to process request via AI Provider: $e',
        timestamp: DateTime.now(),
        isError: true,
      );

      final errMessages = [...updatedSession.messages, errorMsg];
      final errSession = updatedSession.copyWith(messages: errMessages);

      state = state.copyWith(
        activeSession: errSession,
        isLoading: false,
      );
    }
  }

  Future<void> renameSession(String sessionId, String newTitle) async {
    await ChatHistoryRepositoryImpl.renameSession(sessionId, newTitle);
    await initHistory();
  }

  Future<void> togglePinSession(String sessionId) async {
    await ChatHistoryRepositoryImpl.togglePinSession(sessionId);
    await initHistory();
  }

  Future<void> deleteSession(String sessionId) async {
    await ChatHistoryRepositoryImpl.deleteSession(sessionId);
    await initHistory();
  }
}

final yashBotProvider =
    StateNotifierProvider<YashBotNotifier, YashBotState>((ref) {
  final provider = SupabaseEdgeAIProvider();
  return YashBotNotifier(ref, provider);
});
