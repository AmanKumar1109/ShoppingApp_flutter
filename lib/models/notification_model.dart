import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? route;
  final String type; // 'order', 'broadcast', 'referral', 'promo', 'deal'
  final String? orderId;
  final String? status;
  final DateTime createdAt;
  final bool isRead;
  final bool isPersonal;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.route,
    this.type = 'general',
    this.orderId,
    this.status,
    required this.createdAt,
    this.isRead = false,
    this.isPersonal = false,
  });

  factory NotificationModel.fromFirestore(
    Map<String, dynamic> data,
    String docId, {
    bool isPersonal = false,
  }) {
    DateTime parsedDate = DateTime.now();
    final rawDate = data['createdAt'] ?? data['sentAt'] ?? data['timestamp'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return NotificationModel(
      id: docId,
      title: (data['title'] ?? 'GroceryHub Alert').toString(),
      body: (data['body'] ?? '').toString(),
      imageUrl: data['imageUrl'] as String?,
      route: data['route'] as String?,
      type: (data['type'] ?? (isPersonal ? 'order' : 'broadcast')).toString(),
      orderId: data['orderId']?.toString(),
      status: data['status'] as String?,
      createdAt: parsedDate,
      isRead: data['isRead'] as bool? ?? false,
      isPersonal: isPersonal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'route': route,
      'type': type,
      'orderId': orderId,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? route,
    String? type,
    String? orderId,
    String? status,
    DateTime? createdAt,
    bool? isRead,
    bool? isPersonal,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      route: route ?? this.route,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isPersonal: isPersonal ?? this.isPersonal,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

