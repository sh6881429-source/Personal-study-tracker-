import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/features/ask_yash_bot/presentation/providers/overlay_manager_provider.dart';

class FloatingYashBotLauncher extends ConsumerWidget {
  const FloatingYashBotLauncher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overlayState = ref.watch(overlayManagerProvider);
    final notifier = ref.read(overlayManagerProvider.notifier);

    // If fullscreen mode or hidden, launcher is hidden
    if (overlayState.mode == OverlayMode.hidden || overlayState.mode == OverlayMode.fullscreen) {
      return const SizedBox.shrink();
    }

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    final padding = mediaQuery.padding;

    final defaultRightX = screenSize.width - padding.right - 70;
    final defaultBottomY = screenSize.height - padding.bottom - 140;

    final rawX = overlayState.launcherPosition == const Offset(320, 480)
        ? defaultRightX
        : overlayState.launcherPosition.dx;
    final rawY = overlayState.launcherPosition == const Offset(320, 480)
        ? defaultBottomY
        : overlayState.launcherPosition.dy;

    // Clamp position within safe areas
    final posX = rawX.clamp(
      padding.left + 10,
      screenSize.width - padding.right - 66,
    );
    final posY = rawY.clamp(
      padding.top + 10,
      screenSize.height - padding.bottom - 130, // Stay above bottom nav bar!
    );

    return Positioned(
      left: posX,
      top: posY,
      child: GestureDetector(
        onPanUpdate: (details) {
          notifier.updateLauncherPosition(
            Offset(posX + details.delta.dx, posY + details.delta.dy),
          );
        },
        onPanEnd: (_) {
          // ── Magnetic Edge Snapping ──
          final midX = screenSize.width / 2;
          final targetX = posX < midX
              ? padding.left + 10.0
              : screenSize.width - padding.right - 66.0;
          notifier.updateLauncherPosition(Offset(targetX, posY));
        },
        onTap: () {
          notifier.toggleWindow();
        },
        child: Material(
          elevation: 0,
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(3.5, 3.5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    overlayState.mode == OverlayMode.window
                        ? Icons.close_rounded
                        : Icons.smart_toy_rounded,
                    size: 26,
                    color: Colors.black,
                  ),
                ),
              ),
              if (overlayState.hasUnreadSuggestion)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5D73),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
