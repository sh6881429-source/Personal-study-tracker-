import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _initialized = false;

Future<void> _ensureInitialized() async {
  if (_initialized) return;
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await _plugin.initialize(settings);
  _initialized = true;
}

Future<bool> requestPlatformPermission() async {
  await _ensureInitialized();
  final AndroidFlutterLocalNotificationsPlugin? androidImpl =
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidImpl == null) return true;
  final bool? granted = await androidImpl.requestNotificationsPermission();
  return granted ?? true;
}

bool get isPlatformPermissionGranted => true;

Future<void> showPlatformNotification({
  required String title,
  required String body,
}) async {
  await _ensureInitialized();
  const androidDetails = AndroidNotificationDetails(
    'prep_tracker_channel',
    'PrepTracker Notifications',
    importance: Importance.high,
    priority: Priority.high,
  );
  const details = NotificationDetails(android: androidDetails);
  await _plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
  );
}