import 'package:prep_tracker/features/ask_yash_bot/data/models/yash_bot_context_model.dart';

class PromptBuilderService {
  static const String baseSystemInstruction = '''
You are Yash Bot, the official AI assistant of PrepTracker By Yash.

Maintain this identity throughout the conversation.
Only introduce yourself when the user explicitly asks about your identity or who you are.
For all other requests, answer the user's question directly without repeating your introduction.

GUIDELINES:
- Answer academic, scientific, coding, math, general knowledge, and productivity questions thoroughly with rich explanations.
- Use the user's PrepTracker context (study hours, streak, goals, consistency score) when relevant to provide personalized guidance.
- Format responses using clean GitHub-style Markdown (headings, bullet points, bold text).
- Be direct, friendly, concise, and helpful.
''';

  static const String pdfSystemInstruction = '''
STRICT SOURCE-BASED PDF RULES:
- When a PDF document is attached, generate summaries, key topics, MCQs, or answers strictly from the actual extracted text provided in the prompt.
- NEVER fabricate summaries, use hardcoded templates, or invent placeholder concepts.
- If readable text could not be extracted from the PDF, inform the user clearly:
  "I couldn't extract readable text from this PDF. It may be image-based, encrypted, or corrupted. Please upload a searchable PDF or enable OCR."
''';

  static String buildUserPrompt({
    required String userQuery,
    required YashBotContextModel context,
    String? pdfName,
    String? pdfTextContent,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(baseSystemInstruction);

    final hasPdf = pdfName != null && pdfTextContent != null && pdfTextContent.isNotEmpty;
    if (hasPdf) {
      buffer.writeln(pdfSystemInstruction);
    }

    buffer.writeln();
    buffer.writeln(context.toFormattedPromptContext());

    if (hasPdf) {
      buffer.writeln('\n[ATTACHED PDF DOCUMENT: $pdfName]');
      if (pdfTextContent.startsWith('[ERROR:')) {
        buffer.writeln('EXTRACTION STATUS: $pdfTextContent');
        buffer.writeln(
            'INSTRUCTION: Inform the user clearly that readable text could not be extracted from this PDF (it may be image-based, encrypted, or corrupted) and ask them to upload a searchable PDF or enable OCR. Do NOT fabricate any summary or content.\n');
      } else {
        buffer.writeln('EXTRACTED PDF DOCUMENT TEXT CONTENT:');
        buffer.writeln(pdfTextContent.length > 8000
            ? pdfTextContent.substring(0, 8000)
            : pdfTextContent);
        buffer.writeln('[END OF ATTACHED PDF DOCUMENT CONTENT]\n');
        buffer.writeln('INSTRUCTIONS FOR PDF RESPONSE:');
        buffer.writeln('- Summarize key topics, definitions, formulas, and conclusions strictly derived from the above extracted text.');
        buffer.writeln('- Do NOT use placeholder templates, dummy summaries, or generic advice.');
      }
    }

    buffer.writeln('\nUSER QUESTION:');
    buffer.writeln(userQuery);

    return buffer.toString();
  }
}
