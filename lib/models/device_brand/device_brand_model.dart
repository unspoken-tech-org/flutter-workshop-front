class DeviceBrandModel {
  final int idBrand;
  final String brand;

  DeviceBrandModel({
    required this.idBrand,
    required this.brand,
  });

  factory DeviceBrandModel.fromJson(Map<String, dynamic> json) {
    return DeviceBrandModel(
      idBrand: json['idBrand'],
      brand: json['brand'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idBrand': idBrand,
      'brand': brand,
    };
  }
}
