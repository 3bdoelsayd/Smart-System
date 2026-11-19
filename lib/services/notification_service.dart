import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> init() async {
    // Disabled permission requests and notification reminders completely
    return;
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Disabled notification scheduling
    return;
  }

  static Future<void> cancelAllNotifications() async {
    return;
  }
}
