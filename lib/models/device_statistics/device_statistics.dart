import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class DeviceStatistics {
  final StatisticsCount novo;
  final StatisticsCount aguardando;
  final StatisticsCount emAndamento;
  final StatisticsCount pronto;
  final StatisticsCount entregue;
  final StatisticsCount descartado;
  final StatisticsCount revisao;
  final StatisticsCount urgente;
  final List<DeviceDataTable> lastViewedDevices;

  DeviceStatistics({
    required this.novo,
    required this.aguardando,
    required this.emAndamento,
    required this.pronto,
    required this.entregue,
    required this.descartado,
    required this.revisao,
    required this.urgente,
    required this.lastViewedDevices,
  });

  factory DeviceStatistics.fromJson(Map<String, dynamic> json) {
    return DeviceStatistics(
      novo: StatisticsCount.fromJson(json[StatusEnum.newDevice.dbName]),
      aguardando:
          StatisticsCount.fromJson(json[StatusEnum.waitingApproval.dbName]),
      emAndamento: StatisticsCount.fromJson(json[StatusEnum.inProgress.dbName]),
      pronto: StatisticsCount.fromJson(json[StatusEnum.ready.dbName]),
      entregue: StatisticsCount.fromJson(json[StatusEnum.delivered.dbName]),
      descartado: StatisticsCount.fromJson(json[StatusEnum.disposed.dbName]),
      revisao: StatisticsCount.fromJson(json['REVISAO']),
      urgente: StatisticsCount.fromJson(json['URGENTE']),
      lastViewedDevices: (json['last_viewed_devices'] as List)
          .map((e) => DeviceDataTable.fromJson(e))
          .toList(),
    );
  }
}

class StatisticsCount {
  final int total;
  final int lastMonth;

  StatisticsCount({required this.total, required this.lastMonth});

  factory StatisticsCount.fromJson(Map<String, dynamic> json) {
    return StatisticsCount(total: json['total'], lastMonth: json['lastMonth']);
  }
}
