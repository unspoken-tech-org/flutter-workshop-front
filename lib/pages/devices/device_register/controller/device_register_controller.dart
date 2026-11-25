import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/exceptions/requisition_exception.dart';
import 'package:flutter_workshop_front/core/result/app_failure.dart';
import 'package:flutter_workshop_front/core/result/result.dart';
import 'package:flutter_workshop_front/core/state/safe_change_notifier_mixin.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/repositories/catalog/catalog_repository.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/device/device_repository.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class DeviceRegisterController extends ChangeNotifier
    with SafeChangeNotifierMixin {
  final CatalogRepository _catalogRepository;
  final DeviceRepository _deviceRepository;
  final CustomerRepository _customerRepository;

  DeviceRegisterController({
    required CatalogRepository catalogRepository,
    required DeviceRepository deviceRepository,
    required CustomerRepository customerRepository,
  }) : _catalogRepository = catalogRepository,
       _deviceRepository = deviceRepository,
       _customerRepository = customerRepository;

  List<ColorModel> allColors = [];
  List<Technician> technicians = [];
  List<MinifiedCustomerModel> customers = [];

  int? customerId;
  String? customerName;

  Type? selectedType;
  Brand? selectedBrand;
  Model? selectedModel;
  List<ColorModel> selectedColors = [];

  bool isLoading = false;
  bool isCustomerSelected = true;
  bool isCreatingDevice = false;

  DeviceInput inputDevice = DeviceInput.empty();

  Future<void> init(int? customerId, String? customerName) async {
    this.customerId = customerId;
    this.customerName = customerName;
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        fetchColors(),
        fetchTechnicians(),
        if (customerId != null && customerName == null)
          _loadCustomerName(customerId),
      ]);
      if (this.customerId == null) isCustomerSelected = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Fallback quando a rota chega só com `customerId` (deep-link ou chamador
  /// sem `extra`): o nome vem da API, nunca da URI.
  Future<void> _loadCustomerName(int customerId) async {
    switch (await _customerRepository.getCustomer(customerId)) {
      case Ok(:final value):
        if (this.customerId == customerId) customerName = value.name;
      case Err(:final failure):
        // Sem o nome não dá para confirmar o cliente: volta para a busca manual.
        if (this.customerId == customerId) {
          this.customerId = null;
          customerName = null;
        }
        SnackBarUtil().showError(failure.messageOr('Erro ao buscar o cliente'));
    }
  }

  Future<void> fetchColors() async {
    switch (await _catalogRepository.getColors()) {
      case Ok(:final value):
        allColors = value;
      case Err(:final failure):
        SnackBarUtil().showError(failure.messageOr('Erro ao buscar as cores'));
    }
  }

  Future<void> fetchTechnicians() async {
    switch (await _catalogRepository.getTechnicians()) {
      case Ok(:final value):
        technicians = value;
      case Err(:final failure):
        SnackBarUtil().showError(
          failure.messageOr('Erro ao buscar os técnicos'),
        );
    }
  }

  Future<List<MinifiedCustomerModel>> fetchCustomers(String query) async {
    final filter = CustomerSearchFilter.getCustomerSearchFilter(
      query,
      page: 0,
      size: 20,
    );
    switch (await _customerRepository.searchCustomers(filter)) {
      case Ok(:final value):
        return value.content;
      case Err():
        // Mensagem fixa de hoje, também para erros da API.
        SnackBarUtil().showError('Erro ao buscar o cliente');
        return [];
    }
  }

  // Adaptador temporário: o autocomplete (SearchFn/CreateFn) ainda espera
  // exceções e as trata de forma genérica.
  T _unwrapOrThrow<T>(Result<T> result) {
    switch (result) {
      case Ok(:final value):
        return value;
      case Err(:final failure):
        throw switch (failure) {
          RejectedFailure(:final message, :final code) => RequisitionException(
            message,
            code,
          ),
          _ => Exception('Falha na requisição'),
        };
    }
  }

  Future<List<Type>> searchTypes(String query) async {
    final page = _unwrapOrThrow(await _catalogRepository.searchTypes(query));
    return page.content;
  }

  Future<List<Brand>> searchBrands(String query) async {
    if (selectedType == null) return [];
    final page = _unwrapOrThrow(await _catalogRepository.searchBrands(query));
    return page.content;
  }

  Future<List<Model>> searchModels(String query) async {
    if (selectedType == null || selectedBrand == null) return [];
    final page = _unwrapOrThrow(
      await _catalogRepository.searchModels(
        selectedType!.idType,
        selectedBrand!.idBrand,
        query,
      ),
    );
    return page.content;
  }

  Future<Type> createType(String name) async {
    return _unwrapOrThrow(await _catalogRepository.createType(name));
  }

  Future<Brand> createBrand(String name) async {
    return _unwrapOrThrow(await _catalogRepository.createBrand(name));
  }

  Future<Model> createModel(String name) async {
    return _unwrapOrThrow(await _catalogRepository.createModel(name));
  }

  void setSelectedType(Type? type) {
    selectedType = type;
    selectedBrand = null;
    selectedModel = null;
    notifyListeners();
  }

  void setSelectedBrand(Brand? brand) {
    selectedBrand = brand;
    selectedModel = null;
    notifyListeners();
  }

  void setSelectedModel(Model? model) {
    selectedModel = model;
    notifyListeners();
  }

  Future<int?> createDevice() async {
    if (isCreatingDevice) return null;
    try {
      isCreatingDevice = true;
      notifyListeners();

      final typeBrandModel = TypeBrandModelInput(
        type: selectedType!.type,
        brand: selectedBrand!.brand,
        model: selectedModel!.model,
      );

      final List<String> colors = selectedColors.map((c) => c.color).toList();

      inputDevice = inputDevice.copyWith(
        customerId: customerId,
        typeBrandModel: typeBrandModel,
        colors: colors,
      );

      switch (await _deviceRepository.createDeviceCustomer(inputDevice)) {
        case Ok(:final value):
          SnackBarUtil().showSuccess('Dispositivo criado com sucesso');
          return value.deviceId;
        case Err(:final failure):
          SnackBarUtil().showError(
            failure.messageOr('Erro ao criar dispositivo'),
          );
          return null;
      }
    } finally {
      isCreatingDevice = false;
      notifyListeners();
    }
  }

  void addColor(ColorModel color) {
    final alreadyExists = selectedColors.any(
      (c) => c.color.toLowerCase() == color.color.toLowerCase(),
    );
    if (alreadyExists) return;

    if (color.idColor == null) {
      final existingInAll = allColors.firstWhereOrNull(
        (c) => c.color.toLowerCase() == color.color.toLowerCase(),
      );
      selectedColors = [...selectedColors, (existingInAll ?? color)];
    } else {
      selectedColors = [...selectedColors, color];
    }
    notifyListeners();
  }

  void removeColor(ColorModel color) {
    if (color.idColor != null) {
      selectedColors = selectedColors
          .where((c) => c.idColor != color.idColor)
          .toList();
    } else {
      selectedColors = selectedColors
          .where((c) => c.color.toLowerCase() != color.color.toLowerCase())
          .toList();
    }
    notifyListeners();
  }

  void setCustomerInfos(int? customerId, String? customerName) {
    this.customerId = customerId;
    this.customerName = customerName;
    isCustomerSelected = true;
    notifyListeners();
  }

  void clearCustomerInfos() {
    customerId = null;
    customerName = null;
    isCustomerSelected = false;
    customers = [];
    notifyListeners();
  }
}
