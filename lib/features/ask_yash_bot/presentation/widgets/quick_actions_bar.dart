import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({
    super.key,
    required this.onActionTap,
  });

  final void Function(String prompt, String title) onActionTap;

  static const List<Map<String, String>> actions = [
    {
      'label': '📅 Create Today\'s Study Plan',
      'title': 'Today\'s Study Plan',
      'prompt': 'Create a structured study plan for today based on my pending subjects and goals.',
    },
    {
      'label': '📊 Analyze My Progress',
      'title': 'Overall Progress Analysis',
      'prompt': 'Analyze my study hours, streak, and gym attendance to recommend improvements.',
    },
    {
      'label': '📖 Summarize My PDF',
      'title': 'PDF Summary Request',
      'prompt': 'Please summarize the key topics, definitions, and important points from my attached PDF document.',
    },
    {
      'label': '🎯 Improve Consistency Score',
      'title': 'Consistency Score Strategy',
      'prompt': 'Explain how I can increase my Consistency Score toward 900 based on my recent habits.',
    },
    {
      'label': '🔄 Generate Revision Plan',
      'title': 'Revision Schedule',
      'prompt': 'Generate a spaced-repetition revision plan for my completed chapters this week.',
    },
    {
      'label': '💪 Analyze Gym Progress',
      'title': 'Gym Consistency Analysis',
      'prompt': 'Analyze my gym attendance consistency and suggest optimal workout rest balance.',
    },
    {
      'label': '📝 Create Revision Notes',
      'title': 'Study Notes Generation',
      'prompt': 'Create concise bulleted revision notes for my weakest subject.',
    },
    {
      'label': '❓ Generate Quiz',
      'title': 'Practice Quiz',
      'prompt': 'Generate 5 multiple choice practice questions for self-testing.',
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
        children: actions.map((act) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onActionTap(act['prompt']!, act['title']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(1.5, 1.5))],
                ),
                child: Text(
                  act['label']!,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
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
