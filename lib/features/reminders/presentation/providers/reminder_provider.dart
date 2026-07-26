import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prep_tracker/core/services/notification_service.dart';
import 'package:prep_tracker/features/auth/presentation/providers/auth_provider.dart';
import 'package:prep_tracker/features/reminders/data/models/reminder_model.dart';
import 'package:prep_tracker/features/reminders/data/services/reminder_service.dart';
import 'package:prep_tracker/features/reminders/domain/models/reminder_type.dart';

/// Provider for ReminderService
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// State class for Reminders
class ReminderState {
  const ReminderState({
    this.reminders = const [],
    this.isLoading = false,
    this.selectedFilter,
    this.errorMessage,
  });

  final List<ReminderModel> reminders;
  final bool isLoading;
  final ReminderType? selectedFilter;
  final String? errorMessage;

  List<ReminderModel> get filteredReminders {
    if (selectedFilter == null) return reminders;
    return reminders.where((r) => r.type == selectedFilter).toList();
  }

  int get activeCount => reminders.where((r) => r.isEnabled).length;

  ReminderState copyWith({
    List<ReminderModel>? reminders,
    bool? isLoading,
    ReminderType? selectedFilter,
    bool clearFilter = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ReminderState(
      reminders: reminders ?? this.reminders,
      isLoading: isLoading ?? this.isLoading,
      selectedFilter: clearFilter ? null : (selectedFilter ?? this.selectedFilter),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// ── Reminder Notifier ──
class ReminderNotifier extends StateNotifier<ReminderState> {
  ReminderNotifier(this._service, this._ref) : super(const ReminderState()) {
    loadReminders();
  }

  final ReminderService _service;
  final Ref _ref;

  String get _userId {
    final authState = _ref.read(authProvider);
    return authState.profile?.userId ?? authState.supabaseUser?.id ?? '';
  }

  /// Loads all reminders for current user
  Future<void> loadReminders() async {
    final userId = _userId;
    if (userId.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _service.fetchReminders(userId);
      state = state.copyWith(reminders: list, isLoading: false);
      NotificationService.syncScheduledReminders(list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sets category filter
  void setFilter(ReminderType? type) {
    if (state.selectedFilter == type) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(selectedFilter: type);
    }
  }

  /// Creates a new reminder
  Future<void> addReminder({
    required String title,
    required String message,
    required ReminderType type,
    required String targetRoute,
    required DateTime scheduledAt,
    bool isRecurring = false,
    String? recurrencePattern,
  }) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final now = DateTime.now();
    final newReminder = ReminderModel(
      id: '',
      userId: userId,
      title: title,
      message: message,
      type: type,
      targetRoute: targetRoute,
      scheduledAt: scheduledAt,
      isEnabled: true,
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      createdAt: now,
      updatedAt: now,
    );

    try {
      final saved = await _service.createReminder(newReminder);
      final updatedList = [...state.reminders, saved];
      state = state.copyWith(reminders: updatedList);
      NotificationService.syncScheduledReminders(updatedList);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to create reminder: $e');
      rethrow;
    }
  }

  /// Updates an existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    try {
      final updated = await _service.updateReminder(reminder);
      final updatedList = state.reminders.map((r) => r.id == updated.id ? updated : r).toList();
      state = state.copyWith(reminders: updatedList);
      NotificationService.syncScheduledReminders(updatedList);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update reminder: $e');
      rethrow;
    }
  }

  /// Toggles `isEnabled` status for a reminder
  Future<void> toggleReminder(String id, bool isEnabled) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final updatedList = state.reminders.map((r) {
      if (r.id == id) {
        return r.copyWith(isEnabled: isEnabled, updatedAt: DateTime.now());
      }
      return r;
    }).toList();

    state = state.copyWith(reminders: updatedList);
    NotificationService.syncScheduledReminders(updatedList);

    try {
      await _service.toggleReminder(id, userId, isEnabled);
    } catch (e) {
      // Rollback on failure
      unawaited(loadReminders());
    }
  }

  /// Deletes a reminder
  Future<void> deleteReminder(String id) async {
    final userId = _userId;
    if (userId.isEmpty) return;

    final updatedList = state.reminders.where((r) => r.id != id).toList();
    state = state.copyWith(reminders: updatedList);
    NotificationService.syncScheduledReminders(updatedList);

    try {
      await _service.deleteReminder(id, userId);
    } catch (e) {
      unawaited(loadReminders());
      rethrow;
    }
  }
}

/// Provider for ReminderNotifier
final reminderProvider = StateNotifierProvider<ReminderNotifier, ReminderState>((ref) {
  final service = ref.watch(reminderServiceProvider);
  return ReminderNotifier(service, ref);
});
