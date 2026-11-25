import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_search_service.dart';

/// Repositório do catálogo de apoio (técnicos, cores, tipos, marcas e modelos),
/// com cache em memória para leituras que mudam pouco entre telas.
class CatalogRepository {
  CatalogRepository({
    required TechnicianService technicianService,
    required ColorService colorService,
    required DeviceTypeService deviceTypeService,
    required DeviceBrandService deviceBrandService,
    required TypeBrandModelSearchService searchService,
  }) : _technicianService = technicianService,
       _colorService = colorService,
       _deviceTypeService = deviceTypeService,
       _deviceBrandService = deviceBrandService,
       _searchService = searchService;

  final TechnicianService _technicianService;
  final ColorService _colorService;
  final DeviceTypeService _deviceTypeService;
  final DeviceBrandService _deviceBrandService;
  final TypeBrandModelSearchService _searchService;

  List<Technician>? _technicians;
  List<ColorModel>? _colors;
  List<DeviceType>? _deviceTypes;
  List<DeviceBrand>? _deviceBrands;
  final Map<(String, int, int), Page<Type>> _typeSearchCache = {};
  final Map<(String, int, int), Page<Brand>> _brandSearchCache = {};
  final Map<(int, int, String, int, int), Page<Model>> _modelSearchCache = {};

  Future<Result<List<Technician>>> getTechnicians({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _technicians != null) {
      return Ok(_technicians!);
    }
    final result = await _technicianService.getTechnicians();
    if (result case Ok(:final value)) {
      _technicians = List.unmodifiable(value);
      return Ok(_technicians!);
    }
    return result;
  }

  Future<Result<List<ColorModel>>> getColors({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _colors != null) {
      return Ok(_colors!);
    }
    final result = await _colorService.getColors();
    if (result case Ok(:final value)) {
      _colors = List.unmodifiable(value);
      return Ok(_colors!);
    }
    return result;
  }

  Future<Result<List<DeviceType>>> getAllDeviceTypes([
    String? name,
    bool forceRefresh = false,
  ]) async {
    final isUnfiltered = name == null || name.isEmpty;
    if (isUnfiltered && !forceRefresh && _deviceTypes != null) {
      return Ok(_deviceTypes!);
    }
    final result = await _deviceTypeService.getAllDeviceTypes(name);
    if (result case Ok(:final value) when isUnfiltered) {
      _deviceTypes = List.unmodifiable(value);
      return Ok(_deviceTypes!);
    }
    return result;
  }

  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([
    String? name,
    bool forceRefresh = false,
  ]) async {
    final isUnfiltered = name == null || name.isEmpty;
    if (isUnfiltered && !forceRefresh && _deviceBrands != null) {
      return Ok(_deviceBrands!);
    }
    final result = await _deviceBrandService.getAllDeviceBrands(name);
    if (result case Ok(:final value) when isUnfiltered) {
      _deviceBrands = List.unmodifiable(value);
      return Ok(_deviceBrands!);
    }
    return result;
  }

  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    final key = (query ?? '', page, size);
    if (!forceRefresh && _typeSearchCache.containsKey(key)) {
      return Ok(_typeSearchCache[key]!);
    }
    final result = await _searchService.searchTypes(
      query,
      page: page,
      size: size,
    );
    if (result case Ok(:final value)) {
      _typeSearchCache[key] = value;
    }
    return result;
  }

  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    final key = (query ?? '', page, size);
    if (!forceRefresh && _brandSearchCache.containsKey(key)) {
      return Ok(_brandSearchCache[key]!);
    }
    final result = await _searchService.searchBrands(
      query,
      page: page,
      size: size,
    );
    if (result case Ok(:final value)) {
      _brandSearchCache[key] = value;
    }
    return result;
  }

  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
    bool forceRefresh = false,
  }) async {
    final key = (typeId, brandId, query ?? '', page, size);
    if (!forceRefresh && _modelSearchCache.containsKey(key)) {
      return Ok(_modelSearchCache[key]!);
    }
    final result = await _searchService.searchModels(
      typeId,
      brandId,
      query,
      page: page,
      size: size,
    );
    if (result case Ok(:final value)) {
      _modelSearchCache[key] = value;
    }
    return result;
  }

  Future<Result<Type>> createType(String name) async {
    final result = await _searchService.createType(name);
    if (result is Ok<Type>) {
      _deviceTypes = null;
      _typeSearchCache.clear();
    }
    return result;
  }

  Future<Result<Brand>> createBrand(String name) async {
    final result = await _searchService.createBrand(name);
    if (result is Ok<Brand>) {
      _deviceBrands = null;
      _brandSearchCache.clear();
    }
    return result;
  }

  Future<Result<Model>> createModel(String name) async {
    final result = await _searchService.createModel(name);
    if (result is Ok<Model>) {
      _modelSearchCache.clear();
    }
    return result;
  }

  void clearCache() {
    _technicians = null;
    _colors = null;
    _deviceTypes = null;
    _deviceBrands = null;
    _typeSearchCache.clear();
    _brandSearchCache.clear();
    _modelSearchCache.clear();
  }
}
