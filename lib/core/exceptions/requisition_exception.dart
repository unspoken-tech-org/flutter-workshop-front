class RequisitionException implements Exception {
  final String message;
  final String code;

  RequisitionException(this.message, this.code);

  factory RequisitionException.fromJson(Map<String, dynamic> json) {
    final message = json['message'];
    final code = json['code'];
    return RequisitionException(
      message is String && message.isNotEmpty
          ? message
          : 'Erro na requisição. Tente novamente.',
      code?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'RequisitionException: $message - $code';
  }
}
