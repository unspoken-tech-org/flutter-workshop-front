import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';

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
      novo: StatisticsCount.fromJson(json['novo']),
      aguardando: StatisticsCount.fromJson(json['aguardando']),
      emAndamento: StatisticsCount.fromJson(json['em_andamento']),
      pronto: StatisticsCount.fromJson(json['pronto']),
      entregue: StatisticsCount.fromJson(json['entregue']),
      descartado: StatisticsCount.fromJson(json['descartado']),
      revisao: StatisticsCount.fromJson(json['revisao']),
      urgente: StatisticsCount.fromJson(json['urgente']),
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
