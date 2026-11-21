class RequisitionException implements Exception {
  final String message;
  final String code;

  RequisitionException(this.message, this.code);

  factory RequisitionException.fromJson(Map<String, dynamic> json) {
    return RequisitionException(
      json['message'] as String,
      json['code'] as String,
    );
  }

  @override
  String toString() {
    return 'RequisitionException: $message - $code';
  }
}
