abstract class ITypeBrandModelColor {
  int? getId();
  String getName();
}

class TypeBrandModel implements ITypeBrandModelColor {
  final int idType;
  final String type;
  final List<Brand> brands;

  TypeBrandModel({
    required this.idType,
    required this.type,
    required this.brands,
  });

  @override
  int getId() {
    return idType;
  }

  @override
  String getName() {
    return type;
  }

  factory TypeBrandModel.fromJson(Map<String, dynamic> json) {
    return TypeBrandModel(
      idType: json['idType'],
      type: json['type'],
      brands: (json['brands'] as List)
          .map((brand) => Brand.fromJson(brand))
          .toList(),
    );
  }
}

class Brand implements ITypeBrandModelColor {
  final int idBrand;
  final String brand;
  final List<Model> models;

  Brand({
    required this.idBrand,
    required this.brand,
    required this.models,
  });

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
      idBrand: json['idBrand'],
      brand: json['brand'],
      models: (json['models'] as List)
          .map((model) => Model.fromJson(model))
          .toList(),
    );
  }
}

class Model implements ITypeBrandModelColor {
  final int idModel;
  final String model;

  Model({
    required this.idModel,
    required this.model,
  });

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
      idModel: json['idModel'],
      model: json['model'],
    );
  }
}
