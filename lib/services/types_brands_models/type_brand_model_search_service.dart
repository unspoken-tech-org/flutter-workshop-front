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
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>(
          '/v1/type/search',
          data: {'query': query, 'page': page, 'size': size},
        );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Page.fromJson(
      response.data!,
      (json) => Type.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Page<Brand>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>(
          '/v1/brand/search',
          data: {'query': query, 'page': page, 'size': size},
        );

    if (response.statusCode != 200) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Page.fromJson(
      response.data!,
      (json) => Brand.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Page<Model>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>(
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
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Page.fromJson(
      response.data!,
      (json) => Model.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<Type> createType(String name) async {
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/type', data: {'type': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Type.fromJson(response.data!);
  }

  Future<Brand> createBrand(String name) async {
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/brand', data: {'brand': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Brand.fromJson(response.data!);
  }

  Future<Model> createModel(String name) async {
    final Response<Map<String, dynamic>> response = await dio
        .post<Map<String, dynamic>>('/v1/model', data: {'model': name});

    if (response.statusCode != 201) {
      throw RequisitionException.fromJson(
        response.data!['error'] as Map<String, dynamic>,
      );
    }

    return Model.fromJson(response.data!);
  }
}
