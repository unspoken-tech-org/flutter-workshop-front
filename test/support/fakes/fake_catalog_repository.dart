import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';

/// Fake tipado de [CatalogRepository] para testes unitários e de widget.
///
/// Por padrão retorna listas vazias (`Ok(const [])`) nas leituras de catálogo
/// para simplificar testes de telas e controllers que não exercitam o catálogo.
class FakeCatalogRepository extends Fake implements CatalogRepository {
  FakeCatalogRepository({
    this.onGetTechnicians,
    this.techniciansResult = const Ok([]),
    this.onGetColors,
    this.colorsResult = const Ok([]),
    this.onGetAllDeviceTypes,
    this.deviceTypesResult = const Ok([]),
    this.onGetAllDeviceBrands,
    this.deviceBrandsResult = const Ok([]),
    this.onSearchTypes,
    this.onSearchBrands,
    this.onSearchModels,
    this.onCreateType,
    this.onCreateBrand,
    this.onCreateModel,
  });

  Future<Result<List<Technician>>> Function({bool forceRefresh})?
  onGetTechnicians;
  Result<List<Technician>> techniciansResult;
  int getTechniciansCalls = 0;

  Future<Result<List<ColorModel>>> Function({bool forceRefresh})? onGetColors;
  Result<List<ColorModel>> colorsResult;
  int getColorsCalls = 0;

  Future<Result<List<DeviceType>>> Function(String? name, bool forceRefresh)?
  onGetAllDeviceTypes;
  Result<List<DeviceType>> deviceTypesResult;
  int getAllDeviceTypesCalls = 0;

  Future<Result<List<DeviceBrand>>> Function(String? name, bool forceRefresh)?
  onGetAllDeviceBrands;
  Result<List<DeviceBrand>> deviceBrandsResult;
  int getAllDeviceBrandsCalls = 0;

  Future<Result<Page<Type>>> Function(
    String? query, {
    int page,
    int size,
    bool forceRefresh,
  })?
  onSearchTypes;

  Future<Result<Page<Brand>>> Function(
    String? query, {
    int page,
    int size,
    bool forceRefresh,
  })?
  onSearchBrands;

  Future<Result<Page<Model>>> Function(
    int typeId,
    int brandId,
    String? query, {
    int page,
    int size,
    bool forceRefresh,
  })?
  onSearchModels;

  Future<Result<Type>> Function(String name)? onCreateType;
  Future<Result<Brand>> Function(String name)? onCreateBrand;
  Future<Result<Model>> Function(String name)? onCreateModel;
  int clearCacheCalls = 0;

  @override
  Future<Result<List<Technician>>> getTechnicians({
    bool forceRefresh = false,
  }) async {
    getTechniciansCalls++;
    if (onGetTechnicians != null) {
      return onGetTechnicians!(forceRefresh: forceRefresh);
    }
    return techniciansResult;
  }

  @override
  Future<Result<List<ColorModel>>> getColors({
    bool forceRefresh = false,
  }) async {
    getColorsCalls++;
    if (onGetColors != null) {
      return onGetColors!(forceRefresh: forceRefresh);
    }
    return colorsResult;
  }

  @override
  Future<Result<List<DeviceType>>> getAllDeviceTypes([
    String? name,
    bool forceRefresh = false,
  ]) async {
    getAllDeviceTypesCalls++;
    if (onGetAllDeviceTypes != null) {
      return onGetAllDeviceTypes!(name, forceRefresh);
    }
    return deviceTypesResult;
  }

  @override
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([
    String? name,
    bool forceRefresh = false,
  ]) async {
    getAllDeviceBrandsCalls++;
    if (onGetAllDeviceBrands != null) {
      return onGetAllDeviceBrands!(name, forceRefresh);
    }
    return deviceBrandsResult;
  }

  @override
  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    if (onSearchTypes != null) {
      return onSearchTypes!(
        query,
        page: page,
        size: size,
        forceRefresh: forceRefresh,
      );
    }
    throw UnimplementedError(
      'FakeCatalogRepository.searchTypes not configured',
    );
  }

  @override
  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    if (onSearchBrands != null) {
      return onSearchBrands!(
        query,
        page: page,
        size: size,
        forceRefresh: forceRefresh,
      );
    }
    throw UnimplementedError(
      'FakeCatalogRepository.searchBrands not configured',
    );
  }

  @override
  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    if (onSearchModels != null) {
      return onSearchModels!(
        typeId,
        brandId,
        query,
        page: page,
        size: size,
        forceRefresh: forceRefresh,
      );
    }
    throw UnimplementedError(
      'FakeCatalogRepository.searchModels not configured',
    );
  }

  @override
  Future<Result<Type>> createType(String name) async {
    if (onCreateType != null) {
      return onCreateType!(name);
    }
    throw UnimplementedError('FakeCatalogRepository.createType not configured');
  }

  @override
  Future<Result<Brand>> createBrand(String name) async {
    if (onCreateBrand != null) {
      return onCreateBrand!(name);
    }
    throw UnimplementedError(
      'FakeCatalogRepository.createBrand not configured',
    );
  }

  @override
  Future<Result<Model>> createModel(String name) async {
    if (onCreateModel != null) {
      return onCreateModel!(name);
    }
    throw UnimplementedError(
      'FakeCatalogRepository.createModel not configured',
    );
  }

  @override
  void clearCache() {
    clearCacheCalls++;
  }
}
