import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/notification_model.dart';

class NotificationStorageService {
  static final NotificationStorageService _instance = NotificationStorageService._internal();
  factory NotificationStorageService() => _instance;
  NotificationStorageService._internal();

  static const String _notificationsKey = 'app_notifications';
  static const int _maxNotifications = 100; // Keep last 100 notifications

  /// Save a new notification
  Future<void> saveNotification(NotificationModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notifications = await getNotifications();
      
      // Add new notification at the beginning
      notifications.insert(0, notification);
      
      // Keep only the most recent notifications
      if (notifications.length > _maxNotifications) {
        notifications.removeRange(_maxNotifications, notifications.length);
      }
      
      // Convert to JSON and save
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
      print('✅ Notification saved: ${notification.title}');
    } catch (e) {
      print('❌ Error saving notification: $e');
    }
  }

  /// Get all notifications
  Future<List<NotificationModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_notificationsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error loading notifications: $e');
      return [];
    }
  }

  /// Get unread notifications
  Future<List<NotificationModel>> getUnreadNotifications() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).toList();
  }

  /// Get unread count
  Future<int> getUnreadCount() async {
    final unread = await getUnreadNotifications();
    return unread.length;
  }

  /// Mark notification as read
  Future<void> markAsRead(String id) async {
    try {
      final notifications = await getNotifications();
      final index = notifications.indexWhere((n) => n.id == id);
      
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        
        // Save updated list
        final prefs = await SharedPreferences.getInstance();
        final jsonList = notifications.map((n) => n.toJson()).toList();
        await prefs.setString(_notificationsKey, jsonEncode(jsonList));
        
        print('✅ Notification marked as read: $id');
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notifications = await getNotifications();
      final updatedNotifications = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      
      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      final jsonList = updatedNotifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String id) async {
    try {
      final notifications = await getNotifications();
      notifications.removeWhere((n) => n.id == id);
      
      // Save updated list
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setString(_notificationsKey, jsonEncode(jsonList));
      
      print('✅ Notification deleted: $id');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      print('✅ All notifications cleared');
    } catch (e) {
      print('❌ Error clearing notifications: $e');
    }
  }

  /// Get notifications by type
  Future<List<NotificationModel>> getNotificationsByType(String type) async {
    final notifications = await getNotifications();
    return notifications.where((n) => n.type.toLowerCase() == type.toLowerCase()).toList();
  }
}
