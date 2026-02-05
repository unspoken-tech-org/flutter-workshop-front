import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/home/widgets/dashboard_stats_view.dart';
import 'package:flutter_workshop_front/pages/home/widgets/quick_actions_widget.dart';
import 'package:flutter_workshop_front/pages/home/widgets/recent_devices_view.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  static const route = '/home';

  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdatesOnStartup();
    });
  }

  Future<void> _checkForUpdatesOnStartup() async {
    if (UpdateService.hasCheckedOnStartup) return;
    UpdateService.hasCheckedOnStartup = true;

    try {
      final updateService = UpdateService();
      final updateInfo = await updateService.checkForUpdates();

      if (!mounted || updateInfo == null || !updateInfo.hasUpdate) return;

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      await UpdateDialog.show(context, updateInfo, updateService);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => HomeController()..getDeviceStatistics(),
      child: WsScaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 24.0),
                  child: Row(
                    children: [
                      Text(
                        'Dashboard Aparelhos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    spacing: 32,
                    children: [
                      QuickActionsWidget(),
                      DashboardStatsView(),
                      RecentDevicesView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
