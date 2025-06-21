class CustomerSearchFilter {
  final int? id;
  final String? name;
  final String? cpf;
  final String? email;
  final String? phone;

  CustomerSearchFilter({
    this.id,
    this.name,
    this.cpf,
    this.email,
    this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      'email': email,
      'phone': phone,
    };
  }
}
