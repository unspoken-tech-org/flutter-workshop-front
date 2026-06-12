class MinifiedCustomerModel {
  final int customerId;
  final String name;
  final DateTime createdAt;
  final String cpf;
  final String mainPhone;
  final String? email;
  final String gender;

  MinifiedCustomerModel({
    required this.customerId,
    required this.name,
    required this.createdAt,
    required this.cpf,
    required this.mainPhone,
    required this.email,
    required this.gender,
  });

  factory MinifiedCustomerModel.fromJson(Map<String, dynamic> json) {
    return MinifiedCustomerModel(
      customerId: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['createdAt']),
      cpf: json['cpf'],
      mainPhone: json['mainPhone'] ?? '',
      email: json['email'],
      gender: json['gender'],
    );
  }
}
