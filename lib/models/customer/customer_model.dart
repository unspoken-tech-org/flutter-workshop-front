import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';

class CustomerModel {
  final int customerId;
  final String name;
  final String insertDate;
  final String cpf;
  final String gender;
  final String? email;
  final List<PhoneModel> phones;
  final List<MinifiedCustomerDevice> customerDevices;

  CustomerModel({
    required this.customerId,
    required this.name,
    required this.insertDate,
    required this.cpf,
    required this.gender,
    this.email,
    required this.phones,
    required this.customerDevices,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customerId'],
      name: json['name'],
      insertDate: json['insertDate'],
      cpf: json['cpf'],
      gender: json['gender'],
      email: json['email'],
      phones: (json['phones'] as List)
          .map((phone) => PhoneModel.fromJson(phone))
          .toList(),
      customerDevices: ((json['customerDevices'] ?? []) as List)
          .map((device) => MinifiedCustomerDevice.fromJson(device))
          .toList(),
    );
  }
}

class PhoneModel {
  final int idCellphone;
  final String number;
  final String? name;
  final bool main;

  PhoneModel({
    required this.idCellphone,
    required this.number,
    required this.main,
    this.name,
  });

  factory PhoneModel.fromJson(Map<String, dynamic> json) {
    return PhoneModel(
      idCellphone: json['id'],
      number: json['number'],
      main: json['main'],
      name: json['name'],
    );
  }
}
