import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const String _enabledKey = 'phone_notifications_enabled';

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    // Hide/cancel local phone notifications when the user turns them off.
    // This does not delete the in-app notification history in NotificationCubit.
    if (!enabled) {
      await _plugin.cancelAll();
    }
  }

  Future<void> showTransactionNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!await areNotificationsEnabled()) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'expense_tracker_transactions',
        'Transaction Updates',
        channelDescription: 'Income and expense notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}