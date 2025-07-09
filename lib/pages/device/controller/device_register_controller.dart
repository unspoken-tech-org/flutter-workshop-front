import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/services/color/color_service.dart';
import 'package:flutter_workshop_front/services/device_data/device_customer_service.dart';
import 'package:flutter_workshop_front/services/technician/technician_service.dart';
import 'package:flutter_workshop_front/services/types_brands_models/type_brand_model_service.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';

class DeviceRegisterController {
  final TypeBrandModelService _typeBrandModelService;
  final ColorService _colorService;
  final DeviceCustomerService _deviceCustomerService;
  final TechnicianService _technicianService;

  DeviceRegisterController(
    this._typeBrandModelService,
    this._colorService,
    this._deviceCustomerService,
    this._technicianService,
  );

  final ValueNotifier<List<TypeBrandModel>> typesBrandsModels =
      ValueNotifier([]);
  final ValueNotifier<List<ColorModel>> allColors = ValueNotifier([]);
  final ValueNotifier<List<Technician>> technicians = ValueNotifier([]);

  late final int customerId;
  late final String customerName;

  final ValueNotifier<TypeBrandModel?> selectedType = ValueNotifier(null);
  final ValueNotifier<Brand?> selectedBrand = ValueNotifier(null);
  final ValueNotifier<Model?> selectedModel = ValueNotifier(null);
  final ValueNotifier<List<ColorModel>> selectedColors = ValueNotifier([]);

  final ValueNotifier<bool> isLoading = ValueNotifier(false);
  final ValueNotifier<bool> isCreatingDevice = ValueNotifier(false);

  Future<void> init(int customerId, String customerName) async {
    this.customerId = customerId;
    this.customerName = customerName;
    isLoading.value = true;
    await Future.wait([
      fetchTypesBrandsModels(),
      fetchColors(),
      fetchTechnicians(),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchColors() async {
    try {
      final colors = await _colorService.getColors();
      allColors.value = colors;
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar as cores');
    }
  }

  Future<void> fetchTechnicians() async {
    try {
      final technicians = await _technicianService.getTechnicians();
      this.technicians.value = technicians;
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar os técnicos');
    }
  }

  Future<void> fetchTypesBrandsModels() async {
    try {
      typesBrandsModels.value =
          await _typeBrandModelService.getTypesBrandsModels();
    } catch (e) {
      SnackBarUtil().showError('Erro ao buscar tipos, marcas e modelos');
    }
  }

  Future<int?> createDevice(DeviceInput device) async {
    try {
      isCreatingDevice.value = true;
      final deviceCustomer =
          await _deviceCustomerService.createDeviceCustomer(device);

      SnackBarUtil().showSuccess('Dispositivo criado com sucesso');
      return deviceCustomer.deviceId;
    } catch (e) {
      SnackBarUtil().showError('Erro ao criar dispositivo');
      return null;
    } finally {
      isCreatingDevice.value = false;
    }
  }

  void setSelectedType(int? id) {
    if (id == null) {
      selectedType.value = null;
      selectedBrand.value = null;
      selectedModel.value = null;
      return;
    }
    selectedType.value =
        typesBrandsModels.value.firstWhere((type) => type.idType == id);
  }

  void setSelectedBrand(int? id) {
    if (id == null) {
      selectedBrand.value = null;
      selectedModel.value = null;
      return;
    }
    selectedBrand.value =
        selectedType.value?.brands.firstWhere((brand) => brand.idBrand == id);
  }

  void setSelectedModel(int? id) {
    if (id == null) {
      selectedModel.value = null;
      return;
    }
    selectedModel.value =
        selectedBrand.value?.models.firstWhere((model) => model.idModel == id);
  }

  void addColor(ColorModel color) {
    if (color.idColor == null) {
      final findedColor =
          allColors.value.firstWhereOrNull((c) => c.color == color.color);
      selectedColors.value = [...selectedColors.value, (findedColor ?? color)];
      return;
    }
    if (!selectedColors.value.any((c) => c.idColor == color.idColor)) {
      selectedColors.value = [...selectedColors.value, color];
    }
  }

  void removeColor(ColorModel color) {
    selectedColors.value =
        selectedColors.value.where((c) => c.idColor != color.idColor).toList();
  }
}
