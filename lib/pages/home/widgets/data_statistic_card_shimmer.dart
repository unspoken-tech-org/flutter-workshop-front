import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/shimmer_container.dart';

class DataStatisticCardShimmer extends StatelessWidget {
  const DataStatisticCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerContainer(
                    width: 120.0,
                    height: 14.0,
                  ),
                  ShimmerContainer(
                    width: 40.0,
                    height: 40.0,
                    borderRadius: 8,
                  ),
                ],
              ),
              SizedBox(height: 8),
              ShimmerContainer(
                width: 80.0,
                height: 24.0,
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  ShimmerContainer(
                    width: 12.0,
                    height: 12.0,
                  ),
                  SizedBox(width: 4),
                  ShimmerContainer(
                    width: 100.0,
                    height: 12.0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
