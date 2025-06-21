import 'package:flutter/material.dart';

class EmptyListWidget extends StatelessWidget {
  final String message;
  final String imagePath;
  final double imageWidth;
  final double imageHeight;

  const EmptyListWidget({
    super.key,
    required this.message,
    this.imagePath = 'assets/images/not_found.png',
    this.imageWidth = 200,
    this.imageHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            width: imageWidth,
            height: imageHeight,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
