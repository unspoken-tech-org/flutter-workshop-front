import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/type_brand_model_autocomplete_form_field.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/multi_select_color_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:provider/provider.dart';

class DeviceDetailsRegisterForm extends StatefulWidget {
  const DeviceDetailsRegisterForm({super.key});

  @override
  State<DeviceDetailsRegisterForm> createState() =>
      _DeviceDetailsRegisterFormState();
}

class _DeviceDetailsRegisterFormState extends State<DeviceDetailsRegisterForm> {
  late DeviceRegisterController controller;
  // Controllers for text fields
  final _deviceTypeController = TextEditingController();
  final _deviceBrandController = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _deviceBudgetFeeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = context.read<DeviceRegisterController>();
  }

  @override
  void dispose() {
    _deviceTypeController.dispose();
    _deviceBrandController.dispose();
    _deviceModelController.dispose();
    _deviceBudgetFeeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            spacing: 8,
            children: [
              Icon(Icons.settings_outlined),
              Text(
                'Detalhes do Aparelho',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Expanded(
                child: TypeBrandModelAutocompleteFormField<Type>(
                  controller: _deviceTypeController,
                  headerLabelText: 'Tipo Aparelho',
                  hintText: 'Ex: Lavadora, Microondas, Ventilador',
                  searchFn: (query) => controller.searchTypes(query),
                  createFn: (name) => controller.createType(name),
                  getName: (item) => item.type,
                  getId: (item) => item.idType,
                  onAccept: (type) {
                    controller.setSelectedType(type);
                  },
                  onClear: () {
                    controller.setSelectedType(null);
                    _deviceBrandController.clear();
                    _deviceModelController.clear();
                  },
                  fieldValidator: (String? value) {
                    if (controller.selectedType == null) {
                      return 'Selecione um tipo de aparelho';
                    }
                    return null;
                  },
                  createLabel: 'Criar novo tipo',
                  createSuccessMessage: 'Tipo criado com sucesso',
                ),
              ),
              Selector<DeviceRegisterController, Type?>(
                selector: (context, controller) => controller.selectedType,
                builder: (context, selectedType, child) {
                  return Expanded(
                    child: TypeBrandModelAutocompleteFormField<Brand>(
                      controller: _deviceBrandController,
                      headerLabelText: 'Marca Aparelho',
                      hintText: 'Ex: LG, Samsung, Panasonic',
                      enabled: selectedType != null,
                      searchFn: (query) => controller.searchBrands(query),
                      createFn: (name) => controller.createBrand(name),
                      getName: (item) => item.brand,
                      getId: (item) => item.idBrand,
                      onAccept: (brand) {
                        controller.setSelectedBrand(brand);
                      },
                      onClear: () {
                        controller.setSelectedBrand(null);
                        _deviceModelController.clear();
                      },
                      fieldValidator: (String? value) {
                        if (controller.selectedBrand == null) {
                          return 'Selecione uma marca';
                        }
                        return null;
                      },
                      createLabel: 'Criar nova marca',
                      createSuccessMessage: 'Marca criada com sucesso',
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Selector<DeviceRegisterController, Brand?>(
                selector: (context, controller) => controller.selectedBrand,
                builder: (context, selectedBrand, child) {
                  return Expanded(
                    child: TypeBrandModelAutocompleteFormField<Model>(
                      controller: _deviceModelController,
                      headerLabelText: 'Modelo Aparelho',
                      hintText: 'Ex: 1234567890',
                      enabled: selectedBrand != null,
                      searchFn: (query) => controller.searchModels(query),
                      createFn: (name) => controller.createModel(name),
                      getName: (item) => item.model,
                      getId: (item) => item.idModel,
                      onAccept: (model) {
                        controller.setSelectedModel(model);
                      },
                      onClear: () {
                        controller.setSelectedModel(null);
                      },
                      fieldValidator: (String? value) {
                        if (controller.selectedModel == null) {
                          return 'Selecione um modelo';
                        }
                        return null;
                      },
                      createLabel: 'Criar novo modelo',
                      createSuccessMessage: 'Modelo criado com sucesso',
                    ),
                  );
                },
              ),
              Expanded(
                child: CustomTextField(
                  controller: _deviceBudgetFeeController,
                  headerLabel: 'Valor Orçamento (Opcional)',
                  hintText: 'Ex: 100,00',
                  inputFormatters: [CurrencyInputFormatter()],
                  onSave: (value) {
                    if (value == null || value.isEmpty) return;
                    final budgetFee = double.parse(
                      value.replaceAll('R\$', '').replaceAll(',', '.'),
                    );
                    controller.inputDevice = controller.inputDevice.copyWith(
                      budgetFee: budgetFee,
                    );
                  },
                ),
              ),
            ],
          ),
          Selector<DeviceRegisterController, List<ColorModel>>(
            selector: (context, controller) => controller.selectedColors,
            builder: (context, selectedColors, child) {
              return MultiSelectColorField(
                headerLabelText: 'Cores',
                hintText: 'Ex: Azul, Branco, Preto',
                suggestions: controller.allColors,
                selectedColors: selectedColors,
                maxSelections: 4,
                onCreateColor: (name) async {
                  return ColorModel(idColor: null, color: name);
                },
                onColorAdded: (color) => controller.addColor(color),
                onColorRemoved: (color) => controller.removeColor(color),
                fieldValidator: (colors) {
                  if (colors.isEmpty) {
                    return 'Selecione ao menos uma cor';
                  }
                  return null;
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
