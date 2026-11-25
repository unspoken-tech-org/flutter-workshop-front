import 'package:flutter_workshop_front/core/di/app_dependencies.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/logging/app_logger.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/home/widgets/dashboard_stats_view.dart';
import 'package:flutter_workshop_front/pages/home/widgets/quick_actions_widget.dart';
import 'package:flutter_workshop_front/pages/home/widgets/recent_devices_view.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/shared/update_dialog.dart';
import 'package:flutter_workshop_front/services/update/update_service.dart';
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
      unawaited(_checkForUpdatesOnStartup());
    });
  }

  Future<void> _checkForUpdatesOnStartup() async {
    final updateService = context.read<AppDependencies>().updateService;
    if (updateService.hasCheckedOnStartup) return;
    updateService.hasCheckedOnStartup = true;
    AppLogger.info('Update', 'Startup update check triggered');

    try {
      final result = await updateService.checkForUpdates();
      final updateInfo = switch (result) {
        UpdateCheckCompleted(:final info) => info,
        UpdateCheckDisabled() || UpdateCheckFailed() => null,
      };

      if (!mounted || updateInfo == null || !updateInfo.hasUpdate) return;

      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) {
        AppLogger.info('Update', 'Startup dialog skipped: home unmounted');
        return;
      }

      await UpdateDialog.show(context, updateInfo, updateService);
    } catch (e, st) {
      debugPrint('[HomePage] Failed to check for updates: $e');
      AppLogger.error(
        'Update',
        'Startup update flow failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final controller = HomeController(
          context.read<AppDependencies>().deviceStatisticsService,
        );
        unawaited(controller.getDeviceStatistics());
        return controller;
      },
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
