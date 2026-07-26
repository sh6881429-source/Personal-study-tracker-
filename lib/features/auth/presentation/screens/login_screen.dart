import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/shared/widgets/app_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// ── Login Screen (Responsive Dual Neo-Brutalist Layout) ──
/// Mobile: Renders the clean Modern Neo-Brutalist Productivity Portal with social buttons.
/// Desktop/Tablet: Renders the exact 1:1 Reference Layout stretched to the screen edges with large centered content.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isButtonHovered = false;
  bool _isButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    // Listen for authentication errors
    ref.listen<AppAuthState>(authProvider, (previous, next) {
      if (next.errorMessage != null) {
        AppDialog.showError(
          context,
          title: 'Authentication Failed',
          message: next.errorMessage!,
        ).then((_) {
          ref.read(authProvider.notifier).clearError();
        });
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return _buildMobilePortalLayout(context, authState, isDark, screenWidth);
    }

    return _buildDesktopReferenceLayout(context, authState, isDark);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. DESKTOP & TABLET LAYOUT (Stretched to Screen Edges & Large Centered Content)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildDesktopReferenceLayout(
    BuildContext context,
    AppAuthState authState,
    bool isDark,
  ) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // Occupy extreme horizontal edges of screen/window
    final double cardWidth = screenWidth - 16;
    final double cardHeight = screenHeight - 16;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFEBECEF),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(8),
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF6F6F6),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black, width: 4.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black,
                  offset: Offset(8, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                children: [
                  // ── Top-Left Stepped Yellow Accent Corner (Pinned at absolute extreme) ──
                  Positioned(
                    top: 0,
                    left: 0,
                    child: CustomPaint(
                      size: const Size(280, 155),
                      painter: _SteppedTopLeftPainter(),
                    ),
                  ),

                  // Overlay text for Top-Left corner precisely to prevent overflow
                  Positioned(
                    top: 14,
                    left: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 28,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'PREPTRACKER',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              'BY YASH',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Bottom-Right Stepped Purple Accent Corner (Pinned at absolute extreme) ──
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(200, 155),
                      painter: _SteppedBottomRightPainter(),
                    ),
                  ),

                  // ── Top-Right Dot Matrix Grid ──
                  Positioned(
                    top: 24,
                    right: 32,
                    child: _buildDotGrid(rows: 3, cols: 7),
                  ),

                  // ── Right Edge Diagonal Slashes ──
                  Positioned(
                    top: cardHeight * 0.22,
                    right: 24,
                    child: Column(
                      children: List.generate(
                        8,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.5),
                          child: Transform.rotate(
                            angle: -0.5,
                            child: Container(
                              width: 16,
                              height: 2.5,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Left Edge Crosses Stack ──
                  Positioned(
                    bottom: cardHeight * 0.22,
                    left: 24,
                    child: Column(
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          child: Text(
                            '✕',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Bottom-Left Dot Matrix Grid ──
                  Positioned(
                    bottom: 24,
                    left: 32,
                    child: _buildDotGrid(rows: 3, cols: 8),
                  ),

                  // ── Split Row: Left = Login Content, Right = Features Panel ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── LEFT: Main Login Content ──
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                        // Hero Logo Badge (Yellow Box with Ray & Accent Details)
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            // Top Rays (\ | /)
                            Positioned(
                              top: -26,
                              child: Row(
                                children: [
                                  Transform.rotate(
                                    angle: -0.4,
                                    child: Container(width: 3.0, height: 18, color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 3.0, height: 20, color: Colors.black),
                                  const SizedBox(width: 8),
                                  Transform.rotate(
                                    angle: 0.4,
                                    child: Container(width: 3.0, height: 18, color: Colors.black),
                                  ),
                                ],
                              ),
                            ),

                            // Left Dot Triangle Accent
                            Positioned(
                              left: -44,
                              child: Column(
                                children: [
                                  Row(children: [_dot(), const SizedBox(width: 3), _dot()]),
                                  const SizedBox(height: 3),
                                  Row(children: [_dot(), const SizedBox(width: 3), _dot(), const SizedBox(width: 3), _dot()]),
                                  const SizedBox(height: 3),
                                  Row(children: [_dot(), const SizedBox(width: 3), _dot()]),
                                ],
                              ),
                            ),

                            // Right ✕ Accent
                            Positioned(
                              right: -40,
                              child: Text(
                                '✕',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),

                            // Hero Yellow Logo Box
                            Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFC800),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black, width: 4.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(7, 7),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 66,
                                    color: Colors.black,
                                  ),
                                  Text(
                                    'PT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      height: 0.9,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Title & Subtitle Section
                        Column(
                          children: [
                            Text(
                              'PREPTRACKER',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                                letterSpacing: 2.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 34, height: 3.5, color: Colors.black),
                                const SizedBox(width: 8),
                                Text(
                                  'BY YASH',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF5B5FEF),
                                    letterSpacing: 3.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(width: 34, height: 3.5, color: Colors.black),
                              ],
                            ),
                          ],
                        ),

                        // Tagline Pill Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 9),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 3.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(4.5, 4.5),
                              ),
                            ],
                          ),
                          child: Text(
                            'TRACK PROGRESS. ACHIEVE GOALS.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),

                        // Google Sign-In Button (Visually Stretched Focal Point)
                        MouseRegion(
                          onEnter: (_) => setState(() => _isButtonHovered = true),
                          onExit: (_) => setState(() => _isButtonHovered = false),
                          child: GestureDetector(
                            onTapDown: (_) => setState(() => _isButtonPressed = true),
                            onTapUp: (_) => setState(() => _isButtonPressed = false),
                            onTapCancel: () => setState(() => _isButtonPressed = false),
                            onTap: authState.isLoading
                                ? null
                                : () => ref.read(authProvider.notifier).loginWithGoogle(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              transform: Matrix4.translationValues(
                                0,
                                _isButtonPressed ? 3.0 : (_isButtonHovered ? -2.0 : 0),
                                0,
                              ),
                              width: (cardWidth * 0.55).clamp(580.0, 720.0),
                              height: 68,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5FEF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black, width: 4.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: _isButtonPressed
                                        ? const Offset(2.5, 2.5)
                                        : (_isButtonHovered ? const Offset(7.5, 7.5) : const Offset(6, 6)),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Left 'G' Badge
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.black, width: 2.5),
                                    ),
                                    child: Center(
                                      child: _buildColoredGoogleIcon(24),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Divider Line
                                  Container(
                                    width: 2.0,
                                    height: 30,
                                    color: Colors.black.withValues(alpha: 0.3),
                                  ),

                                  // Button Text
                                  Expanded(
                                    child: Text(
                                      authState.isLoading
                                          ? 'CONNECTING TO GOOGLE...'
                                          : 'SIGN IN WITH GOOGLE',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),

                                  // Chevron Right
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.black,
                                    size: 34,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Security Disclaimer Card
                        Container(
                          width: 520,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Google sign-in is processed securely via Supabase Auth.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Key Features Strip & Social Buttons REMOVED FROM HERE ──
                        // (Now on the right panel)

                              // Footer Attribution Badge
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    children: [
                                      Container(width: 20, height: 2.5, color: Colors.black),
                                      const SizedBox(height: 3),
                                      Container(width: 20, height: 2.5, color: Colors.black),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5B5FEF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.black, width: 2.5),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black,
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      'DEVELOPED BY YASH SHUKLA',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    children: [
                                      Container(width: 20, height: 2.5, color: Colors.black),
                                      const SizedBox(height: 3),
                                      Container(width: 20, height: 2.5, color: Colors.black),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // ── RIGHT: Social & Features Panel ──
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 2,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── FOLLOW US (comes first) ──
                              Text(
                                'FOLLOW US',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withValues(alpha: 0.4),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Instagram Button — real URL
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse('https://www.instagram.com/i.yassshhhh/');
                                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1306C),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.black, width: 3.0),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'FOLLOW ON INSTA',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // WhatsApp Button — real number
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.parse('https://wa.me/917652002964');
                                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF25D366),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.black, width: 3.0),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black, offset: Offset(4, 4)),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'CONNECT ON WHATSAPP',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── WHAT'S INSIDE (comes second) ──
                              Text(
                                'WHAT\'S INSIDE',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black.withValues(alpha: 0.4),
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Feature pills — stacked vertically
                              _buildDesktopFeaturePill(Icons.bolt_rounded, 'STUDY TRACKER', const Color(0xFF5B5FEF), isDark),
                              const SizedBox(height: 10),
                              _buildDesktopFeaturePill(Icons.fitness_center_rounded, 'GYM LOG', const Color(0xFFFF5D73), isDark),
                              const SizedBox(height: 10),
                              _buildDesktopFeaturePill(Icons.analytics_rounded, 'ANALYTICS', const Color(0xFFFF8C42), isDark),
                              const SizedBox(height: 10),
                              _buildDesktopFeaturePill(Icons.emoji_events_rounded, 'GOAL TRACK', const Color(0xFF34D399), isDark),
                              const SizedBox(height: 10),
                              _buildDesktopFeaturePill(Icons.auto_awesome_rounded, 'AI YASH BOT', const Color(0xFF7C3AED), isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. MOBILE PORTAL LAYOUT (Keep Same As Current Phone Version)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMobilePortalLayout(
    BuildContext context,
    AppAuthState authState,
    bool isDark,
    double screenWidth,
  ) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFF4F5F8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Container(
              width: screenWidth * 0.94,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B22) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 4.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black,
                    offset: Offset(8, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Yellow Banner Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD60A),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 4.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 20, color: Colors.black),
                        const SizedBox(width: 6),
                        Text(
                          'PREPTRACKER PORTAL',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content Body
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        // Logo Square
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD60A),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black, width: 3.8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(5, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 44, color: Colors.black),
                              Text(
                                'PT',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  height: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title
                        Text(
                          'PREPTRACKER',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: 1.8,
                            height: 1.0,
                          ),
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 22, height: 3.5, color: Colors.black),
                            const SizedBox(width: 6),
                            Text(
                              'BY YASH',
                              style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF5B5FEF),
                                  letterSpacing: 2.4),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 22, height: 3.5, color: Colors.black),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Social Action Buttons (Instagram & WhatsApp)
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SocialButton(
                              label: 'FOLLOW INSTA',
                              icon: _buildInstagramIcon(16),
                              backgroundColor: const Color(0xFFE1306C),
                              textColor: Colors.white,
                              fontSize: 9.5,
                              height: 36,
                              onTap: () => _launchURL('https://www.instagram.com/i.yassshhhh/'),
                            ),
                            _SocialButton(
                              label: 'WHATSAPP CHAT',
                              icon: _buildWhatsAppIcon(16),
                              backgroundColor: const Color(0xFF25D366),
                              textColor: Colors.black,
                              fontSize: 9.5,
                              height: 36,
                              onTap: () => _launchURL('https://wa.me/917652002964'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Google Sign-In Button
                        GestureDetector(
                          onTap: authState.isLoading
                              ? null
                              : () => ref.read(authProvider.notifier).loginWithGoogle(),
                          child: Container(
                            width: double.infinity,
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5B5FEF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black, width: 3.8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black,
                                  offset: Offset(4.5, 4.5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.black, width: 2.2),
                                  ),
                                  child: Center(
                                    child: _buildColoredGoogleIcon(20),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 1.8,
                                  height: 24,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                                Expanded(
                                  child: Text(
                                    authState.isLoading ? 'CONNECTING...' : 'SIGN IN WITH GOOGLE',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.black,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Tagline Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF21262D) : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: Colors.black, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'TRACK PROGRESS. ACHIEVE GOALS.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Security Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black, width: 2.2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black,
                                offset: Offset(3, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3.5),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Google sign-in is processed securely via Supabase Auth.',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Footer Badge
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              children: [
                                Container(width: 14, height: 2.5, color: Colors.black),
                                const SizedBox(height: 2.5),
                                Container(width: 14, height: 2.5, color: Colors.black),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5FEF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black, width: 2.0),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black,
                                    offset: Offset(2.5, 2.5),
                                  ),
                                ],
                              ),
                              child: Text(
                                'DEVELOPED BY YASH SHUKLA',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              children: [
                                Container(width: 14, height: 2.5, color: Colors.black),
                                const SizedBox(height: 2.5),
                                Container(width: 14, height: 2.5, color: Colors.black),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Colored Google Icon Builder ──
  Widget _buildColoredGoogleIcon(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Widget _buildInstagramIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.camera_alt_rounded,
          size: size * 0.7,
          color: const Color(0xFFE1306C),
        ),
      ),
    );
  }

  Widget _buildWhatsAppIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.chat_bubble_rounded,
          size: size * 0.65,
          color: const Color(0xFF25D366),
        ),
      ),
    );
  }

  static Widget _dot() {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDotGrid({required int rows, required int cols}) {
    return Column(
      children: List.generate(
        rows,
        (r) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(
              cols,
              (c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: _dot(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a compact feature pill for the desktop Key Features strip.
  Widget _buildDesktopFeaturePill(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(3, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom Painter for Google Colored 'G' Logo ──
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue Segment (#4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final bluePath = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(size.width, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -0.5,
        1.1,
        false,
      )
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green Segment (#34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        0.6,
        1.5,
        false,
      )
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow Segment (#FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final yellowPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        2.1,
        1.1,
        false,
      )
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red Segment (#EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;
    final redPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        3.2,
        1.5,
        false,
      )
      ..close();
    canvas.drawPath(redPath, redPaint);

    // Center Mask Circle
    final maskPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius * 0.52, maskPaint);

    // Horizontal Bar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(center.dx, center.dy - radius * 0.18, size.width, center.dy + radius * 0.18),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Custom Painter for Top-Left Stepped Accent ──
class _SteppedTopLeftPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFFC800)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.32)
      ..lineTo(size.width * 0.74, size.height * 0.32)
      ..lineTo(size.width * 0.74, size.height * 0.62)
      ..lineTo(size.width * 0.36, size.height * 0.62)
      ..lineTo(size.width * 0.36, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Custom Painter for Bottom-Right Stepped Purple Accent ──
class _SteppedBottomRightPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF5B5FEF)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;

    final path = Path()
      ..moveTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width * 0.64, 0)
      ..lineTo(size.width * 0.64, size.height * 0.38)
      ..lineTo(size.width * 0.36, size.height * 0.38)
      ..lineTo(size.width * 0.36, size.height * 0.68)
      ..lineTo(0, size.height * 0.68)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Social Media Action Button Widget ──
class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.height = 42,
    this.fontSize = 11.5,
  });

  final String label;
  final Widget icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 2.8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(3.0, 3.0),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
