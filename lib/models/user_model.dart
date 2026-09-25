import 'dart:convert';
import 'dart:math';

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String street;
  final String locality;
  final String city;
  final String state;
  final String pincode;
  final String type;
  final double? lat;
  final double? lng;
  final String location;
  final String addressDetails;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.street,
    required this.locality,
    required this.city,
    required this.state,
    required this.pincode,
    this.type = 'Home',
    this.lat,
    this.lng,
    required this.location,
    required this.addressDetails,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      street: map['street'] ?? '',
      locality: map['locality'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      type: map['type'] ?? 'Home',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      location: map['location'] ?? '',
      addressDetails: map['addressDetails'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'street': street,
      'locality': locality,
      'city': city,
      'state': state,
      'pincode': pincode,
      'type': type,
      'lat': lat,
      'lng': lng,
      'location': location,
      'addressDetails': addressDetails,
    };
  }
}

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? photoURL;
  final bool profileCompleted;
  final List<AddressModel> addresses;
  final String? primaryAddressId;
  final List<Map<String, dynamic>> wishlist;
  final bool welcomeEmailSent;
  final String? referredByCode;
  final String myReferralCode;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.photoURL,
    this.profileCompleted = false,
    this.addresses = const [],
    this.primaryAddressId,
    this.wishlist = const [],
    this.welcomeEmailSent = true,
    this.referredByCode,
    required this.myReferralCode,
  });

  // Generate referral code format: JOHN482ABC (4 name letters + 3 digits + 3 letters)
  static String generateReferralCode(String name) {
    final cleanName = name.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    final prefix = (cleanName.length >= 4)
        ? cleanName.substring(0, 4)
        : cleanName.padRight(4, 'X');

    final rand = Random();
    final digits = (100 + rand.nextInt(900)).toString(); // 3 digits
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final randomStr = String.fromCharCodes(
      Iterable.generate(3, (_) => chars.codeUnitAt(rand.nextInt(chars.length))),
    );
    return '$prefix$digits$randomStr';
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    var rawAddresses = map['addresses'];
    List<AddressModel> parsedAddresses = [];
    if (rawAddresses is List) {
      parsedAddresses = rawAddresses
          .map((item) => AddressModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    var rawWishlist = map['wishlist'];
    List<Map<String, dynamic>> parsedWishlist = [];
    if (rawWishlist is List) {
      parsedWishlist = rawWishlist
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    final phoneVal = map['phone']?.toString() ?? '';

    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? map['name'] ?? 'User',
      email: map['email'] ?? '',
      phone: phoneVal,
      photoURL: map['photoURL'] ?? map['avatarUrl'],
      profileCompleted: map['profileCompleted'] ?? phoneVal.isNotEmpty,
      addresses: parsedAddresses,
      primaryAddressId: map['primaryAddressId'],
      wishlist: parsedWishlist,
      welcomeEmailSent: map['welcomeEmailSent'] ?? true,
      referredByCode: map['referredByCode'],
      myReferralCode: map['myReferralCode'] ?? generateReferralCode(map['fullName'] ?? 'User'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoURL': photoURL,
      'profileCompleted': profileCompleted,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'primaryAddressId': primaryAddressId,
      'wishlist': wishlist,
      'welcomeEmailSent': welcomeEmailSent,
      'referredByCode': referredByCode,
      'myReferralCode': myReferralCode,
    };
  }

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return wishlist.any((item) => (item['id'] ?? item['productId']) == productId);
  }

  // JSON Serialization for Offline Cache
  String toJsonString() => jsonEncode(toMap());

  factory UserModel.fromJsonString(String jsonStr) {
    final Map<String, dynamic> map = jsonDecode(jsonStr);
    return UserModel.fromMap(map, map['uid'] ?? '');
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? photoURL,
    bool? profileCompleted,
    List<AddressModel>? addresses,
    String? primaryAddressId,
    List<Map<String, dynamic>>? wishlist,
    bool? welcomeEmailSent,
    String? referredByCode,
    String? myReferralCode,
  }) {
    return UserModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoURL: photoURL ?? this.photoURL,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      addresses: addresses ?? this.addresses,
      primaryAddressId: primaryAddressId ?? this.primaryAddressId,
      wishlist: wishlist ?? this.wishlist,
      welcomeEmailSent: welcomeEmailSent ?? this.welcomeEmailSent,
      referredByCode: referredByCode ?? this.referredByCode,
      myReferralCode: myReferralCode ?? this.myReferralCode,
    );
  }
}
