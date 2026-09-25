import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final ShapeBorder? shape;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.shape,
  });

  const SkeletonLoader.circular({super.key, required double size})
    : width = size,
      height = size,
      borderRadius = size / 2,
      shape = const CircleBorder();

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: ShapeDecoration(
            shape:
                widget.shape ??
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                ),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1.0, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                Color(0xFFE5E7EB),
                Color(0xFFF3F4F6),
                Color(0xFFE5E7EB),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class HomeSkeletonScreen extends StatelessWidget {
  const HomeSkeletonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Yellowish Header Skeleton Area
          Container(
            padding: const EdgeInsets.only(
              top: 48,
              left: 20,
              right: 20,
              bottom: 16,
            ),
            color: const Color(0xFFFFF9E0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonLoader(width: 80, height: 12),
                        SizedBox(height: 6),
                        SkeletonLoader(width: 160, height: 18),
                      ],
                    ),
                    const SkeletonLoader.circular(size: 40),
                  ],
                ),
                const SizedBox(height: 16),
                const SkeletonLoader(
                  width: double.infinity,
                  height: 48,
                  borderRadius: 24,
                ),
                const SizedBox(height: 16),
                // Horizontal category circles
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 5,
                    itemBuilder: (_, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: const [
                          SkeletonLoader.circular(size: 54),
                          SizedBox(height: 6),
                          SkeletonLoader(width: 50, height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Banner Skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonLoader(
              width: double.infinity,
              height: 155,
              borderRadius: 20,
            ),
          ),

          const SizedBox(height: 24),

          // Section Title Skeleton
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonLoader(width: 150, height: 20),
          ),

          const SizedBox(height: 12),

          // Product Cards Row Skeleton
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              itemBuilder: (_, _) => Container(
                width: 160,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonLoader(width: 160, height: 110, borderRadius: 16),
                    SizedBox(height: 10),
                    SkeletonLoader(width: 140, height: 14),
                    SizedBox(height: 6),
                    SkeletonLoader(width: 80, height: 12),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLoader(width: 60, height: 16),
                        SkeletonLoader(width: 50, height: 26, borderRadius: 14),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
