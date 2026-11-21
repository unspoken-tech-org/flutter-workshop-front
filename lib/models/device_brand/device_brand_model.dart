class DeviceBrand {
  final int idBrand;
  final String brand;

  DeviceBrand({required this.idBrand, required this.brand});

  factory DeviceBrand.fromJson(Map<String, dynamic> json) {
    return DeviceBrand(
      idBrand: json['idBrand'] as int,
      brand: json['brand'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'idBrand': idBrand, 'brand': brand};
  }
}
