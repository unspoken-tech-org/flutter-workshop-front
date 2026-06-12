import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_repository.dart';
import 'package:flutter_workshop_front/repositories/types_brands_models/types_brands_models_repository.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class DeviceRegisterController extends ChangeNotifier {
  final TypesBrandsModelsRepository _typesBrandsModelsRepository;
  final ColorService _colorService;
  final DeviceCustomerService _deviceCustomerService;
  final TechnicianService _technicianService;
  final CustomerRepository _customerRepository;

  DeviceRegisterController(
    this._typesBrandsModelsRepository,
    this._colorService,
    this._deviceCustomerService,
    this._technicianService,
    this._customerRepository,
  );

  final Debouncer _debouncer = Debouncer(milliseconds: 500);

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
      await Future.wait([fetchColors(), fetchTechnicians()]);
      if (customerId == null) isCustomerSelected = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchColors() async {
    try {
      final colors = await _colorService.getColors();
      allColors = colors;
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar as cores');
    }
  }

  Future<void> fetchTechnicians() async {
    try {
      final technicians = await _technicianService.getTechnicians();
      this.technicians = technicians;
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar os técnicos');
    }
  }

  Future<void> searchCustomers(String? searchTerm) async {
    _debouncer.run(() async {
      try {
        final filter = CustomerSearchFilter.getCustomerSearchFilter(
          searchTerm,
          page: 0,
          size: 20,
        );
        final customersPage = await _customerRepository.searchCustomers(filter);
        customers = customersPage.content;
        notifyListeners();
      } catch (e) {
        SnackBarUtil().showError('Erro ao buscar o cliente');
        customers = [];
        notifyListeners();
      }
    });
  }

  Future<List<Type>> searchTypes(String query) async {
    final page = await _typesBrandsModelsRepository.searchTypes(query);
    return page.content;
  }

  Future<List<Brand>> searchBrands(String query) async {
    if (selectedType == null) return [];
    final page = await _typesBrandsModelsRepository.searchBrands(query);
    return page.content;
  }

  Future<List<Model>> searchModels(String query) async {
    if (selectedType == null || selectedBrand == null) return [];
    final page = await _typesBrandsModelsRepository.searchModels(
      selectedType!.idType,
      selectedBrand!.idBrand,
      query,
    );
    return page.content;
  }

  Future<Type> createType(String name) async {
    return _typesBrandsModelsRepository.createType(name);
  }

  Future<Brand> createBrand(String name) async {
    return _typesBrandsModelsRepository.createBrand(name);
  }

  Future<Model> createModel(String name) async {
    return _typesBrandsModelsRepository.createModel(name);
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

      final deviceCustomer = await _deviceCustomerService.createDeviceCustomer(
        inputDevice,
      );

      SnackBarUtil().showSuccess('Dispositivo criado com sucesso');
      return deviceCustomer.deviceId;
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar dispositivo');
      return null;
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
