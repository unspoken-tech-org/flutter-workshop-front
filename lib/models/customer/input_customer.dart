import 'package:equatable/equatable.dart';

class InputCustomer extends Equatable {
  final String? name;
  final String? email;
  final String? cpf;
  final String? gender;
  final List<InputCustomerPhone> phones;

  const InputCustomer({
    this.name,
    this.email,
    this.cpf,
    this.gender,
    this.phones = const [],
  });

  factory InputCustomer.empty() => const InputCustomer();

  InputCustomer copyWith({
    String? name,
    String? email,
    String? cpf,
    String? gender,
    List<InputCustomerPhone>? phones,
  }) =>
      InputCustomer(
        name: name ?? this.name,
        email: email ?? this.email,
        cpf: cpf ?? this.cpf,
        gender: gender ?? this.gender,
        phones: phones ?? this.phones,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'cpf': cpf,
        'gender': gender,
        'phones': phones.map((phone) => phone.toJson()).toList(),
      };

  @override
  List<Object?> get props => [name, email, cpf, gender, phones];
}

class InputCustomerPhone {
  final int? id;
  final String number;
  final String? name;
  final bool isPrimary;

  InputCustomerPhone({
    this.id,
    required String number,
    this.name,
    this.isPrimary = false,
  }) : number = number.replaceAll(RegExp(r'\D'), '');

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'number': number,
        if (name != null) 'name': name,
        'isPrimary': isPrimary,
      };
}
