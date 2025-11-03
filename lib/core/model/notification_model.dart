import 'package:flutter/material.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
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
      'data': data,
    };
  }

  // Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String? ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
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
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }

  // Get icon based on type
  IconData get icon {
    switch (type.toLowerCase()) {
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
    switch (type.toLowerCase()) {
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
    switch (type.toLowerCase()) {
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
