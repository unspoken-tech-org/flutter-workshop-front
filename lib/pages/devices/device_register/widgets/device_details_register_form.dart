import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/autocomplete_form_field.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/widgets/selected_colors_form_field.dart';
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
  final _deviceBudgetValueController = TextEditingController();
  final _deviceColorsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = context.read<DeviceRegisterController>();
  }

  List<ITypeBrandModelColor> _getTypeSuggestions() {
    var types = controller.typesBrandsModels;
    return types;
  }

  List<ITypeBrandModelColor> _getBrandSuggestions() {
    var brands = controller.selectedType?.brands ?? [];
    return brands;
  }

  List<ITypeBrandModelColor> _getModelSuggestions() {
    var models = controller.selectedBrand?.models ?? [];
    return models;
  }

  List<ColorModel> _getColorSuggestions() {
    return controller.allColors;
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
                child: AutocompleteFormField(
                  controller: _deviceTypeController,
                  headerLabelText: 'Tipo Aparelho',
                  hintText: 'Ex: Lavadora, Microondas, Ventilador',
                  suggestions: _getTypeSuggestions(),
                  onAccept: (id) {
                    controller.setSelectedType(id);
                  },
                  onClear: () {
                    controller.setSelectedType(null);
                    _deviceBrandController.clear();
                    _deviceModelController.clear();
                  },
                  onSave: (name) {
                    controller.inputDevice = controller.inputDevice.copyWith(
                      typeBrandModel: controller.inputDevice.typeBrandModel
                          ?.copyWith(type: name),
                    );
                  },
                  fieldValidator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione um tipo de aparelho ou digite um novo';
                    }
                    return null;
                  },
                ),
              ),
              Selector<DeviceRegisterController, TypeBrandModel?>(
                selector: (context, controller) => controller.selectedType,
                builder: (context, selectedType, child) {
                  return Expanded(
                    child: AutocompleteFormField(
                      controller: _deviceBrandController,
                      headerLabelText: 'Marca Aparelho',
                      hintText: 'Ex: LG, Samsung, Panasonic',
                      suggestions: _getBrandSuggestions(),
                      onAccept: (id) {
                        controller.setSelectedBrand(id);
                      },
                      onSave: (name) {
                        controller.inputDevice =
                            controller.inputDevice.copyWith(
                          typeBrandModel: controller.inputDevice.typeBrandModel
                              ?.copyWith(brand: name),
                        );
                      },
                      onClear: () {
                        controller.setSelectedBrand(null);
                        _deviceModelController.clear();
                      },
                      fieldValidator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione uma marca ou digite uma nova';
                        }
                        return null;
                      },
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
                    child: AutocompleteFormField(
                      controller: _deviceModelController,
                      headerLabelText: 'Modelo Aparelho',
                      hintText: 'Ex: 1234567890',
                      suggestions: _getModelSuggestions(),
                      onAccept: (id) {
                        controller.setSelectedModel(id);
                      },
                      onClear: () {
                        controller.setSelectedModel(null);
                      },
                      onSave: (name) {
                        controller.inputDevice =
                            controller.inputDevice.copyWith(
                          typeBrandModel: controller.inputDevice.typeBrandModel
                              ?.copyWith(model: name),
                        );
                      },
                      fieldValidator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecione um modelo ou digite um novo';
                        }
                        return null;
                      },
                    ),
                  );
                },
              ),
              Expanded(
                child: CustomTextField(
                  controller: _deviceBudgetValueController,
                  headerLabel: 'Valor Orçamento (Opcional)',
                  hintText: 'Ex: 100,00',
                  inputFormatters: [
                    CurrencyInputFormatter(),
                  ],
                  onSave: (value) {
                    if (value == null || value.isEmpty) return;
                    final budgetValue = double.parse(
                        value.replaceAll('R\$', '').replaceAll(',', '.'));
                    controller.inputDevice = controller.inputDevice.copyWith(
                      budgetValue: budgetValue,
                    );
                  },
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Expanded(
                child: AutocompleteFormField(
                  controller: _deviceColorsController,
                  headerLabelText: 'Cores',
                  hintText: 'Ex: Azul, Branco, Preto',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                  ],
                  suggestions: _getColorSuggestions(),
                  suffixIcon: Icon(
                    Icons.arrow_circle_right_outlined,
                    size: 20,
                    color: Colors.grey.shade600,
                    weight: 100,
                  ),
                  suffixIconAction: (name) {
                    controller.addColor(ColorModel(idColor: null, color: name));
                    setState(() {});
                  },
                  onAccept: (id) {
                    if (id == null) return;
                    final color =
                        controller.allColors.firstWhere((c) => c.idColor == id);
                    controller.addColor(color);
                    _deviceColorsController.clear();
                    setState(() {});
                  },
                  onSave: (name) {
                    controller.inputDevice = controller.inputDevice.copyWith(
                      colors: controller.selectedColors
                          .map((c) => c.color)
                          .toList(),
                    );
                  },
                  onSubmit: (id, name) {
                    controller.addColor(ColorModel(idColor: null, color: name));
                    _deviceColorsController.clear();
                    setState(() {});
                  },
                ),
              ),
              const Expanded(
                child: SelectedColorsFormField(
                  headerLabel: 'Cores selecionadas',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
