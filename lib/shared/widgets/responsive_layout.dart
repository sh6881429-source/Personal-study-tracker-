import 'package:flutter/material.dart';
import 'package:prep_tracker/core/constants/app_spacing.dart';

/// ── Responsive Layout Builder ──
/// Adapts UI for mobile, tablet, and desktop breakpoints.
///
/// ```dart
/// ResponsiveLayout(
///   mobile: (context) => MobileView(),
///   tablet: (context) => TabletView(),
///   desktop: (context) => DesktopView(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Required — always provided.
  final Widget Function(BuildContext context) mobile;

  /// Falls back to [mobile] if not provided.
  final Widget Function(BuildContext context)? tablet;

  /// Falls back to [tablet] → [mobile] if not provided.
  final Widget Function(BuildContext context)? desktop;

  // ── Breakpoints ──
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;

  /// Returns true if the screen width is in the mobile range.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  /// Returns true if the screen width is in the tablet range.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Returns true if the screen width is in the desktop range.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return (desktop ?? tablet ?? mobile)(context);
        }
        if (constraints.maxWidth >= mobileBreakpoint) {
          return (tablet ?? mobile)(context);
        }
        return mobile(context);
      },
    );
  }
}

/// ── Responsive Padding ──
/// Applies different horizontal padding based on screen width.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double padding;
    if (ResponsiveLayout.isDesktop(context)) {
      padding = AppSpacing.xxl;
    } else if (ResponsiveLayout.isTablet(context)) {
      padding = AppSpacing.xl;
    } else {
      padding = AppSpacing.md;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
  }
}
