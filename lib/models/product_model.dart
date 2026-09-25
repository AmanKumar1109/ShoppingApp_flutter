class ProductModel {
  final String id;
  final String title;
  final String category;
  final String subcategory;
  final String brand;
  final String brandLogo;
  final double price; // Sale Price (User pays this)
  final double mrp; // Maximum Retail Price (Original Selling Price)
  final int offPercentage;
  final String unit;
  final String imageUrl;
  final List<String> images;
  final double rating;
  final int reviewsCount;
  final int recentBuyers;
  final int? maxQuantity;
  final bool isDeal;
  final bool isTrending;
  final bool isBogo;
  final bool isVisible;
  final int sortOrder;
  final List<String> tags;
  final String description;

  ProductModel({
    required this.id,
    required this.title,
    required this.category,
    this.subcategory = '',
    this.brand = '',
    this.brandLogo = '',
    required this.price,
    double? mrp,
    int? offPercentage,
    required this.unit,
    required this.imageUrl,
    List<String>? images,
    this.rating = 4.8,
    this.reviewsCount = 24,
    this.recentBuyers = 0,
    this.maxQuantity,
    this.isDeal = false,
    this.isTrending = false,
    this.isBogo = false,
    this.isVisible = true,
    this.sortOrder = 0,
    this.tags = const [],
    String? description,
  })  : mrp = (mrp != null && mrp > 0) ? mrp : price,
        offPercentage = offPercentage ??
            ((mrp != null && mrp > price && mrp > 0)
                ? (((mrp - price) / mrp) * 100).round()
                : 0),
        images = (images != null && images.isNotEmpty)
            ? images
            : (imageUrl.isNotEmpty ? [imageUrl] : const []),
        description = (description != null && description.trim().isNotEmpty)
            ? description.trim()
            : 'Fresh and premium ${title.isNotEmpty ? title : "grocery item"} sourced directly and delivered to your doorstep in 10 minutes.';

  // Savings in rupees
  double get savingsAmount => (mrp > price) ? (mrp - price) : 0.0;

  // Safe images list guaranteed to have at least one image url or fallback
  List<String> get displayImages {
    if (images.isNotEmpty) return images;
    if (imageUrl.isNotEmpty) return [imageUrl];
    return const ['https://images.unsplash.com/photo-1542838132-92c53300491e?w=600&q=80'];
  }

  // Factory constructor transforming raw Firestore item document
  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    final double rawPrice = (map['price'] ??
            map['salePrice'] ??
            map['discountedPrice'] ??
            map['sellingPrice'] ??
            0.0)
        .toDouble();

    final double rawMrp = (map['sellingPrice'] ??
            map['mrp'] ??
            map['originalPrice'] ??
            map['price'] ??
            rawPrice)
        .toDouble();

    int calculatedDiscount = 0;
    if (map['offPercentage'] != null) {
      calculatedDiscount = (map['offPercentage'] as num).toInt();
    } else if (map['discount'] != null) {
      calculatedDiscount = (map['discount'] as num).toInt();
    } else if (rawMrp > rawPrice && rawMrp > 0) {
      calculatedDiscount = (((rawMrp - rawPrice) / rawMrp) * 100).round();
    }

    // Extract image URLs supporting string or array of images
    String extractedImageUrl = '';
    final List<String> extractedImages = [];

    if (map['images'] is List && (map['images'] as List).isNotEmpty) {
      for (var img in (map['images'] as List)) {
        if (img != null && img.toString().trim().isNotEmpty) {
          extractedImages.add(img.toString().trim());
        }
      }
    }

    if (map['image'] != null && map['image'].toString().trim().isNotEmpty) {
      extractedImageUrl = map['image'].toString().trim();
    } else if (map['imageUrl'] != null && map['imageUrl'].toString().trim().isNotEmpty) {
      extractedImageUrl = map['imageUrl'].toString().trim();
    } else if (map['photoURL'] != null && map['photoURL'].toString().trim().isNotEmpty) {
      extractedImageUrl = map['photoURL'].toString().trim();
    } else if (map['img'] != null && map['img'].toString().trim().isNotEmpty) {
      extractedImageUrl = map['img'].toString().trim();
    }

    if (extractedImageUrl.isEmpty && extractedImages.isNotEmpty) {
      extractedImageUrl = extractedImages.first;
    }

    if (extractedImages.isEmpty && extractedImageUrl.isNotEmpty) {
      extractedImages.add(extractedImageUrl);
    }

    final tagList = (map['tags'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final String itemTitle = (map['name'] ?? map['title'] ?? map['productName'] ?? map['itemName'] ?? '').toString().trim();
    final rawDesc = map['description'] ?? map['desc'];
    final String itemDesc = (rawDesc != null && rawDesc.toString().trim().isNotEmpty)
        ? rawDesc.toString().trim()
        : 'Fresh and premium ${itemTitle.isNotEmpty ? itemTitle : "grocery item"} sourced directly and delivered to your doorstep in 10 minutes.';

    final rawMaxQty = map['maxQuantity'];
    int? maxQty;
    if (rawMaxQty != null) {
      maxQty = rawMaxQty is int ? rawMaxQty : int.tryParse(rawMaxQty.toString());
    }

    final rawRecent = map['recentBuyers'];
    int recentCount = 0;
    if (rawRecent != null) {
      recentCount = rawRecent is int ? rawRecent : (int.tryParse(rawRecent.toString()) ?? 0);
    }

    return ProductModel(
      id: id,
      title: itemTitle,
      category: (map['category'] ?? map['categoryName'] ?? map['cat'] ?? 'General').toString().trim(),
      subcategory: (map['subcategory'] ?? map['subCategory'] ?? map['subcat'] ?? '').toString().trim(),
      brand: (map['brand'] ?? '').toString().trim(),
      brandLogo: (map['brandLogo'] ?? '').toString().trim(),
      price: rawPrice,
      mrp: rawMrp,
      offPercentage: calculatedDiscount,
      unit: (map['unit'] ?? map['weight'] ?? map['quantity'] ?? map['packSize'] ?? '1 unit').toString().trim(),
      imageUrl: extractedImageUrl,
      images: extractedImages,
      rating: (map['rating'] ?? map['rate'] ?? map['stars'] ?? 4.8).toDouble(),
      reviewsCount: (map['reviewsCount'] ?? map['reviews'] ?? map['numReviews'] ?? 24) is int
          ? (map['reviewsCount'] ?? map['reviews'] ?? map['numReviews'] ?? 24)
          : int.tryParse((map['reviewsCount'] ?? map['reviews'] ?? map['numReviews'] ?? 24).toString()) ?? 24,
      recentBuyers: recentCount,
      maxQuantity: maxQty,
      isDeal: map['isDeal'] ?? map['onSale'] ?? (calculatedDiscount >= 15),
      isTrending: map['isTrending'] ?? map['trending'] ?? map['isFeatured'] ?? false,
      isBogo: map['isBogo'] ?? map['bogo'] ?? false,
      isVisible: map['isVisible'] ?? map['active'] ?? map['inStock'] ?? map['available'] ?? true,
      sortOrder: (map['sortOrder'] ?? map['order'] ?? 0) is int
          ? (map['sortOrder'] ?? map['order'] ?? 0)
          : int.tryParse((map['sortOrder'] ?? map['order'] ?? 0).toString()) ?? 0,
      tags: tagList,
      description: itemDesc,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': title,
      'title': title,
      'category': category,
      'subcategory': subcategory,
      'brand': brand,
      'brandLogo': brandLogo,
      'price': price,
      'sellingPrice': mrp,
      'mrp': mrp,
      'offPercentage': offPercentage,
      'unit': unit,
      'image': imageUrl,
      'imageUrl': imageUrl,
      'images': images,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'recentBuyers': recentBuyers,
      'maxQuantity': maxQuantity,
      'isDeal': isDeal,
      'isTrending': isTrending,
      'isBogo': isBogo,
      'isVisible': isVisible,
      'sortOrder': sortOrder,
      'tags': tags,
      'description': description,
    };
  }
}

// Alias for backwards compatibility
typedef GroceryProductModel = ProductModel;
