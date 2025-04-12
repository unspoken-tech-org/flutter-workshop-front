class CustomerPhones {
  final int id;
  final String number;

  CustomerPhones({required this.id, required this.number});

  factory CustomerPhones.fromJson(Map<String, dynamic> json) {
    return CustomerPhones(id: json['id'], number: json['number']);
  }
}
