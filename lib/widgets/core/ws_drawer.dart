import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';

class WsDrawer extends StatefulWidget {
  final String currentRoute;
  const WsDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  State<WsDrawer> createState() => _WsDrawerState();
}

class _WsDrawerState extends State<WsDrawer> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isExpanded = true),
      onExit: (_) => setState(() => isExpanded = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isExpanded ? 250 : 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 70,
              padding: EdgeInsets.symmetric(
                horizontal: isExpanded ? 16 : 8,
                vertical: 8,
              ),
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business, size: 30),
                  if (isExpanded) ...[
                    const SizedBox(width: 16),
                    const Text(
                      'Workshop App',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              route: [HomePage.route],
              onTap: () {
                WsNavigator.pushHome(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'Clientes',
              route: [AllCustomersPage.route, CustomerRegisterPage.route],
              onTap: () {
                WsNavigator.pushCustomers(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required List<String> route,
    required VoidCallback onTap,
  }) {
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
    );
  }
}
