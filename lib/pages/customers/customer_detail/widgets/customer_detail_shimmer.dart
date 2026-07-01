import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class CustomerDetailShimmer extends StatelessWidget {
  const CustomerDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeaderShimmer(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: _buildFieldShimmer(labelWidth: 16, valueWidth: 60),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFieldShimmer(labelWidth: 36, valueWidth: 120),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 2,
              child: _buildFieldShimmer(labelWidth: 36, valueWidth: 180),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 1,
              child: _buildFieldShimmer(labelWidth: 24, valueWidth: 140),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 1,
              child: _buildFieldShimmer(labelWidth: 120, valueWidth: 160),
            ),
            const SizedBox(width: 16),
            Flexible(
              flex: 1,
              child: _buildFieldShimmer(labelWidth: 36, valueWidth: 160),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SecondaryPhonesShimmer(),
        const SizedBox(height: 16),
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [ShimmerContainer(width: 100, height: 44)],
        ),
        const SizedBox(height: 32),
        const _DevicesSectionShimmer(),
      ],
    );
  }

  Widget _buildFieldShimmer({
    required double labelWidth,
    required double valueWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerContainer(width: labelWidth, height: 12),
        const SizedBox(height: 8),
        const ShimmerContainer(width: double.infinity, height: 48),
      ],
    );
  }
}

class _HeaderShimmer extends StatelessWidget {
  const _HeaderShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ShimmerContainer(width: 180, height: 24),
        ShimmerContainer(width: 160, height: 48),
      ],
    );
  }
}

class _SecondaryPhonesShimmer extends StatelessWidget {
  const _SecondaryPhonesShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerContainer(width: 160, height: 12),
        const SizedBox(height: 8),
        ...List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: ShimmerContainer(height: 48)),
                SizedBox(width: 16),
                Expanded(child: ShimmerContainer(height: 48)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DevicesSectionShimmer extends StatelessWidget {
  const _DevicesSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 500,
        child: Column(
          children: List.generate(
            4,
            (_) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: ShimmerContainer(width: double.infinity, height: 60),
            ),
          ),
        ),
      ),
    );
  }
}
