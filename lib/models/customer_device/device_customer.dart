import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_phones.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';
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
  final int? technicianId;
  final String? technicianName;
  final String problem;
  final String observation;
  final String? budget;
  final double? serviceValue;
  final double? laborValue;
  final bool laborValueCollected;
  final bool hasUrgency;
  final bool revision;
  final List<String> deviceColors;
  final String entryDate;
  final String? departureDate;
  final String? lastUpdate;
  final List<CustomerContact> customerContacts;
  final List<CustomerPhones> customerPhones;
  final List<MinifiedCustomerDevice> otherDevices;
  final List<CustomerDevicePayment> payments;

  const DeviceCustomer({
    required this.deviceId,
    required this.customerId,
    required this.customerName,
    required this.deviceStatus,
    required this.brandName,
    required this.modelName,
    required this.typeName,
    this.technicianId,
    this.technicianName,
    required this.problem,
    required this.observation,
    required this.hasUrgency,
    required this.revision,
    required this.deviceColors,
    required this.entryDate,
    required this.lastUpdate,
    this.departureDate,
    this.budget,
    this.serviceValue,
    this.laborValue,
    this.laborValueCollected = false,
    this.customerContacts = const [],
    this.customerPhones = const [],
    this.otherDevices = const [],
    this.payments = const [],
  });

  factory DeviceCustomer.fromJson(Map<String, dynamic> json) {
    return DeviceCustomer(
      deviceId: json['deviceId'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      deviceStatus: StatusEnum.fromDbName(json['deviceStatus']),
      brandName: json['brandName'],
      modelName: json['modelName'],
      typeName: json['typeName'],
      technicianId: json['technicianId'],
      technicianName: json['technicianName'],
      problem: json['problem'],
      observation: json['observation'],
      budget: json['budget'],
      serviceValue: json['serviceValue'],
      laborValue: json['laborValue'],
      laborValueCollected: json['laborValueCollected'],
      hasUrgency: json['hasUrgency'],
      revision: json['revision'],
      deviceColors: (json['deviceColors'] as List<dynamic>)
          .map((e) => e.toString().capitalizeFirst)
          .toList(),
      entryDate: json['entryDate'],
      departureDate: json['departureDate'],
      lastUpdate: json['lastUpdate'],
      customerContacts: (json['customerContacts'] as List<dynamic>)
          .map((e) => CustomerContact.fromJson(e))
          .toList(),
      customerPhones: (json['customerPhones'] as List<dynamic>)
          .map((e) => CustomerPhones.fromJson(e))
          .toList(),
      otherDevices: (json['otherDevices'] as List<dynamic>)
          .map((e) => MinifiedCustomerDevice.fromJson(e))
          .toList(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => CustomerDevicePayment.fromJson(e))
          .toList(),
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
      serviceValue: newDeviceCustomer.serviceValue,
      laborValue: newDeviceCustomer.laborValue,
      laborValueCollected: newDeviceCustomer.laborValueCollected,
      hasUrgency: newDeviceCustomer.hasUrgency,
      revision: newDeviceCustomer.revision,
      deviceColors: newDeviceCustomer.deviceColors,
      entryDate: newDeviceCustomer.entryDate,
      departureDate: newDeviceCustomer.departureDate,
      lastUpdate: newDeviceCustomer.lastUpdate,
      customerContacts: newDeviceCustomer.customerContacts,
      customerPhones: newDeviceCustomer.customerPhones,
      otherDevices: newDeviceCustomer.otherDevices,
      payments: newDeviceCustomer.payments,
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
    double? serviceValue,
    double? laborValue,
    bool? laborValueCollected,
    bool? hasUrgency,
    bool? revision,
    List<String>? deviceColors,
    String? entryDate,
    String? departureDate,
    String? lastUpdate,
    List<CustomerContact>? customerContacts,
    List<CustomerPhones>? customerPhones,
    List<MinifiedCustomerDevice>? otherDevices,
    List<CustomerDevicePayment>? payments,
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
      serviceValue: serviceValue ?? this.serviceValue,
      laborValue: laborValue ?? this.laborValue,
      laborValueCollected: laborValueCollected ?? this.laborValueCollected,
      hasUrgency: hasUrgency ?? this.hasUrgency,
      revision: revision ?? this.revision,
      deviceColors: deviceColors ?? this.deviceColors,
      entryDate: entryDate ?? this.entryDate,
      departureDate: departureDate ?? this.departureDate,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      customerContacts: customerContacts ?? this.customerContacts,
      customerPhones: customerPhones ?? this.customerPhones,
      otherDevices: otherDevices ?? this.otherDevices,
      payments: payments ?? this.payments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'customerId': customerId,
      'customerName': customerName,
      'deviceStatus': deviceStatus.dbName,
      'brandName': brandName,
      'modelName': modelName,
      'typeName': typeName,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'problem': problem,
      'observation': observation,
      'budget': budget,
      'serviceValue': serviceValue,
      'laborValue': laborValue,
      'laborValueCollected': laborValueCollected,
      'hasUrgency': hasUrgency,
      'revision': revision,
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
        payments,
        problem,
        observation,
        customerContacts,
        budget,
        serviceValue,
        laborValue,
        laborValueCollected,
        hasUrgency,
        revision,
        deviceColors,
        entryDate,
        departureDate,
        lastUpdate,
      ];
}
