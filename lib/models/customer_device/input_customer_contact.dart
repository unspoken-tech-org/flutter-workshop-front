enum ContactType {
  pessoalmente('Pessoalmente'),
  mensagem('Mensagem'),
  ligacao('Ligação');

  final String displayName;

  const ContactType(
    this.displayName,
  );

  static ContactType fromDisplayName(String displayName) =>
      switch (displayName) {
        'Pessoalmente' => pessoalmente,
        'Mensagem' => mensagem,
        'Ligação' => ligacao,
        _ => throw Exception('Invalid contact type: $displayName'),
      };
}

enum ContactStatus {
  realizado('Realizado'),
  pendente('Pendente');

  final String displayName;

  const ContactStatus(this.displayName);

  static ContactStatus fromDisplayName(String displayName) =>
      switch (displayName) {
        'Realizado' => realizado,
        'Pendente' => pendente,
        _ => throw Exception('Invalid contact status: $displayName'),
      };
}

class InputCustomerContact {
  int deviceId;
  String? contactType;
  int? technicianId;
  String? phoneNumber;
  String? message;
  String? contactStatus;
  String? deviceStatus;
  DateTime? contactDate;

  InputCustomerContact({
    required this.deviceId,
    this.contactType,
    this.technicianId,
    this.phoneNumber,
    this.message,
    this.contactStatus,
    this.deviceStatus,
    this.contactDate,
  });

  static const List<ContactType> contactTypes = ContactType.values;
  static const List<ContactStatus> contactStatuses = ContactStatus.values;

  factory InputCustomerContact.empty(int deviceId) =>
      InputCustomerContact(deviceId: deviceId, contactDate: DateTime.now());

  Map<String, dynamic> toJson() => {
        'deviceId': deviceId,
        'contactType': contactType,
        'technicianId': technicianId,
        'phoneNumber': phoneNumber,
        'message': message,
        'contactStatus': contactStatus == 'Contatado' ? true : false,
        'deviceStatus': deviceStatus,
        'contactDate': contactDate?.toIso8601String(),
      };
}
