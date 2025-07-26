import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class CustomerCardShimmer extends StatelessWidget {
  const CustomerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerContainer(
              width: 250.0,
              height: 24.0,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRowShimmer(),
                      const SizedBox(height: 12),
                      _buildInfoRowShimmer(width: 150),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRowShimmer(width: 120),
                      const SizedBox(height: 12),
                      _buildInfoRowShimmer(width: 110),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowShimmer({double width = 100}) {
    return Row(
      children: [
        const ShimmerContainer(
          width: 16,
          height: 16,
        ),
        const SizedBox(width: 8),
        ShimmerContainer(
          width: width,
          height: 16.0,
        ),
      ],
    );
  }
}
