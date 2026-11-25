import 'package:flutter_workshop_front/core/http/api_client.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

class TypeBrandModelSearchService {
  TypeBrandModelSearchService(this._api);

  final ApiClient _api;

  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _api.send(
      (dio) => dio.post<dynamic>(
        '/v1/type/search',
        data: {'query': query, 'page': page, 'size': size},
      ),
      decode: (data) => Page.fromJson(
        asJsonMap(data),
        (json) => Type.fromJson(json as Map<String, dynamic>),
      ),
    );
  }

  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _api.send(
      (dio) => dio.post<dynamic>(
        '/v1/brand/search',
        data: {'query': query, 'page': page, 'size': size},
      ),
      decode: (data) => Page.fromJson(
        asJsonMap(data),
        (json) => Brand.fromJson(json as Map<String, dynamic>),
      ),
    );
  }

  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  }) {
    return _api.send(
      (dio) => dio.post<dynamic>(
        '/v1/model/search',
        data: {
          'typeId': typeId,
          'brandId': brandId,
          'query': query,
          'page': page,
          'size': size,
        },
      ),
      decode: (data) => Page.fromJson(
        asJsonMap(data),
        (json) => Model.fromJson(json as Map<String, dynamic>),
      ),
    );
  }

  Future<Result<Type>> createType(String name) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/type', data: {'type': name}),
      expectedStatus: {201},
      decode: (data) => Type.fromJson(asJsonMap(data)),
    );
  }

  Future<Result<Brand>> createBrand(String name) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/brand', data: {'brand': name}),
      expectedStatus: {201},
      decode: (data) => Brand.fromJson(asJsonMap(data)),
    );
  }

  Future<Result<Model>> createModel(String name) {
    return _api.send(
      (dio) => dio.post<dynamic>('/v1/model', data: {'model': name}),
      expectedStatus: {201},
      decode: (data) => Model.fromJson(asJsonMap(data)),
    );
  }
}
