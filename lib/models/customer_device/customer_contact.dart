import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class CustomerContact {
  final int id;
  final int deviceId;
  final int technicianId;
  final String technicianName;
  final String? phone;
  final String? phoneNumber;
  final String type;
  final bool hasMadeContact;
  final DateTime lastContact;
  final String? conversation;
  final StatusEnum deviceStatus;

  CustomerContact({
    required this.id,
    required this.deviceId,
    required this.technicianId,
    required this.technicianName,
    required this.phone,
    required this.phoneNumber,
    required this.type,
    required this.hasMadeContact,
    required this.lastContact,
    required this.conversation,
    required this.deviceStatus,
  });

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    return CustomerContact(
      id: json['id'] as int,
      deviceId: json['deviceId'] as int,
      technicianId: json['technicianId'] as int,
      technicianName: json['technicianName'] as String,
      phone: json['phone'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      type: json['type'] as String,
      hasMadeContact: json['hasMadeContact'] as bool,
      lastContact: DateTime.parse(json['lastContact'] as String),
      conversation: json['conversation'] as String?,
      deviceStatus: StatusEnum.fromDbName(json['deviceStatus'] as String),
    );
  }
}
