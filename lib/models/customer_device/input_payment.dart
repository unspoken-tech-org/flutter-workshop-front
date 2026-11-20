import 'package:flutter_workshop_front/core/money/money.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';

class InputPayment {
  final int deviceId;
  final Money value;
  final PaymentType? paymentType;
  final PaymentCategory? category;
  final DateTime? paymentDate;
  final String? receivedBy;

  InputPayment({
    required this.deviceId,
    required this.value,
    this.paymentType,
    this.category,
    this.paymentDate,
    this.receivedBy,
  });

  static InputPayment empty(int deviceId) {
    return InputPayment(
      deviceId: deviceId,
      value: Money.zero,
      paymentDate: DateTime.now(),
    );
  }

  bool get isEmpty {
    return value.isZero || paymentType == null;
  }

  InputPayment copyWith({
    int? deviceId,
    Money? value,
    PaymentType? paymentType,
    PaymentCategory? category,
    DateTime? paymentDate,
    String? receivedBy,
  }) {
    return InputPayment(
      deviceId: deviceId ?? this.deviceId,
      value: value ?? this.value,
      paymentType: paymentType ?? this.paymentType,
      category: category ?? this.category,
      paymentDate: paymentDate ?? this.paymentDate,
      receivedBy: receivedBy ?? this.receivedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'value': value.toJson(),
      'paymentType': paymentType?.name,
      'category': category?.dbName,
      'paymentDate': paymentDate?.toIso8601String(),
      'receivedBy': receivedBy,
    };
  }
}
