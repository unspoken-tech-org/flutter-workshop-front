import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class MinifiedCustomerDevice {
  int deviceId;
  int customerId;
  String typeBrandModel;
  StatusEnum deviceStatus;
  String problem;
  bool hasUrgency;
  bool revision;
  DateTime entryDate;
  DateTime? departureDate;

  MinifiedCustomerDevice({
    required this.deviceId,
    required this.customerId,
    required this.typeBrandModel,
    required this.deviceStatus,
    required this.problem,
    required this.hasUrgency,
    required this.revision,
    required this.entryDate,
    this.departureDate,
  });

  factory MinifiedCustomerDevice.fromJson(Map<String, dynamic> json) {
    return MinifiedCustomerDevice(
      deviceId: json['deviceId'] as int,
      customerId: json['customerId'] as int,
      typeBrandModel: json['typeBrandModel'] as String,
      deviceStatus: StatusEnum.fromDbName(json['deviceStatus'] as String),
      problem: json['problem'] as String,
      hasUrgency: json['hasUrgency'] as bool,
      revision: json['revision'] as bool,
      entryDate: DateTime.parse(json['entryDate'] as String),
      departureDate: json['departureDate'] != null
          ? DateTime.parse(json['departureDate'] as String)
          : null,
    );
  }
}
