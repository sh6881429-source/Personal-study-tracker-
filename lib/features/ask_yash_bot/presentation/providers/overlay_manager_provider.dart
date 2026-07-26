import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum OverlayMode { hidden, mini, window, fullscreen }

class OverlayManagerState {
  final OverlayMode mode;
  final Offset launcherPosition;
  final Size windowSize;
  final bool hasUnreadSuggestion;

  OverlayManagerState({
    this.mode = OverlayMode.mini,
    this.launcherPosition = const Offset(320, 480),
    this.windowSize = const Size(380, 520),
    this.hasUnreadSuggestion = true,
  });

  OverlayManagerState copyWith({
    OverlayMode? mode,
    Offset? launcherPosition,
    Size? windowSize,
    bool? hasUnreadSuggestion,
  }) {
    return OverlayManagerState(
      mode: mode ?? this.mode,
      launcherPosition: launcherPosition ?? this.launcherPosition,
      windowSize: windowSize ?? this.windowSize,
      hasUnreadSuggestion: hasUnreadSuggestion ?? this.hasUnreadSuggestion,
    );
  }
}

class OverlayManagerNotifier extends StateNotifier<OverlayManagerState> {
  OverlayManagerNotifier() : super(OverlayManagerState());

  void setMode(OverlayMode mode) {
    state = state.copyWith(mode: mode, hasUnreadSuggestion: false);
  }

  void toggleWindow() {
    if (state.mode == OverlayMode.window || state.mode == OverlayMode.fullscreen) {
      state = state.copyWith(mode: OverlayMode.mini);
    } else {
      state = state.copyWith(mode: OverlayMode.window, hasUnreadSuggestion: false);
    }
  }

  void updateLauncherPosition(Offset newPos) {
    state = state.copyWith(launcherPosition: newPos);
  }

  void updateWindowSize(Size newSize) {
    state = state.copyWith(windowSize: newSize);
  }

  void triggerSuggestionPulse() {
    state = state.copyWith(hasUnreadSuggestion: true);
  }
}

final overlayManagerProvider =
    StateNotifierProvider<OverlayManagerNotifier, OverlayManagerState>((ref) {
  return OverlayManagerNotifier();
});
