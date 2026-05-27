import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ShimmerWrap extends StatelessWidget {
  final Widget child;
  const _ShimmerWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerLow,
      highlightColor: cs.surfaceContainerHigh,
      child: child,
    );
  }
}

class ShimmerCardList extends StatelessWidget {
  final int count;
  final double cardHeight;
  const ShimmerCardList({super.key, this.count = 3, this.cardHeight = 72});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrap(
      child: Column(
        children: List.generate(count, (i) => Padding(
          padding: EdgeInsets.only(
            bottom: i < count - 1 ? 12 : 0,
            left: 20,
            right: 20,
          ),
          child: ShimmerBox(height: cardHeight),
        )),
      ),
    );
  }
}

class ShimmerMealCards extends StatelessWidget {
  final int count;
  const ShimmerMealCards({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrap(
      child: Column(
        children: List.generate(count, (i) => Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? 12 : 0),
          child: const ShimmerBox(height: 80),
        )),
      ),
    );
  }
}

class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(height: 24, width: 200),
            const SizedBox(height: 8),
            const ShimmerBox(height: 14, width: 260),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 64, radius: 12)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 64, radius: 12)),
              ],
            ),
            const SizedBox(height: 24),
            const ShimmerBox(height: 14, width: 100),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 80),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerBox(height: 80),
            ),
            const ShimmerBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class ShimmerBill extends StatelessWidget {
  const ShimmerBill({super.key});

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrap(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const ShimmerBox(height: 40, width: 140),
            const SizedBox(height: 8),
            const ShimmerBox(height: 14, width: 100),
            const SizedBox(height: 28),
            const ShimmerBox(height: 14, width: 100),
            const SizedBox(height: 12),
            const ShimmerBox(height: 280),
          ],
        ),
      ),
    );
  }
}
