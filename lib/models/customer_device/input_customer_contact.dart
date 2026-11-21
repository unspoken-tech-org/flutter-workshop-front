import 'package:collection/collection.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';

enum ContactType {
  pessoalmente('Pessoalmente'),
  mensagem('Mensagem'),
  ligacao('Ligação');

  final String displayName;

  const ContactType(this.displayName);

  static ContactType? tryParse(String? raw) {
    final normalized = raw?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;

    return ContactType.values.firstWhereOrNull(
      (e) =>
          e.name.toLowerCase() == normalized ||
          e.displayName.toLowerCase() == normalized,
    );
  }

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

  factory InputCustomerContact.fromCustomerContact(CustomerContact contact) {
    final matchedType = ContactType.tryParse(contact.type);

    final DateTime parsedDate = contact.lastContact;

    return InputCustomerContact(
      deviceId: contact.deviceId,
      contactType: matchedType?.name,
      technicianId: contact.technicianId,
      phoneNumber: contact.phoneNumber ?? contact.phone,
      message: contact.conversation,
      contactStatus: contact.hasMadeContact
          ? ContactStatus.realizado.name
          : ContactStatus.pendente.name,
      deviceStatus: contact.deviceStatus.dbName,
      contactDate: parsedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'contactType': contactType,
    'technicianId': technicianId,
    'phoneNumber': phoneNumber,
    'message': message,
    'contactStatus': contactStatus == ContactStatus.realizado.name,
    'deviceStatus': deviceStatus,
    'contactDate': contactDate?.toIso8601String(),
  };
}
