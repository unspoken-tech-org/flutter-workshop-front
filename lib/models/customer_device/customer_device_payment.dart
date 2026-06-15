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

enum PaymentCategory {
  budgetFee('taxa_orcamento', 'Taxa de orçamento'),
  service('servicos', 'Serviços');

  final String displayName;
  final String dbName;

  const PaymentCategory(this.dbName, this.displayName);

  static PaymentCategory fromString(String value) {
    return PaymentCategory.values.firstWhere(
      (e) => e.dbName == value,
      orElse: () => PaymentCategory.service,
    );
  }
}

class CustomerDevicePayment extends Equatable {
  final int paymentId;
  final DateTime paymentDate;
  final PaymentType paymentType;
  final double paymentValue;
  final PaymentCategory category;

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
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentType: PaymentType.fromString(json['paymentType']),
      paymentValue: json['paymentValue'],
      category: PaymentCategory.fromString(json['category']),
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
