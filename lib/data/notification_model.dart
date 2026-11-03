import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledTime;
  String status; // 'pending', 'unread', 'read'
  final String? type; // 'goal_morning', 'goal_warning', 'goal_appreciate', 'plan_alert'

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.status = 'pending',
    this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.toIso8601String(),
        'status': status,
        'type': type,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        scheduledTime: DateTime.parse(json['scheduledTime'] as String),
        status: json['status'] as String? ?? 'pending',
        type: json['type'] as String?,
      );

  static const String _storageKey = 'local_saved_notifications_v2';

  static Future<List<AppNotification>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => AppNotification.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveAll(List<AppNotification> list) async {
    final prefs = await SharedPreferences.getInstance();
    // Keep max 100 items (FIFO)
    if (list.length > 100) {
      list = list.sublist(0, 100);
    }
    await prefs.setString(_storageKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<void> upsert(AppNotification item) async {
    final list = await loadAll();
    final idx = list.indexWhere((e) => e.id == item.id);
    if (idx != -1) {
      list[idx] = item;
    } else {
      list.insert(0, item);
    }
    await saveAll(list);
  }

  static Future<void> remove(String id) async {
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }
}