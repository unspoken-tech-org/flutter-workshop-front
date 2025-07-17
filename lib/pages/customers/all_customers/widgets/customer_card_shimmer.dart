import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CustomerCardShimmer extends StatelessWidget {
  const CustomerCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 24.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 100,
                height: 16.0,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Container(
                width: 200,
                height: 16.0,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                width: 250,
                height: 16.0,
                color: Colors.white,
              ),
              const SizedBox(height: 4),
              Container(
                width: 150,
                height: 16.0,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
