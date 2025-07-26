import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/models/device/device_filter.dart';
import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/home/controllers/home_controller.dart';
import 'package:flutter_workshop_front/pages/home/widgets/data_statistic_card_shimmer.dart';
import 'package:flutter_workshop_front/pages/home/widgets/data_statistic_card_widget.dart';
import 'package:provider/provider.dart';

class DashboardStatsView extends StatelessWidget {
  const DashboardStatsView({super.key});

  void _onPressed(BuildContext context, DeviceFilter filter) async {
    await WsNavigator.pushAllDevices(context, filter: filter);
    if (context.mounted) {
      context.read<HomeController>().getDeviceStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        spacing: 16,
        children: [
          const Row(
            spacing: 8,
            children: [
              Icon(Icons.analytics_outlined, size: 24),
              Text(
                'Estatísticas de Aparelhos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Selector<HomeController, (bool, DeviceStatistics?)>(
              selector: (context, controller) => (
                    controller.isLoading,
                    controller.deviceStatistics,
                  ),
              builder: (context, values, child) {
                final (isLoading, statistics) = values;
                if (isLoading) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(
                      8,
                      (index) => const DataStatisticCardShimmer(),
                    ),
                  );
                }
                if (statistics == null) {
                  return const SizedBox.shrink();
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DataStatisticCardWidget(
                      title: 'Em revisão',
                      value: statistics.revisao.total,
                      iconData: Icons.history,
                      iconColor: Colors.deepPurple.shade700,
                      backgroundIconColor: Colors.deepPurple.shade50,
                      change: statistics.revisao.lastMonth,
                      onPressed: () {
                        _onPressed(context, DeviceFilter(hasRevision: true));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Urgentes',
                      value: statistics.urgente.total,
                      iconData: Icons.hourglass_bottom_outlined,
                      iconColor: Colors.red.shade600,
                      backgroundIconColor: Colors.red.shade50,
                      change: statistics.urgente.lastMonth,
                      onPressed: () {
                        _onPressed(context, DeviceFilter(hasUrgency: true));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Novo',
                      value: statistics.novo.total,
                      iconData: Icons.new_releases_outlined,
                      iconColor: Colors.green,
                      backgroundIconColor: Colors.green.shade50,
                      change: statistics.novo.lastMonth,
                      onPressed: () {
                        _onPressed(context,
                            DeviceFilter(status: [StatusEnum.newDevice]));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Em Andamento',
                      value: statistics.emAndamento.total,
                      iconData: Icons.watch_later_outlined,
                      iconColor: Colors.blue.shade600,
                      backgroundIconColor: Colors.blue.shade50,
                      change: statistics.emAndamento.lastMonth,
                      onPressed: () {
                        _onPressed(context,
                            DeviceFilter(status: [StatusEnum.inProgress]));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Aguardando aprovação',
                      value: statistics.aguardando.total,
                      iconData: Icons.watch_later_outlined,
                      iconColor: Colors.yellow.shade800,
                      backgroundIconColor: Colors.yellow.shade50,
                      change: statistics.aguardando.lastMonth,
                      onPressed: () {
                        _onPressed(context,
                            DeviceFilter(status: [StatusEnum.waitingApproval]));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Prontos para entrega',
                      value: statistics.pronto.total,
                      iconData: Icons.unarchive_outlined,
                      iconColor: Colors.green,
                      backgroundIconColor: Colors.green.shade50,
                      change: statistics.pronto.lastMonth,
                      onPressed: () {
                        _onPressed(
                            context, DeviceFilter(status: [StatusEnum.ready]));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Entregues',
                      value: statistics.entregue.total,
                      iconData: Icons.local_shipping_outlined,
                      iconColor: Colors.green,
                      backgroundIconColor: Colors.green.shade50,
                      change: statistics.entregue.lastMonth,
                      onPressed: () {
                        _onPressed(context,
                            DeviceFilter(status: [StatusEnum.delivered]));
                      },
                    ),
                    DataStatisticCardWidget(
                      title: 'Descartados',
                      value: statistics.descartado.total,
                      iconData: Icons.delete_outline,
                      iconColor: Colors.red,
                      backgroundIconColor: Colors.red.shade50,
                      change: statistics.descartado.lastMonth,
                      onPressed: () {
                        _onPressed(context,
                            DeviceFilter(status: [StatusEnum.disposed]));
                      },
                    ),
                  ],
                );
              }),
        ],
      ),
    );
  }
}
