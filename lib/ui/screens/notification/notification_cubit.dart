import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_item.dart';

class NotificationCubit extends Cubit<List<NotificationItem>> {
  NotificationCubit() : super(const []) {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        emit(const []);
      } else {
        loadNotifications();
      }
    });
  }

  StreamSubscription<User?>? _authSubscription;

  String? get _storageKey {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return 'notifications_${user.uid}';
  }

  int get unreadCount => state.where((item) => !item.isRead).length;

  Future<void> loadNotifications() async {
    final key = _storageKey;
    if (key == null) {
      emit(const []);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);

      if (stored == null) {
        emit(const []);
        return;
      }

      final decoded = jsonDecode(stored) as List<dynamic>;
      final items = decoded
          .map(
            (item) => NotificationItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(items);
    } catch (_) {
      emit(const []);
    }
  }

  Future<void> _persist(List<NotificationItem> items) async {
    final key = _storageKey;
    if (key == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> addNotification({
    required String title,
    required String message,
  }) async {
    if (_storageKey == null) return;

    final item = NotificationItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      createdAt: DateTime.now(),
    );

    final updated = [item, ...state];
    emit(updated);
    await _persist(updated);
  }

  Future<void> markAsRead(String id) async {
    final updated = state
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();

    emit(updated);
    await _persist(updated);
  }

  Future<void> markAllAsRead() async {
    final updated = state.map((item) => item.copyWith(isRead: true)).toList();

    emit(updated);
    await _persist(updated);
  }

  Future<void> deleteNotification(String id) async {
    final updated = state.where((item) => item.id != id).toList();

    emit(updated);
    await _persist(updated);
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
