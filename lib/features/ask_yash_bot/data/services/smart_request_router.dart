import 'package:flutter/foundation.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/client_action_model.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/yash_bot_context_model.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/services/intent_detector_service.dart';

enum QueryCategory {
  clientAction,
  dbOnly,
  identityKnowledge,
  pdfWorkflow,
  aiReasoning,
}

class SmartRequestRouter {
  /// Evaluates user query and returns routing decision, category, client action, or answer.
  static Map<String, dynamic> routeQuery({
    required String query,
    required YashBotContextModel context,
    bool hasAttachedPdf = false,
  }) {
    final startTime = DateTime.now();
    final q = query.trim().toLowerCase();
    final intent = IntentDetectorService.detectIntent(query, hasAttachedPdf: hasAttachedPdf);

    Map<String, dynamic> result;

    // ── 1. Client Actions Routing ──
    if (intent == BotIntent.clientAction) {
      ClientActionModel? clientAction;

      if (q.contains('analytics')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openAnalytics,
          target: '/analytics',
          confirmationMessage: 'Opening Analytics Dashboard...',
        );
      } else if (q.contains('gym')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openGymTracker,
          target: '/gym',
          confirmationMessage: 'Opening Gym Tracker...',
        );
      } else if (q.contains('timer')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openStudyTimer,
          target: '/study',
          confirmationMessage: 'Opening Study Timer...',
        );
      } else if (q.contains('profile')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openProfile,
          target: '/profile',
          confirmationMessage: 'Opening Profile...',
        );
      } else if (q.contains('settings')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openSettings,
          target: '/settings',
          confirmationMessage: 'Opening Settings...',
        );
      } else if (q.contains('bookmark')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openBookmarkPage,
          target: '/bookmark',
          confirmationMessage: 'Opening Bookmark Manager...',
        );
      } else if (q.contains('picker') || q.contains('attach pdf') || q.contains('select pdf')) {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.openPdfPicker,
          confirmationMessage: 'Opening PDF Selector...',
        );
      } else {
        clientAction = const ClientActionModel(
          actionType: ClientActionType.navigateToScreen,
          target: '/home',
          confirmationMessage: 'Navigating to Home Dashboard...',
        );
      }

      result = {
        'category': QueryCategory.clientAction,
        'intent': intent,
        'clientAction': clientAction,
        'answer': clientAction.confirmationMessage,
        'aiCalled': false,
      };
    }
    // ── 2. Explicit Identity Routing ──
    else if (intent == BotIntent.identity) {
      result = {
        'category': QueryCategory.identityKnowledge,
        'intent': intent,
        'answer':
            "I'm Yash Bot, the official AI assistant of PrepTracker By Yash. I was developed by Yash Shukla to help you manage your studies, analyze your progress, and provide personalized guidance using your PrepTracker data.",
        'aiCalled': false,
      };
    }
    // ── 3. Database Stat Queries Routing ──
    else if (q == 'how much did i study today?' || q.contains('study today')) {
      result = {
        'category': QueryCategory.dbOnly,
        'intent': BotIntent.studyAnalytics,
        'answer':
            "📊 **Today's Study Summary**:\nYou have studied **${context.todayStudyHours.toStringAsFixed(1)} hours** today. Your daily goal is ${(context.dailyGoalMinutes / 60).toStringAsFixed(1)} hours.",
        'aiCalled': false,
      };
    } else if (q.contains('study streak') || q == 'what is my study streak?') {
      result = {
        'category': QueryCategory.dbOnly,
        'intent': BotIntent.studyAnalytics,
        'answer':
            "🔥 **Study Streak**: You are on a **${context.currentStudyStreak} Day Study Streak**! Keep up the great work!",
        'aiCalled': false,
      };
    } else if (q.contains('gym streak') || q.contains('gym attendance')) {
      result = {
        'category': QueryCategory.dbOnly,
        'intent': BotIntent.gymAnalytics,
        'answer':
            "💪 **Gym Status**: ${context.gymPresentDays} Present Days, ${context.gymAbsentDays} Rest Days. Attendance Rate: **${context.gymAttendancePercentage.toStringAsFixed(0)}%** (Streak: ${context.currentGymStreak} Days).",
        'aiCalled': false,
      };
    }
    // ── 4. PDF Workflow Routing ──
    else if (intent == BotIntent.pdfQuestion ||
        intent == BotIntent.pdfSummary ||
        intent == BotIntent.pdfMcqs ||
        intent == BotIntent.pdfNotes) {
      result = {
        'category': QueryCategory.pdfWorkflow,
        'intent': intent,
        'answer': hasAttachedPdf
            ? null
            : 'No PDF document is currently attached to this conversation. Please tap the 📎 button to select a PDF from your library.',
        'aiCalled': hasAttachedPdf,
      };
    }
    // ── 5. General Knowledge & AI Questions Routing (Newton\'s law, photosynthesis, coding, general chat) ──
    else {
      result = {
        'category': QueryCategory.aiReasoning,
        'intent': intent,
        'answer': null,
        'aiCalled': true,
      };
    }

    // ── Diagnostic Logging (Fix 7) ──
    final durationMs = DateTime.now().difference(startTime).inMilliseconds;
    if (kDebugMode) {
      debugPrint('''
[YashBot Diagnostics]
  • Question: "$query"
  • Detected Intent: ${result['intent']}
  • Route Selected: ${result['category']}
  • Context Loaded: Yes (Streak: ${context.currentStudyStreak}, Study: ${context.todayStudyHours}h)
  • AI Provider Called: ${result['aiCalled']}
  • Execution Time: ${durationMs}ms
''');
    }

    return result;
  }
}
