import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/core/theme/theme_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/providers/yash_bot_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/chat_message_bubble.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/pdf_selector_modal.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/suggested_questions_widget.dart';
import 'package:prep_tracker/shared/widgets/app_drawer.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class AskYashBotScreen extends ConsumerStatefulWidget {
  const AskYashBotScreen({super.key});

  @override
  ConsumerState<AskYashBotScreen> createState() => _AskYashBotScreenState();
}

class _AskYashBotScreenState extends ConsumerState<AskYashBotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.text;

    final botState = ref.watch(yashBotProvider);
    final botNotifier = ref.read(yashBotProvider.notifier);

    final activeSession = botState.activeSession;
    final messages = activeSession?.messages ?? [];
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF3F4F6),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Header Banner (Matching Reference Image) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: const Border(bottom: BorderSide(color: Colors.black, width: 3.5)),
              ),
              child: Row(
                children: [
                  // Hamburger Drawer Button (Mobile/Tablet)
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.black, size: 24),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),

                  // Robot Avatar Badge
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 3),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
                    ),
                    child: Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.smart_toy_rounded, size: 26, color: Colors.black),
                      ),
                    ),
                  ),

                  // Title & Speech Bubble
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'YASH ',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF5B5FEF),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'BOT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : Colors.black,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('✨', style: TextStyle(fontSize: 16)),
                          ],
                        ),

                        // Speech Bubble Box
                        if (screenWidth > 600)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi, I\'m Yash Bot 👋',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Text(
                                  'Your personal AI study assistant. Ask me anything!',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right Action Controls
                  Row(
                    children: [
                      // New Chat Button
                      GestureDetector(
                        onTap: () {
                          botNotifier.createNewSession();
                          AppSnackbar.showInfo(context, 'Started new chat session.');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(
                                'NEW CHAT',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Theme Toggle
                      GestureDetector(
                        onTap: () => ref.read(themeModeProvider.notifier).toggleTheme(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFFFFD60A) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
                          ),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            size: 18,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Main Body (3-Column Layout) ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Column 1: RECENT CHATS Sidebar (Desktop/Tablet) ──
                    if (screenWidth > 900)
                      Container(
                        width: 240,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 3.5),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                        ),
                        child: _buildRecentChatsPanel(context, botState, botNotifier, isDark, textColor),
                      ),

                    // ── Column 2: Center Main Chat Column ──
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black, width: 3.5),
                          boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                        ),
                        child: Column(
                          children: [
                            // Messages List Area
                            Expanded(
                              child: messages.isEmpty
                                  ? _buildWelcomeState(context, isDark, textColor, botNotifier)
                                  : ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.all(16),
                                      itemCount: messages.length,
                                      itemBuilder: (context, index) {
                                        return ChatMessageBubble(
                                          message: messages[index],
                                          onRegenerate: () {
                                            if (messages.isNotEmpty) {
                                              botNotifier.sendMessage(messages.last.content);
                                            }
                                          },
                                        );
                                      },
                                    ),
                            ),

                            // Loading Indicator
                            if (botState.isLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    Text('Yash Bot is thinking...', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              ),

                            // 4 Recommended Chips
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: SuggestedQuestionsWidget(
                                onQuestionSelected: (q) {
                                  _messageController.text = q;
                                  botNotifier.sendMessage(q);
                                  _messageController.clear();
                                  _scrollToBottom();
                                },
                              ),
                            ),

                            // PDF Attachment Tag if present
                            if (botState.attachedPdfName != null)
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5D73).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFFF5D73), width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFFF5D73)),
                                    const SizedBox(width: 6),
                                    Text('Attached PDF: ${botState.attachedPdfName}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => botNotifier.clearAttachedPdf(),
                                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),

                            // Input Box Area
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                border: const Border(top: BorderSide(color: Colors.black, width: 2.5)),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Row(
                                children: [
                                  // Attach PDF Button
                                  IconButton(
                                    icon: const Icon(Icons.attach_file_rounded, color: Color(0xFFFF5D73)),
                                    tooltip: 'Attach PDF Document',
                                    onPressed: () {
                                      showDialog<void>(
                                        context: context,
                                        builder: (ctx) => PdfSelectorModal(
                                          onPdfSelected: (name, snippet) {
                                            botNotifier.attachPdf(name: name, textContent: snippet);
                                            AppSnackbar.showSuccess(context, 'Attached $name to conversation');
                                          },
                                        ),
                                      );
                                    },
                                  ),

                                  // Text Input
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: TextField(
                                        controller: _messageController,
                                        style: GoogleFonts.inter(fontSize: 12, color: textColor),
                                        decoration: InputDecoration(
                                          hintText: 'Type your message...',
                                          hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                          border: InputBorder.none,
                                        ),
                                        onSubmitted: (val) {
                                          if (val.trim().isNotEmpty) {
                                            botNotifier.sendMessage(val.trim());
                                            _messageController.clear();
                                            _scrollToBottom();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Send Button
                                  GestureDetector(
                                    onTap: () {
                                      final val = _messageController.text.trim();
                                      if (val.isNotEmpty) {
                                        botNotifier.sendMessage(val);
                                        _messageController.clear();
                                        _scrollToBottom();
                                      }
                                    },
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF5B5FEF),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black, width: 2.5),
                                        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
                                      ),
                                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Column 3: "YASH BOT CAN HELP YOU" & Motivation Panel (Desktop Only) ──
                    if (screenWidth > 1150)
                      Container(
                        width: 250,
                        margin: const EdgeInsets.only(left: 12),
                        child: Column(
                          children: [
                            // "YASH BOT CAN HELP YOU" Card
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.black, width: 3.5),
                                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF5B5FEF),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                      border: Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
                                    ),
                                    child: Text(
                                      'YASH BOT CAN HELP YOU',
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        _helpItem('📖', 'Study Guidance', 'Syllabus, topics, strategy', isDark, textColor),
                                        _helpItem('⏱️', 'Time Management', 'Timetable, productivity tips', isDark, textColor),
                                        _helpItem('⚡', 'Motivation Boost', 'Quotes, mindset, focus', isDark, textColor),
                                        _helpItem('🏋️', 'Health & Fitness', 'Workout, diet, habits', isDark, textColor),
                                        _helpItem('❓', 'General Questions', 'Any academic help', isDark, textColor),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Motivation Quote Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.black, width: 3.5),
                                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('“', style: GoogleFonts.poppins(fontSize: 36, height: 0.8, fontWeight: FontWeight.w900, color: Colors.black)),
                                        const SizedBox(height: 8),
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: 'DISCIPLINE TODAY\n',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: isDark ? Colors.white : Colors.black,
                                                  decoration: TextDecoration.underline,
                                                  decorationColor: const Color(0xFF5B5FEF),
                                                  decorationThickness: 3,
                                                ),
                                              ),
                                              TextSpan(
                                                text: 'SUCCESS TOMORROW',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w900,
                                                  color: isDark ? Colors.white : Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text('- Yash', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54)),
                                      ],
                                    ),
                                    const Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Icon(Icons.bolt_rounded, size: 36, color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpItem(String emoji, String title, String subtitle, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 9.5, color: isDark ? Colors.white60 : Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentChatsPanel(BuildContext context, YashBotState botState, YashBotNotifier botNotifier, bool isDark, Color textColor) {
    return Column(
      children: [
        // Header Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF5B5FEF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            border: Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT CHATS',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              GestureDetector(
                onTap: () => botNotifier.createNewSession(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1.5),
                  ),
                  child: const Icon(Icons.add_rounded, size: 14, color: Colors.black),
                ),
              ),
            ],
          ),
        ),

        // Search Input
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => botNotifier.setSearchQuery(val),
            style: GoogleFonts.inter(fontSize: 11, color: textColor),
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: const Icon(Icons.search_rounded, size: 16),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.black, width: 1.5)),
            ),
          ),
        ),

        // Chat Session List
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: botState.filteredSessions.map((s) {
              final isSel = botState.activeSession?.id == s.id;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isSel ? (isDark ? const Color(0xFF334155) : const Color(0xFFFFFDF0)) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? Colors.black : Colors.black26, width: isSel ? 2 : 1),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  leading: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Colors.black),
                  title: Text(
                    s.title,
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: InkWell(
                    onTap: () => botNotifier.deleteSession(s.id),
                    child: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.grey),
                  ),
                  onTap: () => botNotifier.selectSession(s),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeState(BuildContext context, bool isDark, Color textColor, YashBotNotifier botNotifier) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD60A),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(3.5, 3.5))],
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 36, color: Colors.black),
            ),
            const SizedBox(height: 14),
            Text(
              'Welcome to Yash Bot! 🤖',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900, color: textColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Your official AI study coach developed by Yash Shukla.\nAsk questions about your study hours, consistency score, or PDF notes.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
