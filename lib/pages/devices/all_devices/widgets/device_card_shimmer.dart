import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class DeviceCardShimmer extends StatelessWidget {
  const DeviceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              spacing: 16,
              children: [
                const Row(
                  spacing: 16,
                  children: [
                    ShimmerContainer(
                      width: 24.0,
                      height: 24.0,
                    ),
                    ShimmerContainer(
                      width: 60.0,
                      height: 24.0,
                      borderRadius: 16,
                    ),
                  ],
                ),
                Column(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerContainer(
                      width: width * 0.2,
                      height: 12.0,
                    ),
                    ShimmerContainer(
                      width: width * 0.2,
                      height: 12.0,
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        ShimmerContainer(
                          width: width * 0.1,
                          height: 12.0,
                        ),
                        ShimmerContainer(
                          width: width * 0.1,
                          height: 12.0,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            ShimmerContainer(
              width: width * 0.15,
              height: 26.0,
              borderRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
