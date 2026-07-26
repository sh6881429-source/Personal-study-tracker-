import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuggestedQuestionsWidget extends StatelessWidget {
  const SuggestedQuestionsWidget({
    super.key,
    required this.onQuestionSelected,
  });

  final void Function(String) onQuestionSelected;

  static const List<Map<String, String>> chips = [
    {
      'label': 'Study Motivation 💪',
      'prompt': 'How can I stay motivated and focused during long study sessions?',
    },
    {
      'label': 'Time Management ⏱️',
      'prompt': 'What is the best timetable and time management strategy for my exam prep?',
    },
    {
      'label': 'Exam Tips 📝',
      'prompt': 'What are proven exam revision tips and active recall techniques?',
    },
    {
      'label': 'Healthy Habits 🥗',
      'prompt': 'How can I balance gym, study, diet, and healthy daily habits?',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: chips.map((c) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onQuestionSelected(c['prompt']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                ),
                child: Text(
                  c['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
