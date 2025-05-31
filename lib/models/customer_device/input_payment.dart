class InputPayment {
  final int deviceId;
  final double value;
  final String? paymentType;

  InputPayment({
    required this.deviceId,
    required this.value,
    this.paymentType,
  });

  static InputPayment empty(int deviceId) {
    return InputPayment(
      deviceId: deviceId,
      value: 0,
    );
  }

  bool get isEmpty {
    return value == 0 || paymentType == null;
  }

  InputPayment copyWith({
    int? deviceId,
    double? value,
    String? paymentType,
  }) {
    return InputPayment(
      deviceId: deviceId ?? this.deviceId,
      value: value ?? this.value,
      paymentType: paymentType ?? this.paymentType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'value': value,
      'paymentType': paymentType,
      'category': '',
    };
  }
}
