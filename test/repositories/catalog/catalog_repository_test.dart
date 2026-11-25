import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/device_brand/device_brand_model.dart';
import 'package:flutter_workshop_front/models/device_type.dart/device_type_model.dart';
import 'package:flutter_workshop_front/models/pageable/page_model.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_brand_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_type_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_search_service.dart';

class _FakeTechnicianService extends Fake implements TechnicianService {
  int calls = 0;
  Result<List<Technician>> nextResult = Ok([
    Technician(id: 1, name: 'Carlos', number: '11999999999'),
  ]);

  @override
  Future<Result<List<Technician>>> getTechnicians() async {
    calls++;
    return nextResult;
  }
}

class _FakeColorService extends Fake implements ColorService {
  int calls = 0;
  Result<List<ColorModel>> nextResult = Ok([
    ColorModel(idColor: 1, color: 'Preto'),
  ]);

  @override
  Future<Result<List<ColorModel>>> getColors() async {
    calls++;
    return nextResult;
  }
}

class _FakeDeviceTypeService extends Fake implements DeviceTypeService {
  int calls = 0;
  final List<String?> queries = [];
  Result<List<DeviceType>> nextResult = Ok([
    DeviceType(idType: 1, typeName: 'Celular'),
  ]);

  @override
  Future<Result<List<DeviceType>>> getAllDeviceTypes([String? name]) async {
    calls++;
    queries.add(name);
    return nextResult;
  }
}

class _FakeDeviceBrandService extends Fake implements DeviceBrandService {
  int calls = 0;
  final List<String?> queries = [];
  Result<List<DeviceBrand>> nextResult = Ok([
    DeviceBrand(idBrand: 1, brand: 'Samsung'),
  ]);

  @override
  Future<Result<List<DeviceBrand>>> getAllDeviceBrands([String? name]) async {
    calls++;
    queries.add(name);
    return nextResult;
  }
}

class _FakeSearchService extends Fake implements TypeBrandModelSearchService {
  int searchTypeCalls = 0;
  int searchBrandCalls = 0;
  int searchModelCalls = 0;
  Result<Type> createTypeResult = Ok(Type(idType: 2, type: 'Tablet'));
  Result<Brand> createBrandResult = Ok(Brand(idBrand: 2, brand: 'Apple'));
  Result<Model> createModelResult = Ok(Model(idModel: 2, model: 'iPad'));

  Page<T> _page<T>(List<T> items) => Page<T>(
    content: items,
    totalPages: 1,
    totalElements: items.length,
    last: true,
    size: 15,
    number: 0,
    first: true,
    numberOfElements: items.length,
    empty: items.isEmpty,
  );

  @override
  Future<Result<Page<Type>>> searchTypes(
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    searchTypeCalls++;
    return Ok(_page([Type(idType: 1, type: 'Celular')]));
  }

  @override
  Future<Result<Page<Brand>>> searchBrands(
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    searchBrandCalls++;
    return Ok(_page([Brand(idBrand: 1, brand: 'Samsung')]));
  }

  @override
  Future<Result<Page<Model>>> searchModels(
    int typeId,
    int brandId,
    String? query, {
    int page = 0,
    int size = 15,
  }) async {
    searchModelCalls++;
    return Ok(_page([Model(idModel: 1, model: 'Galaxy')]));
  }

  @override
  Future<Result<Type>> createType(String name) async => createTypeResult;

  @override
  Future<Result<Brand>> createBrand(String name) async => createBrandResult;

  @override
  Future<Result<Model>> createModel(String name) async => createModelResult;
}

void main() {
  late _FakeTechnicianService technicianService;
  late _FakeColorService colorService;
  late _FakeDeviceTypeService typeService;
  late _FakeDeviceBrandService brandService;
  late _FakeSearchService searchService;
  late CatalogRepository repository;

  setUp(() {
    technicianService = _FakeTechnicianService();
    colorService = _FakeColorService();
    typeService = _FakeDeviceTypeService();
    brandService = _FakeDeviceBrandService();
    searchService = _FakeSearchService();
    repository = CatalogRepository(
      technicianService: technicianService,
      colorService: colorService,
      deviceTypeService: typeService,
      deviceBrandService: brandService,
      searchService: searchService,
    );
  });

  group('CatalogRepository caching', () {
    test('caches technicians and supports forceRefresh', () async {
      final first = await repository.getTechnicians();
      final second = await repository.getTechnicians();

      expect(first.valueOrNull, hasLength(1));
      expect(second.valueOrNull, hasLength(1));
      expect(technicianService.calls, 1);

      await repository.getTechnicians(forceRefresh: true);
      expect(technicianService.calls, 2);
    });

    test('does not cache failures so retries hit the service', () async {
      technicianService.nextResult = const Err(NetworkFailure());
      expect(await repository.getTechnicians(), isA<Err<List<Technician>>>());
      expect(technicianService.calls, 1);

      technicianService.nextResult = Ok([
        Technician(id: 2, name: 'Ana', number: '11888888888'),
      ]);
      final recovered = await repository.getTechnicians();
      expect(recovered.valueOrNull?.single.name, 'Ana');
      expect(technicianService.calls, 2);
    });

    test('caches colors and returns unmodifiable list', () async {
      final first = await repository.getColors();
      final second = await repository.getColors();

      expect(colorService.calls, 1);
      expect(second.valueOrNull, hasLength(1));
      expect(
        () => first.valueOrNull!.add(ColorModel(idColor: 2, color: 'Azul')),
        throwsUnsupportedError,
      );
    });

    test(
      'caches unfiltered deviceTypes and bypasses cache when filtered',
      () async {
        await repository.getAllDeviceTypes();
        await repository.getAllDeviceTypes();
        expect(typeService.calls, 1);

        await repository.getAllDeviceTypes('Cel');
        expect(typeService.calls, 2);
        expect(typeService.queries, [null, 'Cel']);
      },
    );

    test(
      'createType invalidates deviceTypes and searchTypes caches on Ok',
      () async {
        await repository.getAllDeviceTypes();
        await repository.searchTypes('Cel');
        await repository.searchTypes('Cel');
        expect(typeService.calls, 1);
        expect(searchService.searchTypeCalls, 1);

        // Failed create must NOT invalidate cache
        searchService.createTypeResult = const Err(NetworkFailure());
        await repository.createType('Tablet');
        await repository.getAllDeviceTypes();
        await repository.searchTypes('Cel');
        expect(typeService.calls, 1);
        expect(searchService.searchTypeCalls, 1);

        // Successful create MUST invalidate both caches
        searchService.createTypeResult = Ok(Type(idType: 2, type: 'Tablet'));
        await repository.createType('Tablet');
        await repository.getAllDeviceTypes();
        await repository.searchTypes('Cel');
        expect(typeService.calls, 2);
        expect(searchService.searchTypeCalls, 2);
      },
    );

    test(
      'createBrand invalidates deviceBrands and searchBrands caches on Ok',
      () async {
        await repository.getAllDeviceBrands();
        await repository.searchBrands('Sam');
        await repository.searchBrands('Sam');
        expect(brandService.calls, 1);
        expect(searchService.searchBrandCalls, 1);

        await repository.createBrand('Apple');
        await repository.getAllDeviceBrands();
        await repository.searchBrands('Sam');
        expect(brandService.calls, 2);
        expect(searchService.searchBrandCalls, 2);
      },
    );

    test('createModel invalidates searchModels cache on Ok', () async {
      await repository.searchModels(1, 1, 'Gal');
      await repository.searchModels(1, 1, 'Gal');
      expect(searchService.searchModelCalls, 1);

      await repository.createModel('iPad');
      await repository.searchModels(1, 1, 'Gal');
      expect(searchService.searchModelCalls, 2);
    });

    test('clearCache resets all cached entries', () async {
      await repository.getTechnicians();
      await repository.getColors();
      await repository.getAllDeviceTypes();
      await repository.getAllDeviceBrands();

      repository.clearCache();

      await repository.getTechnicians();
      await repository.getColors();
      await repository.getAllDeviceTypes();
      await repository.getAllDeviceBrands();

      expect(technicianService.calls, 2);
      expect(colorService.calls, 2);
      expect(typeService.calls, 2);
      expect(brandService.calls, 2);
    });
  });
}
