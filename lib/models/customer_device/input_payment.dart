import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';

class InputPayment {
  final int deviceId;
  final double value;
  final PaymentType? paymentType;
  final DateTime? paymentDate;

  InputPayment({
    required this.deviceId,
    required this.value,
    this.paymentType,
    this.paymentDate,
  });

  static InputPayment empty(int deviceId) {
    return InputPayment(
      deviceId: deviceId,
      value: 0,
      paymentDate: DateTime.now(),
    );
  }

  bool get isEmpty {
    return value == 0 || paymentType == null;
  }

  InputPayment copyWith({
    int? deviceId,
    double? value,
    PaymentType? paymentType,
    DateTime? paymentDate,
  }) {
    return InputPayment(
      deviceId: deviceId ?? this.deviceId,
      value: value ?? this.value,
      paymentType: paymentType ?? this.paymentType,
      paymentDate: paymentDate ?? this.paymentDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'value': value,
      'paymentType': paymentType?.name,
      'category': '',
      'paymentDate': paymentDate?.toIso8601String(),
    };
  }
}
