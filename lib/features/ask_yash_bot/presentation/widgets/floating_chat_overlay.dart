import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/providers/overlay_manager_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/providers/yash_bot_provider.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/chat_message_bubble.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/pdf_selector_modal.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/widgets/suggested_questions_widget.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class FloatingChatOverlay extends ConsumerStatefulWidget {
  const FloatingChatOverlay({super.key});

  @override
  ConsumerState<FloatingChatOverlay> createState() => _FloatingChatOverlayState();
}

class _FloatingChatOverlayState extends ConsumerState<FloatingChatOverlay> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
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
    final overlayState = ref.watch(overlayManagerProvider);
    final overlayNotifier = ref.read(overlayManagerProvider.notifier);

    final botState = ref.watch(yashBotProvider);
    final botNotifier = ref.read(yashBotProvider.notifier);

    if (overlayState.mode == OverlayMode.hidden || overlayState.mode == OverlayMode.mini) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFullscreen = overlayState.mode == OverlayMode.fullscreen;

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    // Window dimensions
    final width = isFullscreen
        ? screenSize.width
        : (screenSize.width < 500 ? screenSize.width - 24 : overlayState.windowSize.width.clamp(320.0, 600.0));
    final height = isFullscreen
        ? screenSize.height - padding.top
        : (screenSize.height < 600 ? screenSize.height - 120 : overlayState.windowSize.height.clamp(400.0, 700.0));

    final topOffset = isFullscreen ? padding.top : null;
    final bottomOffset = isFullscreen ? 0.0 : (padding.bottom + 72.0);
    final rightOffset = isFullscreen ? 0.0 : (screenSize.width < 500 ? 12.0 : 20.0);

    final activeMessages = botState.activeSession?.messages ?? [];

    return Positioned(
      top: topOffset,
      bottom: isFullscreen ? null : bottomOffset,
      right: rightOffset,
      width: width,
      height: height,
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(isFullscreen ? 0 : 20),
                border: Border.all(color: Colors.black, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    offset: const Offset(5, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Header Drag & Action Bar ──
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(isFullscreen ? 0 : 16),
                      ),
                      border: const Border(bottom: BorderSide(color: Colors.black, width: 2.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 1.5),
                          ),
                          child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                botState.activeSession?.title ?? 'Yash Bot AI Coach',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'PrepTracker Personal AI Assistant',
                                style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),

                        // Restore / Minimize / Exit Controls
                        IconButton(
                          icon: Icon(
                            isFullscreen ? Icons.fullscreen_exit_rounded : Icons.crop_square_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                          tooltip: isFullscreen ? 'Restore Window' : 'Maximize',
                          onPressed: () {
                            overlayNotifier.setMode(
                              isFullscreen ? OverlayMode.window : OverlayMode.fullscreen,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_rounded, size: 20, color: Colors.black),
                          tooltip: 'Minimize to Launcher',
                          onPressed: () => overlayNotifier.setMode(OverlayMode.mini),
                        ),
                      ],
                    ),
                  ),

                  // ── Chat Messages List ──
                  Expanded(
                    child: activeMessages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFD60A),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black, width: 2.5),
                                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2.5, 2.5))],
                                    ),
                                    child: const Icon(Icons.smart_toy_rounded, size: 32, color: Colors.black),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Hi! I\'m Yash Bot 👋',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your personal AI study assistant. Ask me anything!',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            itemCount: activeMessages.length,
                            itemBuilder: (context, index) {
                              return ChatMessageBubble(
                                message: activeMessages[index],
                                onRegenerate: () {
                                  if (activeMessages.isNotEmpty) {
                                    botNotifier.sendMessage(activeMessages.last.content);
                                  }
                                },
                              );
                            },
                          ),
                  ),

                  // ── Loading Indicator ──
                  if (botState.isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yash Bot is thinking...',
                            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                  // ── 4 Recommended Chips Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: SuggestedQuestionsWidget(
                      onQuestionSelected: (q) {
                        _inputController.text = q;
                        botNotifier.sendMessage(q);
                        _inputController.clear();
                        _scrollToBottom();
                      },
                    ),
                  ),

                  // ── PDF Tag if Attached ──
                  if (botState.attachedPdfName != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                          Text(
                            'Attached PDF: ${botState.attachedPdfName}',
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => botNotifier.clearAttachedPdf(),
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.black),
                          ),
                        ],
                      ),
                    ),

                  // ── Input Bar ──
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: const Border(top: BorderSide(color: Colors.black, width: 2.5)),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(isFullscreen ? 0 : 16)),
                    ),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: TextField(
                              controller: _inputController,
                              style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white : Colors.black),
                              decoration: InputDecoration(
                                hintText: 'Type your message...',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (text) {
                                if (text.trim().isNotEmpty) {
                                  botNotifier.sendMessage(text.trim());
                                  _inputController.clear();
                                  _scrollToBottom();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final text = _inputController.text.trim();
                            if (text.isNotEmpty) {
                              botNotifier.sendMessage(text);
                              _inputController.clear();
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

            // ── Floating Exit Fullscreen Button in Fullscreen Mode ──
            if (isFullscreen)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => overlayNotifier.setMode(OverlayMode.window),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black, width: 2),
                      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.fullscreen_exit_rounded, size: 16, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(
                          'Exit Fullscreen',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
