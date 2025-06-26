import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer.dart';

class WsDrawerItem extends StatelessWidget {
  const WsDrawerItem({
    super.key,
    required this.widget,
    required this.isExpanded,
    required this.icon,
    required this.title,
    required this.route,
    required this.onTap,
  });

  final WsDrawer widget;
  final bool isExpanded;
  final IconData icon;
  final String title;
  final List<String> route;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = route.contains(widget.currentRoute);
    final iconColor = isSelected ? Colors.blue : Colors.black87;

    if (!isExpanded) {
      return InkWell(
        onTap: onTap,
        child: Container(
          height: 50,
          width: 50,
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: iconColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
