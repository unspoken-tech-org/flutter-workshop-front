import 'package:equatable/equatable.dart';

class CustomerDevicePayment extends Equatable {
  final int paymentId;
  final String paymentDate;
  final String paymentType;
  final double paymentValue;
  final String category;

  const CustomerDevicePayment({
    required this.paymentId,
    required this.paymentDate,
    required this.paymentType,
    required this.paymentValue,
    required this.category,
  });

  factory CustomerDevicePayment.fromJson(Map<String, dynamic> json) {
    return CustomerDevicePayment(
      paymentId: json['paymentId'],
      paymentDate: json['paymentDate'],
      paymentType: json['paymentType'],
      paymentValue: json['paymentValue'],
      category: json['category'],
    );
  }

  @override
  List<Object?> get props => [
        paymentId,
        paymentDate,
        paymentType,
        paymentValue,
        category,
      ];
}
