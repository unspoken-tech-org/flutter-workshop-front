import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/all_devices/all_devices_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/device_details_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_page.dart';
import 'package:flutter_workshop_front/pages/home/home_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/widgets/ws_drawer_item.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';
import 'package:go_router/go_router.dart';

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
          color: Colors.white,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (GoRouter.of(context).canPop()) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(left: 5),
                height: 36,
                child: BackButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(Colors.transparent),
                    foregroundColor: WidgetStateProperty.all(Colors.black),
                  ),
                  onPressed: () => GoRouter.of(context).pop(),
                ),
              )
            ] else
              const SizedBox(height: 46),
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
                currentRoute: widget.currentRoute,
                isExpanded: isExpanded,
                icon: Icons.home,
                title: 'Home',
                route: const [HomePage.route],
                onTap: () {
                  WsNavigator.pushHome(context);
                }),
            WsDrawerItem(
                currentRoute: widget.currentRoute,
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
            WsDrawerItem(
              currentRoute: widget.currentRoute,
              isExpanded: isExpanded,
              icon: Icons.local_laundry_service,
              title: 'Aparelhos',
              route: const [
                AllDevicesPage.route,
                DeviceDetailsPage.route,
                DeviceRegisterPage.route,
              ],
              onTap: () {
                WsNavigator.pushAllDevices(context);
              },
            ),
            const Spacer(),
            const Divider(),
            WsDrawerItem(
              currentRoute: widget.currentRoute,
              isExpanded: isExpanded,
              icon: Icons.system_update,
              title: 'Atualizações',
              route: const [],
              onTap: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Verificando atualizações...'),
                    duration: Duration(seconds: 2),
                  ),
                );

                final updateService = UpdateService();
                final updateInfo = await updateService.checkForUpdates();

                if (!context.mounted) return;

                scaffoldMessenger.hideCurrentSnackBar();

                if (updateInfo == null) {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Erro ao verificar atualizações.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (updateInfo.hasUpdate) {
                  await UpdateDialog.show(context, updateInfo, updateService);
                } else {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('O aplicativo já está atualizado!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            WsDrawerItem(
              currentRoute: widget.currentRoute,
              isExpanded: isExpanded,
              icon: Icons.logout,
              title: 'Logout',
              route: const [],
              onTap: () async {
                await AuthService().logout();
                if (!context.mounted) return;
                context.go(SetupPage.route);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
