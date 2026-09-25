import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'skeleton_loader.dart';

class FastCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final Widget? errorWidget;

  const FastCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    Widget content;
    try {
      content = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: width != null ? (width! * 2).toInt() : 400,
        memCacheHeight: height != null ? (height! * 2).toInt() : 400,
        placeholder: (context, url) => SkeletonLoader(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: borderRadius,
        ),
        errorWidget: (context, url, error) => Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: 400,
          cacheHeight: 400,
          errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
        ),
      );
    } catch (_) {
      content = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: 400,
        cacheHeight: 400,
        errorBuilder: (_, _, _) => _buildErrorPlaceholder(),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: content,
      );
    }

    return content;
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4B8),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_basket_rounded,
          color: Color(0xFFF7C415),
          size: 28,
        ),
      ),
    );
  }
}
