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
      customerId: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cpf: json['cpf'] as String,
      mainPhone: (json['mainPhone'] as String?) ?? '',
      email: json['email'] as String?,
      gender: json['gender'] as String,
    );
  }
}
