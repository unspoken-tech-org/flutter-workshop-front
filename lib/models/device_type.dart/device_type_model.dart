class DeviceType {
  final int idType;
  final String typeName;

  DeviceType({
    required this.idType,
    required this.typeName,
  });

  factory DeviceType.fromJson(Map<String, dynamic> json) {
    return DeviceType(
      idType: json['idType'],
      typeName: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idType': idType,
      'type': typeName,
    };
  }
}
