import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class MinifiedCustomerDevice {
  int deviceId;
  int customerId;
  String typeBrandModel;
  StatusEnum deviceStatus;
  String problem;
  bool hasUrgency;
  bool revision;
  String entryDate;
  String? departureDate;

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
      deviceId: json['deviceId'],
      customerId: json['customerId'],
      typeBrandModel: json['typeBrandModel'],
      deviceStatus: StatusEnum.fromDbName(json['deviceStatus']),
      problem: json['problem'],
      hasUrgency: json['hasUrgency'],
      revision: json['revision'],
      entryDate: json['entryDate'],
      departureDate: json['departureDate'],
    );
  }
}
