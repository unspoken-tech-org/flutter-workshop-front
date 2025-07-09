import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

class ColorModel implements ITypeBrandModelColor {
  final int? idColor;
  final String color;

  ColorModel({required this.idColor, required this.color});

  factory ColorModel.fromJson(Map<String, dynamic> json) {
    return ColorModel(
      idColor: json['idColor'],
      color: json['color'],
    );
  }

  @override
  int? getId() {
    return idColor;
  }

  @override
  String getName() {
    return color;
  }
}
