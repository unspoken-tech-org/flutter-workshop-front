import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/pages/customers/all_customers/all_customers_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/customer_detail_page.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/customer_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/device_details_page.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/device_register_page.dart';
import 'package:flutter_workshop_front/pages/devices/search_devices/search_devices_page.dart';
import 'package:flutter_workshop_front/pages/home/home_page.dart';
import 'package:flutter_workshop_front/pages/setup/setup_page.dart';
import 'package:flutter_workshop_front/services/auth/auth_service.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/widgets/ws_drawer_item.dart';
import 'package:flutter_workshop_front/widgets/core/ws_drawer/ws_drawer_controller.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WsDrawer extends StatelessWidget {
  final String currentRoute;
  const WsDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isExpanded = context.watch<WsDrawerController>().isExpanded;
    final controller = context.read<WsDrawerController>();
    final canPop = GoRouter.of(context).canPop();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: canPop
                  ? Container(
                      padding: const EdgeInsets.only(left: 5),
                      child: BackButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.black,
                          ),
                        ),
                        onPressed: () => GoRouter.of(context).pop(),
                      ),
                    )
                  : null,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                      IconButton(
                        tooltip: 'Alternar menu',
                        onPressed: controller.toggle,
                        icon: const Icon(Icons.chevron_left, size: 20),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          foregroundColor: WidgetStateProperty.all(
                            Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (!isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SizedBox(
                  height: 36,
                  child: IconButton(
                    tooltip: 'Alternar menu',
                    onPressed: controller.toggle,
                    icon: const Icon(Icons.menu, size: 20),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        Colors.transparent,
                      ),
                      foregroundColor: WidgetStateProperty.all(
                        Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            const Divider(),
            WsDrawerItem(
              currentRoute: currentRoute,
              isExpanded: isExpanded,
              icon: Icons.home,
              title: 'Home',
              route: const [HomePage.route],
              onTap: () {
                WsNavigator.pushHome(context);
              },
            ),
            WsDrawerItem(
              currentRoute: currentRoute,
              isExpanded: isExpanded,
              icon: Icons.person,
              title: 'Clientes',
              route: const [
                AllCustomersPage.route,
                CustomerRegisterPage.route,
                CustomerDetailPage.route,
              ],
              onTap: () {
                WsNavigator.pushCustomers(context);
              },
            ),
            WsDrawerItem(
              currentRoute: currentRoute,
              isExpanded: isExpanded,
              icon: Icons.search,
              title: 'Buscar Aparelhos',
              route: const [
                SearchDevicesPage.route,
                DeviceDetailsPage.route,
                DeviceRegisterPage.route,
              ],
              onTap: () {
                WsNavigator.pushSearchDevices(context);
              },
            ),
            const Spacer(),
            const Divider(),
            WsDrawerItem(
              currentRoute: currentRoute,
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
              currentRoute: currentRoute,
              isExpanded: isExpanded,
              icon: Icons.logout,
              title: 'Logout',
              route: const [],
              onTap: () async {
                await context.read<AuthService>().logout();
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
