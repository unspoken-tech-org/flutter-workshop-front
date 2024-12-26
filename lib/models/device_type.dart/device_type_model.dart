class DeviceTypeModel {
  final int idType;
  final String typeName;

  DeviceTypeModel({
    required this.idType,
    required this.typeName,
  });

  factory DeviceTypeModel.fromJson(Map<String, dynamic> json) {
    return DeviceTypeModel(
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
