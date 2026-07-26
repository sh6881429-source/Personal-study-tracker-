import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:prep_tracker/core/constants/app_colors.dart';
import 'package:prep_tracker/features/ask_yash_bot/data/models/chat_message_model.dart';
import 'package:prep_tracker/shared/widgets/app_snackbar.dart';

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    this.onRegenerate,
  });

  final ChatMessageModel message;
  final VoidCallback? onRegenerate;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  bool? _isHelpful;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = widget.message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Assistant Robot Avatar ──
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 10, top: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(2, 2))],
              ),
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy_rounded, size: 18, color: Colors.black),
                ),
              ),
            ),
          ],

          // ── Bubble Body ──
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF5B5FEF)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isUser ? Colors.black : (isDark ? Colors.white70 : Colors.black),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(3.5, 3.5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.message.pdfName != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black26, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFFF5D73)),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.message.pdfName!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Message Content Text
                  Text(
                    widget.message.content,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: isUser ? Colors.white : (isDark ? Colors.white : AppColors.text),
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottom Bar inside Bubble
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${DateFormat('hh:mm a').format(widget.message.timestamp)}${isUser ? " ✓✓" : ""}',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isUser ? Colors.white70 : (isDark ? Colors.white54 : Colors.grey.shade600),
                        ),
                      ),

                      if (!isUser)
                        Row(
                          children: [
                            // Copy Action
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: widget.message.content));
                                AppSnackbar.showSuccess(context, 'Copied response to clipboard');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.copy_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),

                            // Share Action
                            InkWell(
                              onTap: () => Share.share(widget.message.content),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.share_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),

                            // Helpful / Thumbs Up
                            InkWell(
                              onTap: () {
                                setState(() => _isHelpful = true);
                                AppSnackbar.showSuccess(context, 'Thanks for your feedback!');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  _isHelpful == true ? Icons.thumb_up_alt_rounded : Icons.thumb_up_off_alt_rounded,
                                  size: 14,
                                  color: _isHelpful == true ? const Color(0xFF34D399) : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),

                            // Not Helpful / Thumbs Down
                            InkWell(
                              onTap: () {
                                setState(() => _isHelpful = false);
                                AppSnackbar.showInfo(context, 'Thanks for your feedback!');
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  _isHelpful == false ? Icons.thumb_down_alt_rounded : Icons.thumb_down_off_alt_rounded,
                                  size: 14,
                                  color: _isHelpful == false ? const Color(0xFFFF5D73) : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── User Avatar ──
          if (isUser) ...[
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(left: 10, top: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFBAE6FD),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2.5),
                boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(2, 2))],
              ),
              child: const Icon(Icons.person_rounded, size: 20, color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }
}
