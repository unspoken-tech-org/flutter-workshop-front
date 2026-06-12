import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

abstract class TypesBrandsModelsRepository {
  Future<Page<Type>> searchTypes(String? query, {int page = 0, int size = 15});

  Future<Page<Brand>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  });

  Future<Page<Model>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  });

  Future<Type> createType(String name);

  Future<Brand> createBrand(String name);

  Future<Model> createModel(String name);
}
