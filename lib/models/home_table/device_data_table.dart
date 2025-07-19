import 'package:flutter_workshop_front/core/extensions/map_read_json_data.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class DeviceDataTable {
  int deviceId;
  int customerId;
  String customerName;
  String type;
  String brand;
  String model;
  StatusEnum status;
  String problem;
  String? observation;
  bool hasUrgency;
  bool hasRevision;
  String entryDate;
  String? departureDate;

  DeviceDataTable({
    required this.deviceId,
    required this.customerId,
    required this.customerName,
    required this.type,
    required this.brand,
    required this.model,
    required this.status,
    required this.problem,
    required this.hasUrgency,
    required this.hasRevision,
    required this.entryDate,
    this.observation,
    this.departureDate,
  });

  factory DeviceDataTable.fromJson(Map<String, dynamic> json) {
    return DeviceDataTable(
      deviceId: json.toInt('deviceId')!,
      customerId: json.toInt('customerId')!,
      customerName: json.toStr('customerName')!,
      type: json.toStr('type')!,
      brand: json.toStr('brand')!,
      model: json.toStr('model')!,
      status: StatusEnum.fromDbName(json['status']),
      problem: json.toStr('problem')!,
      hasUrgency: json.toBool('hasUrgency', defaultValue: false)!,
      hasRevision: json.toBool('hasRevision', defaultValue: false)!,
      entryDate: json.toStr('entryDate')!,
      observation: json.toStr('observation'),
      departureDate: json.toStr('departureDate'),
    );
  }
}
