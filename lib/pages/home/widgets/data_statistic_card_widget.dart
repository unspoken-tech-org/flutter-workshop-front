import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';

class DataStatisticCardWidget extends StatelessWidget {
  final String title;
  final int value;
  final IconData iconData;
  final Color iconColor;
  final Color backgroundIconColor;
  final int change;
  final VoidCallback onPressed;

  const DataStatisticCardWidget({
    super.key,
    required this.title,
    required this.value,
    required this.iconData,
    required this.iconColor,
    required this.backgroundIconColor,
    required this.change,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 150,
      child: HoverableCard(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: backgroundIconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(iconData, size: 24, color: iconColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.trending_up, size: 12, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '+$change este mês',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
