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
      novo: StatisticsCount.fromJson(
        json[StatusEnum.newDevice.dbName] as Map<String, dynamic>,
      ),
      aguardando: StatisticsCount.fromJson(
        json[StatusEnum.waitingApproval.dbName] as Map<String, dynamic>,
      ),
      emAndamento: StatisticsCount.fromJson(
        json[StatusEnum.inProgress.dbName] as Map<String, dynamic>,
      ),
      pronto: StatisticsCount.fromJson(
        json[StatusEnum.ready.dbName] as Map<String, dynamic>,
      ),
      entregue: StatisticsCount.fromJson(
        json[StatusEnum.delivered.dbName] as Map<String, dynamic>,
      ),
      descartado: StatisticsCount.fromJson(
        json[StatusEnum.disposed.dbName] as Map<String, dynamic>,
      ),
      revisao: StatisticsCount.fromJson(
        json['REVISAO'] as Map<String, dynamic>,
      ),
      urgente: StatisticsCount.fromJson(
        json['URGENTE'] as Map<String, dynamic>,
      ),
      lastViewedDevices: (json['last_viewed_devices'] as List<dynamic>)
          .map((e) => DeviceDataTable.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StatisticsCount {
  final int total;
  final int lastMonth;

  StatisticsCount({required this.total, required this.lastMonth});

  factory StatisticsCount.fromJson(Map<String, dynamic> json) {
    return StatisticsCount(
      total: json['total'] as int,
      lastMonth: json['lastMonth'] as int,
    );
  }
}
