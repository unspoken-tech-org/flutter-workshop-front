import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/core/debouncer.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/customer/customer_search_filter.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/customer/customer_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class DeviceRegisterController extends ChangeNotifier {
  final TypeBrandModelService _typeBrandModelService;
  final ColorService _colorService;
  final DeviceCustomerService _deviceCustomerService;
  final TechnicianService _technicianService;
  final CustomerService _customerService;

  DeviceRegisterController(
    this._typeBrandModelService,
    this._colorService,
    this._deviceCustomerService,
    this._technicianService,
    this._customerService,
  );

  final Debouncer _debouncer = Debouncer(milliseconds: 500);

  List<TypeBrandModel> typesBrandsModels = [];
  List<ColorModel> allColors = [];
  List<Technician> technicians = [];
  List<MinifiedCustomerModel> customers = [];

  int? customerId;
  String? customerName;

  TypeBrandModel? selectedType;
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
    await Future.wait([
      fetchTypesBrandsModels(),
      fetchColors(),
      fetchTechnicians(),
    ]);
    if (customerId == null) isCustomerSelected = false;
    isLoading = false;
    notifyListeners();
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
        final customersPage = await _customerService.searchCustomers(filter);
        customers = customersPage.content;
        notifyListeners();
      } catch (e) {
        SnackBarUtil().showError('Erro ao buscar o cliente');
        customers = [];
        notifyListeners();
      }
    });
  }

  Future<void> fetchTypesBrandsModels() async {
    try {
      typesBrandsModels = await _typeBrandModelService.getTypesBrandsModels();
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar tipos, marcas e modelos');
    }
  }

  Future<int?> createDevice() async {
    try {
      isCreatingDevice = true;
      notifyListeners();

      inputDevice = inputDevice.copyWith(
        customerId: customerId,
      );

      final deviceCustomer =
          await _deviceCustomerService.createDeviceCustomer(inputDevice);

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

  void setSelectedType(int? id) {
    if (id == null) {
      selectedType = null;
      selectedBrand = null;
      selectedModel = null;
      notifyListeners();
      return;
    }
    selectedType = typesBrandsModels.firstWhere((type) => type.idType == id);
    notifyListeners();
  }

  void setSelectedBrand(int? id) {
    if (id == null) {
      selectedBrand = null;
      selectedModel = null;
      notifyListeners();
      return;
    }
    selectedBrand =
        selectedType?.brands.firstWhere((brand) => brand.idBrand == id);
    notifyListeners();
  }

  void setSelectedModel(int? id) {
    if (id == null) {
      selectedModel = null;
      notifyListeners();
      return;
    }
    selectedModel =
        selectedBrand?.models.firstWhere((model) => model.idModel == id);
    notifyListeners();
  }

  void addColor(ColorModel color) {
    if (color.idColor == null) {
      final findedColor =
          allColors.firstWhereOrNull((c) => c.color == color.color);
      selectedColors = [...selectedColors, (findedColor ?? color)];
      notifyListeners();
      return;
    }
    if (!selectedColors.any((c) => c.idColor == color.idColor)) {
      selectedColors = [...selectedColors, color];
    }
    notifyListeners();
  }

  void removeColor(ColorModel color) {
    selectedColors =
        selectedColors.where((c) => c.idColor != color.idColor).toList();
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
