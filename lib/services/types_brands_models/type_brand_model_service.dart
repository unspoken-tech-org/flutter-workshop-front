import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

class TypeBrandModelService {
  Future<List<TypeBrandModel>> getTypesBrandsModels() async {
    final response =
        await CustomDio.dioInstance().get('/v1/types-brands-models');
    return (response.data as List)
        .map((e) => TypeBrandModel.fromJson(e))
        .toList();
  }
}
