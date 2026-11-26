import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';

CustomerModel makeCustomerModel({
  int customerId = 1,
  String name = 'Maria Silva',
  DateTime? createdAt,
  String cpf = '52998224725',
  String gender = 'F',
  String? email,
  List<PhoneModel> phones = const [],
  List<MinifiedCustomerDevice> customerDevices = const [],
}) {
  return CustomerModel(
    customerId: customerId,
    name: name,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    cpf: cpf,
    gender: gender,
    email: email,
    phones: phones,
    customerDevices: customerDevices,
  );
}

MinifiedCustomerModel makeMinifiedCustomer({
  int customerId = 1,
  String name = 'Maria Silva',
  DateTime? createdAt,
  String cpf = '52998224725',
  String mainPhone = '11999999999',
  String? email,
  String gender = 'F',
}) {
  return MinifiedCustomerModel(
    customerId: customerId,
    name: name,
    createdAt: createdAt ?? DateTime(2026, 1, 1),
    cpf: cpf,
    mainPhone: mainPhone,
    email: email,
    gender: gender,
  );
}
