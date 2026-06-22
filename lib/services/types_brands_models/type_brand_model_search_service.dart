import 'package:dio/dio.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/http/custom_dio.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

class TypeBrandModelSearchService {
  final Dio dio = CustomDio.dioInstance();

  Future<Page<Type>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    Response response = await dio.post(
      '/v1/type/search',
      data: {'query': query, 'page': page, 'size': size},
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Page.fromJson(response.data, (json) => Type.fromJson(json));
  }

  Future<Page<Brand>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    Response response = await dio.post(
      '/v1/brand/search',
      data: {'query': query, 'page': page, 'size': size},
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Page.fromJson(response.data, (json) => Brand.fromJson(json));
  }

  Future<Page<Model>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    Response response = await dio.post(
      '/v1/model/search',
      data: {
        'typeId': typeId,
        'brandId': brandId,
        'query': query,
        'page': page,
        'size': size,
      },
    );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Page.fromJson(response.data, (json) => Model.fromJson(json));
  }

  Future<Type> createType(String name) async {
    Response response = await dio.post('/v1/type', data: {'type': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Type.fromJson(response.data);
  }

  Future<Brand> createBrand(String name) async {
    Response response = await dio.post('/v1/brand', data: {'brand': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Brand.fromJson(response.data);
  }

  Future<Model> createModel(String name) async {
    Response response = await dio.post('/v1/model', data: {'model': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(response.data['error']);
    }

    return Model.fromJson(response.data);
  }
}
