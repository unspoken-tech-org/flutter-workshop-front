import 'package:flutter/material.dart';

class WsDrawerItem extends StatelessWidget {
  const WsDrawerItem({
    super.key,
    required this.currentRoute,
    required this.isExpanded,
    required this.icon,
    required this.title,
    required this.route,
    required this.onTap,
  });

  final String currentRoute;
  final bool isExpanded;
  final IconData icon;
  final String title;
  final List<String> route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = route.contains(currentRoute);
    final iconColor = isSelected ? Colors.blue : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: 50,
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              if (isExpanded)
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
