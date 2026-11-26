import 'package:flutter_workshop_front/models/device_statistics/device_statistics.dart';
import 'package:flutter_workshop_front/models/home_table/device_data_table.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

DeviceDataTable makeDeviceDataTable({
  int deviceId = 1,
  int customerId = 1,
  String customerName = 'Maria Silva',
  String type = 'Notebook',
  String brand = 'Dell',
  String model = 'Inspiron',
  StatusEnum status = StatusEnum.newDevice,
  String problem = 'Não liga',
  String? observation,
  bool hasUrgency = false,
  bool hasRevision = false,
  DateTime? entryDate,
  DateTime? departureDate,
}) {
  return DeviceDataTable(
    deviceId: deviceId,
    customerId: customerId,
    customerName: customerName,
    type: type,
    brand: brand,
    model: model,
    status: status,
    problem: problem,
    observation: observation,
    hasUrgency: hasUrgency,
    hasRevision: hasRevision,
    entryDate: entryDate ?? DateTime(2026, 1, 1),
    departureDate: departureDate,
  );
}

DeviceStatistics makeDeviceStatistics({
  StatisticsCount? novo,
  StatisticsCount? aguardando,
  StatisticsCount? emAndamento,
  StatisticsCount? pronto,
  StatisticsCount? entregue,
  StatisticsCount? descartado,
  StatisticsCount? revisao,
  StatisticsCount? urgente,
  List<DeviceDataTable> lastViewedDevices = const [],
}) {
  StatisticsCount zero() => StatisticsCount(total: 0, lastMonth: 0);
  return DeviceStatistics(
    novo: novo ?? zero(),
    aguardando: aguardando ?? zero(),
    emAndamento: emAndamento ?? zero(),
    pronto: pronto ?? zero(),
    entregue: entregue ?? zero(),
    descartado: descartado ?? zero(),
    revisao: revisao ?? zero(),
    urgente: urgente ?? zero(),
    lastViewedDevices: lastViewedDevices,
  );
}
