class InputCustomerContact {
  int deviceId;
  String? contactType;
  int? technicianId;
  int? phoneNumberId;
  String? message;
  String? contactStatus;
  String? deviceStatus;
  DateTime? contactDate;

  InputCustomerContact({
    required this.deviceId,
    this.contactType,
    this.technicianId,
    this.phoneNumberId,
    this.message,
    this.contactStatus,
    this.deviceStatus,
    this.contactDate,
  });

  static const List<String> contactTypes = [
    'Pessoalmente',
    'Mensagem',
    'Ligação',
  ];

  static const List<String> contactStatuses = [
    'Contatado',
    'Não contatado',
  ];

  factory InputCustomerContact.empty(int deviceId) =>
      InputCustomerContact(deviceId: deviceId, contactDate: DateTime.now());

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'contactType': contactType,
        'technicianId': technicianId,
        'phoneNumberId': phoneNumberId,
        'message': message,
        'contactStatus': contactStatus == 'Contatado' ? true : false,
        'deviceStatus': deviceStatus,
        'contactDate': contactDate?.toIso8601String(),
      };
}
