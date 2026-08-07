// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<bool> requestPlatformPermission() async {
  try {
    final permission = await html.Notification.requestPermission();
    return permission == 'granted';
  } catch (e) {
    debugPrint('Failed to request web notification permission: $e');
    return false;
  }
}

bool get isPlatformPermissionGranted {
  try {
    return html.Notification.permission == 'granted';
  } catch (_) {
    return false;
  }
}

void showPlatformNotification({
  required String title,
  required String body,
}) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body, icon: '/favicon.png');
    }
  } catch (e) {
    debugPrint('Failed to show HTML5 notification: $e');
  }
}