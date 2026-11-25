import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/repositories/types_brands_models/types_brands_models_repository.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_search_service.dart';

class TypesBrandsModelsRemoteDataSource implements TypesBrandsModelsRepository {
  TypesBrandsModelsRemoteDataSource(this._searchService);

  final TypeBrandModelSearchService _searchService;

  @override
  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _searchService.searchTypes(query, page: page, size: size);
  }

  @override
  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _searchService.searchBrands(query, page: page, size: size);
  }

  @override
  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _searchService.searchModels(
      typeId,
      brandId,
      query,
      page: page,
      size: size,
    );
  }

  @override
  Future<Result<Type>> createType(String name) {
    return _searchService.createType(name);
  }

  @override
  Future<Result<Brand>> createBrand(String name) {
    return _searchService.createBrand(name);
  }

  @override
  Future<Result<Model>> createModel(String name) {
    return _searchService.createModel(name);
  }
}
