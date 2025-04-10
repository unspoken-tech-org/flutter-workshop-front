import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:equatable/equatable.dart';

class DeviceCustomer extends Equatable {
  final int deviceId;
  final int customerId;
  final String customerName;
  final StatusEnum deviceStatus;
  final String brandName;
  final String modelName;
  final String typeName;
  final int technicianId;
  final String technicianName;
  final String problem;
  final String observation;
  final String? budget;
  final bool hasUrgency;
  final bool isRevision;
  final List<String> deviceColors;
  final String entryDate;
  final String? departureDate;
  final String lastUpdate;

  const DeviceCustomer({
    required this.deviceId,
    required this.customerId,
    required this.customerName,
    required this.deviceStatus,
    required this.brandName,
    required this.modelName,
    required this.typeName,
    required this.technicianId,
    required this.technicianName,
    required this.problem,
    required this.observation,
    required this.hasUrgency,
    required this.isRevision,
    required this.deviceColors,
    required this.entryDate,
    this.departureDate,
    this.budget,
    required this.lastUpdate,
  });

  factory DeviceCustomer.fromJson(Map<String, dynamic> json) {
    return DeviceCustomer(
      deviceId: json['deviceId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      deviceStatus: StatusEnum.fromString(json['deviceStatus']),
      brandName: json['brandName'],
      modelName: json['modelName'],
      typeName: json['typeName'],
      technicianId: json['technicianId'],
      technicianName: json['technicianName'],
      problem: json['problem'],
      observation: json['observation'],
      budget: json['budget'],
      hasUrgency: json['hasUrgency'],
      isRevision: json['revision'],
      deviceColors: (json['deviceColors'] as List<dynamic>)
          .map((e) => e.toString().capitalizeFirst)
          .toList(),
      entryDate: json['entryDate'],
      departureDate: json['departureDate'],
      lastUpdate: json['lastUpdate'],
    );
  }

  DeviceCustomer copyWithDeviceCustomer(DeviceCustomer newDeviceCustomer) {
    return DeviceCustomer(
      deviceId: newDeviceCustomer.deviceId,
      customerId: newDeviceCustomer.customerId,
      customerName: newDeviceCustomer.customerName,
      deviceStatus: newDeviceCustomer.deviceStatus,
      brandName: newDeviceCustomer.brandName,
      modelName: newDeviceCustomer.modelName,
      typeName: newDeviceCustomer.typeName,
      technicianId: newDeviceCustomer.technicianId,
      technicianName: newDeviceCustomer.technicianName,
      problem: newDeviceCustomer.problem,
      observation: newDeviceCustomer.observation,
      budget: newDeviceCustomer.budget,
      hasUrgency: newDeviceCustomer.hasUrgency,
      isRevision: newDeviceCustomer.isRevision,
      deviceColors: newDeviceCustomer.deviceColors,
      entryDate: newDeviceCustomer.entryDate,
      departureDate: newDeviceCustomer.departureDate,
      lastUpdate: newDeviceCustomer.lastUpdate,
    );
  }

  DeviceCustomer copyWith({
    int? deviceId,
    int? customerId,
    String? customerName,
    StatusEnum? deviceStatus,
    String? brandName,
    String? modelName,
    String? typeName,
    int? technicianId,
    String? technicianName,
    String? problem,
    String? observation,
    String? budget,
    bool? hasUrgency,
    bool? isRevision,
    List<String>? deviceColors,
    String? entryDate,
    String? departureDate,
    String? lastUpdate,
  }) {
    return DeviceCustomer(
      deviceId: deviceId ?? this.deviceId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      deviceStatus: deviceStatus ?? this.deviceStatus,
      brandName: brandName ?? this.brandName,
      modelName: modelName ?? this.modelName,
      typeName: typeName ?? this.typeName,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      problem: problem ?? this.problem,
      observation: observation ?? this.observation,
      budget: budget ?? this.budget,
      hasUrgency: hasUrgency ?? this.hasUrgency,
      isRevision: isRevision ?? this.isRevision,
      deviceColors: deviceColors ?? this.deviceColors,
      entryDate: entryDate ?? this.entryDate,
      departureDate: departureDate ?? this.departureDate,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'customerId': customerId,
      'customerName': customerName,
      'deviceStatus': deviceStatus.value,
      'brandName': brandName,
      'modelName': modelName,
      'typeName': typeName,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'problem': problem,
      'observation': observation,
      'budget': budget,
      'hasUrgency': hasUrgency,
      'isRevision': isRevision,
      'deviceColors': deviceColors,
      'entryDate': entryDate,
      'departureDate': departureDate,
    };
  }

  @override
  List<Object?> get props => [
        deviceId,
        customerId,
        customerName,
        deviceStatus,
        brandName,
        modelName,
        typeName,
        technicianId,
        technicianName,
        problem,
        observation,
        budget,
        hasUrgency,
        isRevision,
        deviceColors,
        entryDate,
        departureDate,
        lastUpdate,
      ];
}
