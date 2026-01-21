class Technician {
  final int id;
  final String name;
  final String number;

  Technician({required this.id, required this.name, required this.number});

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      id: json['id'],
      name: json['name'],
      number: json['number'],
    );
  }
}
