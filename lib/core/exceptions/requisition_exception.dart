class RequisitionException implements Exception {
  final String message;
  final String code;

  RequisitionException(this.message, this.code);

  factory RequisitionException.fromJson(Map<String, dynamic> json) {
    return RequisitionException(json['message'], json['code']);
  }

  @override
  String toString() {
    return 'RequisitionException: $message - $code';
  }
}
