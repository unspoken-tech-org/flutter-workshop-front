import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/money/money.dart';
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
  final Money? serviceValue;
  final Money? budgetFee;
  final bool hasUrgency;
  final bool revision;
  final List<String> deviceColors;
  final DateTime entryDate;
  final DateTime? departureDate;
  final DateTime? lastUpdate;
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
    this.budgetFee,
    this.customerContacts = const [],
    this.customerPhones = const [],
    this.otherDevices = const [],
    this.payments = const [],
  });

  Money get totalPaidFee {
    return payments
        .where((p) => p.category == PaymentCategory.budgetFee)
        .fold(Money.zero, (sum, p) => sum + p.paymentValue);
  }

  bool get computedBudgetFeeCollected {
    final fee = budgetFee ?? Money.zero;
    if (!fee.isPositive) return false;

    return totalPaidFee >= fee;
  }

  factory DeviceCustomer.fromJson(Map<String, dynamic> json) {
    return DeviceCustomer(
      deviceId: json['deviceId'] as int,
      customerId: json['customerId'] as int,
      customerName: json['customerName'] as String,
      deviceStatus: StatusEnum.fromDbName(json['deviceStatus'] as String),
      brandName: json['brandName'] as String,
      modelName: json['modelName'] as String,
      typeName: json['typeName'] as String,
      technicianId: json['technicianId'] as int?,
      technicianName: json['technicianName'] as String?,
      problem: json['problem'] as String,
      observation: json['observation'] as String,
      budget: json['budget'] as String?,
      serviceValue: json['serviceValue'] != null
          ? Money.fromJson(json['serviceValue'])
          : null,
      budgetFee: json['budgetFee'] != null
          ? Money.fromJson(json['budgetFee'])
          : null,
      hasUrgency: json['hasUrgency'] as bool,
      revision: json['revision'] as bool,
      deviceColors: (json['deviceColors'] as List<dynamic>)
          .map((e) => e.toString().capitalizeFirst)
          .toList(),
      entryDate: DateTime.parse(json['entryDate'] as String),
      departureDate: json['departureDate'] != null
          ? DateTime.parse(json['departureDate'] as String)
          : null,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.parse(json['lastUpdate'] as String)
          : null,
      customerContacts: (json['customerContacts'] as List<dynamic>)
          .map((e) => CustomerContact.fromJson(e as Map<String, dynamic>))
          .toList(),
      customerPhones: (json['customerPhones'] as List<dynamic>)
          .map((e) => CustomerPhones.fromJson(e as Map<String, dynamic>))
          .toList(),
      otherDevices: (json['otherDevices'] as List<dynamic>)
          .map(
            (e) => MinifiedCustomerDevice.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      payments: (json['payments'] as List<dynamic>)
          .map((e) => CustomerDevicePayment.fromJson(e as Map<String, dynamic>))
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
      budgetFee: newDeviceCustomer.budgetFee,
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

  static const Object _unset = Object();

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
    Money? serviceValue,
    Money? budgetFee,
    bool? budgetFeeCollected,
    bool? hasUrgency,
    bool? revision,
    List<String>? deviceColors,
    DateTime? entryDate,
    Object? departureDate = _unset,
    DateTime? lastUpdate,
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
      budgetFee: budgetFee ?? this.budgetFee,
      hasUrgency: hasUrgency ?? this.hasUrgency,
      revision: revision ?? this.revision,
      deviceColors: deviceColors ?? this.deviceColors,
      entryDate: entryDate ?? this.entryDate,
      departureDate: identical(departureDate, _unset)
          ? this.departureDate
          : departureDate as DateTime?,
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
      'serviceValue': serviceValue?.toJson(),
      'budgetFee': budgetFee?.toJson(),
      'hasUrgency': hasUrgency,
      'revision': revision,
      'deviceColors': deviceColors,
      'entryDate': entryDate.toIso8601String(),
      'departureDate': departureDate?.toIso8601String(),
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
    budgetFee,
    hasUrgency,
    revision,
    deviceColors,
    entryDate,
    departureDate,
    lastUpdate,
  ];
}
