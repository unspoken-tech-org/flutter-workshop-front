import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

abstract class TypesBrandsModelsRepository {
  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
  });

  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  });

  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  });

  Future<Result<Type>> createType(String name);

  Future<Result<Brand>> createBrand(String name);

  Future<Result<Model>> createModel(String name);
}
