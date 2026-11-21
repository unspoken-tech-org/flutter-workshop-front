import 'package:flutter_workshop_front/models/customer_device/minified_customer_device.dart';

class CustomerModel {
  final int customerId;
  final String name;
  final DateTime createdAt;
  final String cpf;
  final String gender;
  final String? email;
  final List<PhoneModel> phones;
  final List<MinifiedCustomerDevice> customerDevices;

  CustomerModel({
    required this.customerId,
    required this.name,
    required this.createdAt,
    required this.cpf,
    required this.gender,
    this.email,
    required this.phones,
    required this.customerDevices,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      customerId: json['customerId'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cpf: json['cpf'] as String,
      gender: json['gender'] as String,
      email: json['email'] as String?,
      phones: (json['phones'] as List<dynamic>)
          .map((phone) => PhoneModel.fromJson(phone as Map<String, dynamic>))
          .toList(),
      customerDevices:
          ((json['customerDevices'] ?? <dynamic>[]) as List<dynamic>)
              .map(
                (device) => MinifiedCustomerDevice.fromJson(
                  device as Map<String, dynamic>,
                ),
              )
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
      idCellphone: json['id'] as int,
      number: json['number'] as String,
      main: json['main'] as bool,
      name: json['name'] as String?,
    );
  }
}
