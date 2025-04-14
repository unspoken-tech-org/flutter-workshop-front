import 'package:flutter_workshop_front/models/home_table/status_enum.dart';

class CustomerContact {
  final int id;
  final int deviceId;
  final int technicianId;
  final String technicianName;
  final int? phoneId;
  final String? phoneNumber;
  final String type;
  final bool hasMadeContact;
  final String lastContact;
  final String? conversation;
  final StatusEnum deviceStatus;

  CustomerContact({
    required this.id,
    required this.deviceId,
    required this.technicianId,
    required this.technicianName,
    required this.phoneId,
    required this.phoneNumber,
    required this.type,
    required this.hasMadeContact,
    required this.lastContact,
    required this.conversation,
    required this.deviceStatus,
  });

  factory CustomerContact.fromJson(Map<String, dynamic> json) {
    return CustomerContact(
      id: json['id'],
      deviceId: json['deviceId'],
      technicianId: json['technicianId'],
      technicianName: json['technicianName'],
      phoneId: json['phoneId'],
      phoneNumber: json['phoneNumber'],
      type: json['type'],
      hasMadeContact: json['hasMadeContact'],
      lastContact: json['lastContact'],
      conversation: json['conversation'],
      deviceStatus: StatusEnum.fromString(json['deviceStatus']),
    );
  }
}
