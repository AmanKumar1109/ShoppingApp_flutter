import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final String image;
  final String unit;

  OrderItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.image = '',
    this.unit = '',
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id']?.toString() ?? '',
      name: map['name'] ?? map['title'] ?? 'Product',
      quantity: (map['qty'] ?? map['quantity'] as num?)?.toInt() ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] ?? map['imageUrl'] ?? '',
      unit: map['unit']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'qty': quantity,
      'quantity': quantity,
      'price': price,
      'image': image,
      'unit': unit,
    };
  }
}

class OrderModel {
  final String id;
  final String orderId;
  final String userId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String address;
  final String deliveryAddress;
  final Map<String, dynamic>? deliveryAddressObject;
  final double lat;
  final double lng;
  final List<OrderItemModel> items;
  final double totalAmount;
  final double subTotal;
  final double deliveryFee;
  final double discountAmount;
  final String? couponApplied;
  final String status; // 'Order Received', 'Out for Delivery', 'Delivered', 'Cancelled', 'Pending Payment'
  final bool isCurrent;
  final String paymentMethod; // 'Cash on Delivery', 'Online Payment (SubPaisa)'
  final String paymentStatus; // 'Pending (COD)', 'Paid (SubPaisa)', 'Pending (Online)'
  final String sabpaisaTxnId;
  final Map<String, dynamic>? paymentResponse;
  final String orderTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deliveryOtp; // 6-digit verification OTP
  final bool deliveryOtpVerified;
  final bool riderOtpVerified;
  final bool adminOtpVerified;
  final int otpFailedAttempts;
  final bool isNextMorningDelivery;
  final String deliverySlot;
  final String? assignedPartnerId;
  final String? assignedPartnerName;
  final String? assignedPartnerPhone;
  final Map<String, dynamic>? riderLocation;

  double? get riderLat => (riderLocation?['lat'] as num?)?.toDouble();
  double? get riderLng => (riderLocation?['lng'] as num?)?.toDouble();
  double? get riderSpeed => (riderLocation?['speed'] as num?)?.toDouble();
  double? get riderHeading => (riderLocation?['heading'] as num?)?.toDouble();

  OrderModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone = '',
    required this.address,
    required this.deliveryAddress,
    this.deliveryAddressObject,
    this.lat = 22.2811,
    this.lng = 86.7110,
    required this.items,
    required this.totalAmount,
    required this.subTotal,
    this.deliveryFee = 0.0,
    this.discountAmount = 0.0,
    this.couponApplied,
    this.status = 'Order Received',
    this.isCurrent = true,
    this.paymentMethod = 'Cash on Delivery',
    this.paymentStatus = 'Pending (COD)',
    this.sabpaisaTxnId = '',
    this.paymentResponse,
    required this.orderTime,
    required this.createdAt,
    required this.updatedAt,
    required this.deliveryOtp,
    this.deliveryOtpVerified = false,
    this.riderOtpVerified = false,
    this.adminOtpVerified = false,
    this.otpFailedAttempts = 0,
    this.isNextMorningDelivery = false,
    this.deliverySlot = 'Standard (As soon as possible)',
    this.assignedPartnerId,
    this.assignedPartnerName,
    this.assignedPartnerPhone,
    this.riderLocation,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawItems = map['items'];
    List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((item) => OrderItemModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    return OrderModel(
      id: docId,
      orderId: map['orderId'] ?? map['id'] ?? docId,
      userId: map['userId'] ?? '',
      customerName: map['customerName'] ?? 'Customer',
      customerEmail: map['customerEmail'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      address: map['address'] ?? map['deliveryAddress'] ?? '',
      deliveryAddress: map['deliveryAddress'] ?? map['address'] ?? '',
      deliveryAddressObject: map['deliveryAddressObject'] != null
          ? Map<String, dynamic>.from(map['deliveryAddressObject'])
          : null,
      lat: (map['lat'] as num?)?.toDouble() ?? 22.2811,
      lng: (map['lng'] as num?)?.toDouble() ?? 86.7110,
      items: parsedItems,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      subTotal: (map['subTotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      couponApplied: map['couponApplied'],
      status: map['status'] ?? 'Order Received',
      isCurrent: map['isCurrent'] ?? true,
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      paymentStatus: map['paymentStatus'] ?? 'Pending (COD)',
      sabpaisaTxnId: map['sabpaisaTxnId'] ?? '',
      paymentResponse: map['paymentResponse'] != null
          ? Map<String, dynamic>.from(map['paymentResponse'])
          : null,
      orderTime: map['orderTime'] ?? '',
      createdAt: parseTime(map['createdAt']),
      updatedAt: parseTime(map['updatedAt']),
      deliveryOtp: map['deliveryOtp']?.toString() ?? '123456',
      deliveryOtpVerified: map['deliveryOtpVerified'] ?? false,
      riderOtpVerified: map['riderOtpVerified'] ?? false,
      adminOtpVerified: map['adminOtpVerified'] ?? false,
      otpFailedAttempts: (map['otpFailedAttempts'] as num?)?.toInt() ?? 0,
      isNextMorningDelivery: map['isNextMorningDelivery'] ?? false,
      deliverySlot: map['deliverySlot'] ?? 'Standard (As soon as possible)',
      assignedPartnerId: map['assignedPartnerId'],
      assignedPartnerName: map['assignedPartnerName'],
      assignedPartnerPhone: map['assignedPartnerPhone'],
      riderLocation: map['riderLocation'] != null
          ? Map<String, dynamic>.from(map['riderLocation'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'address': address,
      'deliveryAddress': deliveryAddress,
      'deliveryAddressObject': deliveryAddressObject,
      'lat': lat,
      'lng': lng,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'subTotal': subTotal,
      'deliveryFee': deliveryFee,
      'discountAmount': discountAmount,
      'couponApplied': couponApplied,
      'status': status,
      'isCurrent': isCurrent,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'sabpaisaTxnId': sabpaisaTxnId,
      'paymentResponse': paymentResponse,
      'orderTime': orderTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deliveryOtp': deliveryOtp,
      'deliveryOtpVerified': deliveryOtpVerified,
      'riderOtpVerified': riderOtpVerified,
      'adminOtpVerified': adminOtpVerified,
      'otpFailedAttempts': otpFailedAttempts,
      'isNextMorningDelivery': isNextMorningDelivery,
      'deliverySlot': deliverySlot,
      'assignedPartnerId': assignedPartnerId,
      'assignedPartnerName': assignedPartnerName,
      'assignedPartnerPhone': assignedPartnerPhone,
      'riderLocation': riderLocation,
    };
  }
}
