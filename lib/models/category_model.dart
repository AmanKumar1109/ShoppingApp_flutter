import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final List<String> subcategories;
  final String itemCount;
  final String? icon;
  final String colorHex;
  final String? imageUrl;
  final String? tag;
  final int order;
  final bool isVisible;

  CategoryModel({
    required this.id,
    required this.name,
    this.subcategories = const [],
    this.itemCount = '0 Items',
    this.icon,
    this.colorHex = '0xFFFFF4B8',
    this.imageUrl,
    this.tag,
    this.order = 0,
    this.isVisible = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id, {int count = 0}) {
    final subcats = (map['subcategories'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final resolvedCountStr = (map['itemCount'] != null && (map['itemCount'] as String).isNotEmpty)
        ? map['itemCount'] as String
        : '$count Item${count == 1 ? '' : 's'}';
    return CategoryModel(
      id: map['id'] ?? id,
      name: map['name'] ?? map['title'] ?? id,
      subcategories: subcats,
      itemCount: resolvedCountStr,
      icon: map['icon'],
      colorHex: map['colorHex'] ?? '0xFFFFF4B8',
      imageUrl: map['imageUrl'] ?? map['coverImage'] ?? map['image'],
      tag: map['tag'],
      order: (map['order'] is num) ? (map['order'] as num).toInt() : 0,
      isVisible: map['isActive'] ?? map['isVisible'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'subcategories': subcategories,
      'itemCount': itemCount,
      'icon': icon,
      'colorHex': colorHex,
      'imageUrl': imageUrl,
      'tag': tag,
      'order': order,
      'isActive': isVisible,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    List<String>? subcategories,
    String? itemCount,
    String? icon,
    String? colorHex,
    String? imageUrl,
    String? tag,
    int? order,
    bool? isVisible,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subcategories: subcategories ?? this.subcategories,
      itemCount: itemCount ?? this.itemCount,
      icon: icon ?? this.icon,
      colorHex: colorHex ?? this.colorHex,
      imageUrl: imageUrl ?? this.imageUrl,
      tag: tag ?? this.tag,
      order: order ?? this.order,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  // Icon auto-detection helper based on category name keyword (matching CATEGORIES_FETCH_AND_SHOW_ARCHITECTURE.md)
  IconData get iconData {
    final lower = name.toLowerCase();
    final lowerId = id.toLowerCase();

    if (lowerId == 'all' || lower.contains('all')) {
      return Icons.auto_awesome_rounded;
    } else if (lowerId == 'trending' || lower.contains('trend') || lower.contains('hot')) {
      return Icons.local_fire_department_rounded;
    } else if (lowerId == 'bogo' || lower.contains('bogo') || lower.contains('deal') || lower.contains('offer') || lower.contains('gift')) {
      return Icons.card_giftcard_rounded;
    } else if (lower.contains('baby') || lower.contains('infant') || lower.contains('diaper') || lower.contains('kid')) {
      return Icons.child_care_rounded;
    } else if (lower.contains('veg') || lower.contains('green') || lower.contains('organic')) {
      return Icons.eco_rounded;
    } else if (lower.contains('fruit') || lower.contains('apple') || lower.contains('banana')) {
      return Icons.eco_outlined;
    } else if (lower.contains('dairy') || lower.contains('milk') || lower.contains('egg') || lower.contains('paneer')) {
      return Icons.egg_outlined;
    } else if (lower.contains('bake') || lower.contains('bread') || lower.contains('biscuit') || lower.contains('cake')) {
      return Icons.bakery_dining_rounded;
    } else if (lower.contains('beverage') || lower.contains('drink') || lower.contains('juice') || lower.contains('soda')) {
      return Icons.local_drink_rounded;
    } else if (lower.contains('tea') || lower.contains('coffee')) {
      return Icons.coffee_rounded;
    } else if (lower.contains('snack') || lower.contains('munch') || lower.contains('chip') || lower.contains('namkeen')) {
      return Icons.cookie_rounded;
    } else if (lower.contains('meat') || lower.contains('chicken') || lower.contains('fish')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('rice') || lower.contains('atta') || lower.contains('dal') || lower.contains('flour') || lower.contains('grain')) {
      return Icons.grain_rounded;
    } else if (lower.contains('oil') || lower.contains('ghee') || lower.contains('masala') || lower.contains('spice')) {
      return Icons.soup_kitchen_rounded;
    } else if (lower.contains('dry fruit') || lower.contains('nut') || lower.contains('cereal')) {
      return Icons.breakfast_dining_rounded;
    } else if (lower.contains('sweet') || lower.contains('chocolate') || lower.contains('ice cream')) {
      return Icons.icecream_rounded;
    } else if (lower.contains('personal') || lower.contains('care') || lower.contains('beauty')) {
      return Icons.spa_rounded;
    } else if (lower.contains('clean') || lower.contains('home') || lower.contains('wash')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.shopping_basket_rounded;
  }
}
