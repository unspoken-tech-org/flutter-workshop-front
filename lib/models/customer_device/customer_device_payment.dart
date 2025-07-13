import 'package:equatable/equatable.dart';

enum PaymentType {
  credito('Crédito'),
  debito('Débito'),
  pix('Pix'),
  dinheiro('Dinheiro'),
  outro('Outro');

  final String displayName;

  const PaymentType(this.displayName);

  static PaymentType fromString(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PaymentType.outro,
    );
  }
}

class CustomerDevicePayment extends Equatable {
  final int paymentId;
  final String paymentDate;
  final PaymentType paymentType;
  final double paymentValue;

  const CustomerDevicePayment({
    required this.paymentId,
    required this.paymentDate,
    required this.paymentType,
    required this.paymentValue,
  });

  factory CustomerDevicePayment.fromJson(Map<String, dynamic> json) {
    return CustomerDevicePayment(
      paymentId: json['paymentId'],
      paymentDate: json['paymentDate'],
      paymentType: PaymentType.fromString(json['paymentType']),
      paymentValue: json['paymentValue'],
    );
  }

  @override
  List<Object?> get props => [
        paymentId,
        paymentDate,
        paymentType,
        paymentValue,
      ];
}
