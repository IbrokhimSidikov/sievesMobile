import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final DateTime? readAt;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.readAt,
    this.data,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'data': data,
    };
  }

  // Create from local storage JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  // Create from backend API response (t_mobile_notifications table)
  factory NotificationModel.fromApiJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final Map<String, dynamic>? dataMap = rawData is Map<String, dynamic>
        ? rawData
        : null;

    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'general',
      timestamp: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : DateTime.parse(json['created_at'] as String),
      isRead: (json['is_read'] as num?)?.toInt() == 1,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      data: dataMap,
    );
  }

  // Copy with method for updating
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    DateTime? readAt,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
    );
  }

  // Get icon based on type
  IconData get icon {
    final t = type.toLowerCase();
    if (t == 'task_comment') return Icons.mode_comment_rounded;
    if (t == 'task_status_changed') return Icons.published_with_changes_rounded;
    if (t.startsWith('task_')) return Icons.task_alt_rounded;
    if (t.startsWith('exam')) return Icons.quiz_rounded;
    switch (t) {
      case 'contract_activated':
        return Icons.workspace_premium_rounded;
      case 'training_reminder':
        return Icons.school_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      case 'attendance':
        return Icons.login_rounded;
      case 'break':
        return Icons.free_breakfast_rounded;
      case 'payroll':
        return Icons.payments_rounded;
      case 'system':
        return Icons.auto_awesome_rounded;
      case 'alert':
        return Icons.warning_rounded;
      case 'message':
        return Icons.message_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  // Get color based on type
  Color get colorFrom {
    final t = type.toLowerCase();
    if (t.startsWith('task_')) return const Color(0xFF14B8A6); // Teal
    if (t.startsWith('exam')) return const Color(0xFF7C3AED); // Violet
    switch (t) {
      case 'contract_activated':
        return const Color(0xFFF59E0B); // Amber (celebratory)
      case 'training_reminder':
        return const Color(0xFF0071E3); // Blue
      case 'announcement':
        return const Color(0xFF43C19F); // Brand teal
      case 'attendance':
        return const Color(0xFF34C759); // Green
      case 'break':
        return const Color(0xFFFF9500); // Orange
      case 'payroll':
        return const Color(0xFFFFD60A); // Yellow
      case 'system':
        return const Color(0xFF0071E3); // Blue
      case 'alert':
        return const Color(0xFFFF3B30); // Red
      case 'message':
        return const Color(0xFFAF52DE); // Purple
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }

  Color get colorTo {
    final t = type.toLowerCase();
    if (t.startsWith('task_')) return const Color(0xFF0EA5A4);
    if (t.startsWith('exam')) return const Color(0xFF6D28D9); // Violet (darker)
    switch (t) {
      case 'contract_activated':
        return const Color(0xFFD97706); // Amber (darker)
      case 'training_reminder':
        return const Color(0xFF007AFF); // Blue
      case 'announcement':
        return const Color(0xFF2E9B7E); // Brand teal (darker)
      case 'attendance':
        return const Color(0xFF43C19F);
      case 'break':
        return const Color(0xFFFEDA84);
      case 'payroll':
        return const Color(0xFFFEC700);
      case 'system':
        return const Color(0xFF007AFF);
      case 'alert':
        return const Color(0xFFFF8B92);
      case 'message':
        return const Color(0xFFFFBCFA);
      default:
        return const Color(0xFF4F46E5);
    }
  }

  // Get relative time string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
