class MinifiedCustomerModel {
  final int customerId;
  final String name;
  final String insertDate;
  final String cpf;
  final String mainPhone;
  final String? email;
  final String gender;

  MinifiedCustomerModel({
    required this.customerId,
    required this.name,
    required this.insertDate,
    required this.cpf,
    required this.mainPhone,
    required this.email,
    required this.gender,
  });

  factory MinifiedCustomerModel.fromJson(Map<String, dynamic> json) {
    return MinifiedCustomerModel(
      customerId: json['id'],
      name: json['name'],
      insertDate: json['insertDate'],
      cpf: json['cpf'],
      mainPhone: json['mainPhone'] ?? '',
      email: json['email'],
      gender: json['gender'],
    );
  }
}
