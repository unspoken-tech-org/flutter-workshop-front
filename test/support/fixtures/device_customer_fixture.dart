import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_phones.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

DeviceCustomer makeDeviceCustomer({
  int deviceId = 1,
  int customerId = 1,
  String customerName = 'Maria Silva',
  StatusEnum deviceStatus = StatusEnum.ready,
  String brandName = 'Dell',
  String modelName = 'Inspiron',
  String typeName = 'Notebook',
  int? technicianId,
  String? technicianName,
  String problem = 'Não liga',
  String observation = '',
  String? budget,
  Money? serviceValue,
  Money? budgetFee,
  bool hasUrgency = false,
  bool revision = false,
  List<String> deviceColors = const ['Preto'],
  DateTime? entryDate,
  DateTime? lastUpdate,
  DateTime? departureDate,
  List<CustomerContact> customerContacts = const [],
  List<CustomerPhones> customerPhones = const [],
  List<MinifiedCustomerDevice> otherDevices = const [],
  List<CustomerDevicePayment> payments = const [],
}) {
  return DeviceCustomer(
    deviceId: deviceId,
    customerId: customerId,
    customerName: customerName,
    deviceStatus: deviceStatus,
    brandName: brandName,
    modelName: modelName,
    typeName: typeName,
    technicianId: technicianId,
    technicianName: technicianName,
    problem: problem,
    observation: observation,
    budget: budget,
    serviceValue: serviceValue,
    budgetFee: budgetFee,
    hasUrgency: hasUrgency,
    revision: revision,
    deviceColors: deviceColors,
    entryDate: entryDate ?? DateTime(2026, 1, 10),
    lastUpdate: lastUpdate ?? DateTime(2026, 1, 12),
    departureDate: departureDate,
    customerContacts: customerContacts,
    customerPhones: customerPhones,
    otherDevices: otherDevices,
    payments: payments,
  );
}

CustomerDevicePayment makeCustomerDevicePayment({
  int paymentId = 1,
  DateTime? paymentDate,
  PaymentType paymentType = PaymentType.credito,
  Money value = const Money.fromCents(10000),
  PaymentCategory category = PaymentCategory.service,
  String? receivedBy = 'Carlos Eduardo Oliveira',
}) {
  return CustomerDevicePayment(
    paymentId: paymentId,
    paymentDate: paymentDate ?? DateTime(2026, 1, 15, 14, 30),
    paymentType: paymentType,
    paymentValue: value,
    category: category,
    receivedBy: receivedBy,
  );
}
