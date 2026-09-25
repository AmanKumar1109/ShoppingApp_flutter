import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {
  final String id;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String orderId;
  final String category;
  final String message;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final String adminRemark;
  final DateTime createdAt;

  ComplaintModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone = '',
    required this.orderId,
    required this.category,
    required this.message,
    this.status = 'Pending',
    this.adminRemark = '',
    required this.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parsedDate = DateTime.now();
    final rawCreated = map['createdAt'];
    if (rawCreated is Timestamp) {
      parsedDate = rawCreated.toDate();
    } else if (rawCreated is String) {
      parsedDate = DateTime.tryParse(rawCreated) ?? DateTime.now();
    }

    return ComplaintModel(
      id: id,
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      orderId: map['orderId'] ?? '',
      category: map['category'] ?? 'General Issue',
      message: map['message'] ?? '',
      status: map['status'] ?? 'Pending',
      adminRemark: map['adminRemark'] ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'orderId': orderId,
      'category': category,
      'message': message,
      'status': status,
      'adminRemark': adminRemark,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
