class CustomerPhones {
  final int id;
  final String number;
  final bool isMain;

  CustomerPhones(
      {required this.id, required this.number, required this.isMain});

  factory CustomerPhones.fromJson(Map<String, dynamic> json) {
    return CustomerPhones(
      id: json['id'],
      number: json['number'],
      isMain: json['main'],
    );
  }
}
