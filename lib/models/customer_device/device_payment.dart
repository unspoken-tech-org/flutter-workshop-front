class DevicePayment {
  final int paymentId;
  final String paymentDate;
  final String paymentType;
  final double paymentValue;
  final String category;

  DevicePayment({
    required this.paymentId,
    required this.paymentDate,
    required this.paymentType,
    required this.paymentValue,
    required this.category,
  });

  factory DevicePayment.fromJson(Map<String, dynamic> json) {
    return DevicePayment(
      paymentId: json['paymentId'],
      paymentDate: json['paymentDate'],
      paymentType: json['paymentType'],
      paymentValue: json['paymentValue'],
      category: json['category'],
    );
  }
}
