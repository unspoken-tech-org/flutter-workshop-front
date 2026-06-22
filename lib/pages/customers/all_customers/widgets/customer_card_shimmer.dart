import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class CustomerCardShimmer extends StatelessWidget {
  const CustomerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ShimmerContainer(height: 18.0, width: double.infinity),
                ),
                SizedBox(width: 8),
                ShimmerContainer(width: 20.0, height: 20.0),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, thickness: 0.5, height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoRowShimmer()),
                Expanded(child: _buildInfoRowShimmer(width: 140)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildInfoRowShimmer(width: 120)),
                Expanded(child: _buildInfoRowShimmer(width: 110)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRowShimmer({double width = 100}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerContainer(width: 16.0, height: 16.0),
        const SizedBox(width: 8),
        ShimmerContainer(width: width, height: 16.0),
      ],
    );
  }
}
