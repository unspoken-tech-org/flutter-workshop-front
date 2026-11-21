class DeviceType {
  final int idType;
  final String typeName;

  DeviceType({required this.idType, required this.typeName});

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      idType: json['idType'] as int,
      typeName: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'idType': idType, 'type': typeName};
  }
}
