abstract class ITypeBrandModelColor {
  int? getId();
  String getName();
}

class Type implements ITypeBrandModelColor {
  final int idType;
  final String type;

  Type({required this.idType, required this.type});

  @override
  int getId() {
    return idType;
  }

  @override
  String getName() {
    return type;
  }

  factory Type.fromJson(Map<String, dynamic> json) {
    return Type(idType: json['idType'] as int, type: json['type'] as String);
  }
}

class Brand implements ITypeBrandModelColor {
  final int idBrand;
  final String brand;

  Brand({required this.idBrand, required this.brand});

  @override
  int getId() {
    return idBrand;
  }

  @override
  String getName() {
    return brand;
  }

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      idBrand: json['idBrand'] as int,
      brand: json['brand'] as String,
    );
  }
}

class Model implements ITypeBrandModelColor {
  final int idModel;
  final String model;

  Model({required this.idModel, required this.model});

  @override
  int getId() {
    return idModel;
  }

  @override
  String getName() {
    return model;
  }

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      idModel: json['idModel'] as int,
      model: json['model'] as String,
    );
  }
}
