enum BotIntent {
  identity,
  generalKnowledge,
  studyQuestion,
  studyAnalytics,
  studyPlanning,
  revisionPlanning,
  gymAnalytics,
  pdfQuestion,
  pdfSummary,
  pdfMcqs,
  pdfNotes,
  clientAction,
  appHelp,
  conversation,
}

class IntentDetectorService {
  /// Detects user query intent dynamically.
  static BotIntent detectIntent(String query, {bool hasAttachedPdf = false}) {
    final q = query.trim().toLowerCase();

    // ── 1. Explicit Identity Intent ──
    if (q == 'who are you?' ||
        q == 'who are you' ||
        q.contains('what is your name') ||
        q.contains('who made you') ||
        q.contains('who developed you') ||
        q.contains('are you gemini') ||
        q.contains('are you chatgpt') ||
        q.contains('which ai model') ||
        q.contains('who created yash bot') ||
        q.contains('tell me about yourself')) {
      return BotIntent.identity;
    }

    // ── 2. Client Action Intent ──
    if (q.contains('open analytics') ||
        q.contains('show analytics') ||
        q.contains('view analytics') ||
        q.contains('open gym') ||
        q.contains('show gym') ||
        q.contains('open timer') ||
        q.contains('start timer') ||
        q.contains('open profile') ||
        q.contains('open settings') ||
        q.contains('open pdf picker') ||
        q.contains('attach pdf') ||
        q.contains('select pdf') ||
        q.contains('open bookmarks') ||
        q.contains('open syllabus') ||
        q.contains('show subjects')) {
      return BotIntent.clientAction;
    }

    // ── 3. PDF Specific Intents (ONLY when PDF is mentioned or attached) ──
    if (q.contains('pdf') || q.contains('uploaded document') || q.contains('attached document') || hasAttachedPdf) {
      if (q.contains('mcq') || q.contains('quiz')) {
        return BotIntent.pdfMcqs;
      }
      if (q.contains('notes') || q.contains('flashcard')) {
        return BotIntent.pdfNotes;
      }
      if (q.contains('summarize') || q.contains('summary')) {
        return BotIntent.pdfSummary;
      }
      return BotIntent.pdfQuestion;
    }

    // ── 4. Study Analytics Intent (DB Query) ──
    if (q.contains('how much did i study') ||
        q.contains('today study') ||
        q.contains('my study hours') ||
        q.contains('weekly progress') ||
        q.contains('subject analytics') ||
        q.contains('study streak')) {
      return BotIntent.studyAnalytics;
    }

    // ── 5. Gym Analytics Intent (DB Query) ──
    if (q.contains('gym streak') ||
        q.contains('gym attendance') ||
        q.contains('gym stats') ||
        q.contains('workout count')) {
      return BotIntent.gymAnalytics;
    }

    // ── 6. Study Planning Intent ──
    if (q.contains('timetable') ||
        q.contains('study plan') ||
        q.contains('schedule') ||
        q.contains('routine')) {
      return BotIntent.studyPlanning;
    }

    // ── 7. Revision Planning Intent ──
    if (q.contains('how to revise') ||
        q.contains('revision plan') ||
        q.contains('active recall strategy') ||
        q.contains('revision session')) {
      return BotIntent.revisionPlanning;
    }

    // ── 8. Casual Conversation ──
    if (q == 'hi' ||
        q == 'hello' ||
        q == 'hey' ||
        q.contains('good morning') ||
        q.contains('good evening') ||
        q.contains('thank you') ||
        q.contains('thanks')) {
      return BotIntent.conversation;
    }

    // ── 9. App Help Intent ──
    if (q.contains('help me use app') || q.contains('app guide') || q == 'help') {
      return BotIntent.appHelp;
    }

    // ── 10. General Knowledge / AI Question (Default for all academic, science, general queries) ──
    return BotIntent.generalKnowledge;
  }
}
