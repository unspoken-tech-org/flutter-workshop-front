import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/widgets/ws_drawer_item.dart';

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            ),
            const Divider(),
            WsDrawerItem(
                widget: widget,
                isExpanded: isExpanded,
                icon: Icons.home,
                title: 'Home',
                route: const [HomePage.route],
                onTap: () {
                  WsNavigator.pushHome(context);
                }),
            WsDrawerItem(
                widget: widget,
                isExpanded: isExpanded,
                icon: Icons.person,
                title: 'Clientes',
                route: const [
                  AllCustomersPage.route,
                  CustomerRegisterPage.route,
                  CustomerDetailPage.route
                ],
                onTap: () {
                  WsNavigator.pushCustomers(context);
                }),
          ],
        ),
      ),
    );
  }
}
