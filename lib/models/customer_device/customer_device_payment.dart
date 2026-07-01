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
      (e) => e.name == value.toLowerCase(),
      orElse: () => PaymentType.outro,
    );
  }
}

enum PaymentCategory {
  budgetFee('taxa_orcamento', 'Taxa de orçamento'),
  service('servicos', 'Serviços');

  final String dbName;
  final String displayName;

  const PaymentCategory(this.dbName, this.displayName);

  static PaymentCategory fromString(String value) {
    return PaymentCategory.values.firstWhere(
      (e) => e.dbName == value.toLowerCase(),
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
  final String? receivedBy;

  const CustomerDevicePayment({
    required this.paymentId,
    required this.paymentDate,
    required this.paymentType,
    required this.paymentValue,
    required this.category,
    this.receivedBy,
  });

  factory CustomerDevicePayment.fromJson(Map<String, dynamic> json) {
    return CustomerDevicePayment(
      paymentId: json['paymentId'],
      paymentDate: DateTime.parse(json['paymentDate']),
      paymentType: PaymentType.fromString(json['paymentType']),
      paymentValue: json['paymentValue'],
      category: PaymentCategory.fromString(json['category']),
      receivedBy: json['receivedBy'],
    );
  }

  @override
  List<Object?> get props => [
    paymentId,
    paymentDate,
    paymentType,
    paymentValue,
    category,
    receivedBy,
  ];
}
