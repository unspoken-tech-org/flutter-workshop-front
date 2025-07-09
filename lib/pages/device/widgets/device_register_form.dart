import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/colors/color_model.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/device/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/controller/inherited_device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/widgets/autocomplete_form_field.dart';
import 'package:flutter_workshop_front/pages/device/widgets/customer_info_form_field.dart';
import 'package:flutter_workshop_front/pages/device/widgets/selected_colors_form_field.dart';
import 'package:flutter_workshop_front/pages/device/widgets/urgency_switch.dart';

class DeviceRegisterForm extends StatefulWidget {
  const DeviceRegisterForm({super.key});

  @override
  State<DeviceRegisterForm> createState() => _DeviceRegisterFormState();
}

class _DeviceRegisterFormState extends State<DeviceRegisterForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _problemController = TextEditingController();
  final _observationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _deviceTypeController = TextEditingController();
  final _deviceBrandController = TextEditingController();
  final _deviceModelController = TextEditingController();
  final _deviceColorsController = TextEditingController();

  // State for other form elements
  bool _isUrgent = false;
  Technician? _selectedTechnician;

  @override
  void dispose() {
    _problemController.dispose();
    _observationController.dispose();
    _budgetController.dispose();
    _deviceColorsController.dispose();
    _deviceModelController.dispose();
    _deviceTypeController.dispose();
    _deviceBrandController.dispose();
    super.dispose();
  }

  List<ITypeBrandModelColor> _getTypeSuggestions(
      DeviceRegisterController controller) {
    var types = controller.typesBrandsModels.value;
    return types;
  }

  List<ITypeBrandModelColor> _getBrandSuggestions(
      DeviceRegisterController controller) {
    var brands = controller.selectedType.value?.brands ?? [];
    return brands;
  }

  List<ITypeBrandModelColor> _getModelSuggestions(
      DeviceRegisterController controller) {
    var models = controller.selectedBrand.value?.models ?? [];
    return models;
  }

  List<Technician> _getTechnicianSuggestions(
      DeviceRegisterController controller) {
    return controller.technicians.value;
  }

  List<ColorModel> _getColorSuggestions(DeviceRegisterController controller) {
    return controller.allColors.value;
  }

  DeviceInput _getDeviceInput(DeviceRegisterController controller) {
    final budgetText = _budgetController.text.replaceAll(RegExp(r'[^\d]'), '');
    final budgetValue = budgetText.isNotEmpty ? double.parse(budgetText) : null;

    return DeviceInput(
      customerId: controller.customerId,
      problem: _problemController.text,
      observation: _observationController.text,
      budgetValue: budgetValue,
      hasUrgency: _isUrgent,
      technicianId: _selectedTechnician?.id,
      typeBrandModel: TypeBrandModelInput(
        type: controller.selectedType.value?.type ?? _deviceTypeController.text,
        brand: controller.selectedBrand.value?.brand ??
            _deviceBrandController.text,
        model: controller.selectedModel.value?.model ??
            _deviceModelController.text,
      ),
      colors: controller.selectedColors.value.map((c) => c.color).toList(),
    );
  }

  Future<void> _createDevice(
      BuildContext context, DeviceRegisterController controller) async {
    if (_formKey.currentState!.validate()) {
      final deviceInput = _getDeviceInput(controller);
      int? deviceId = await controller.createDevice(deviceInput);
      if (deviceId != null && context.mounted) {
        WsNavigator.pushDevice(context, deviceId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceRegisterController.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastro de Aparelho',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            CustomerInfoFormField(
              customerId: controller.customerId,
              customerName: controller.customerName,
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 3,
              controller: _problemController,
              decoration: const InputDecoration(
                labelText: 'Problema',
                border: OutlineInputBorder(),
              ),
              validator: (String? value) {
                if (value == null || value.isEmpty) {
                  return 'O campo problema é obrigatório';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observationController,
              decoration: const InputDecoration(
                labelText: 'Observações (Opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  child: AutocompleteFormField(
                    controller: _deviceTypeController,
                    labelText: 'Tipo Aparelho',
                    suggestions: _getTypeSuggestions(controller),
                    onAccept: (id) {
                      controller.setSelectedType(id);
                    },
                    onClear: () {
                      controller.setSelectedType(null);
                      _deviceBrandController.clear();
                      _deviceModelController.clear();
                    },
                    fieldValidator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione um tipo de aparelho ou digite um novo';
                      }
                      return null;
                    },
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: controller.selectedType,
                  builder: (context, _, __) {
                    return Expanded(
                      child: AutocompleteFormField(
                        controller: _deviceBrandController,
                        labelText: 'Marca Aparelho',
                        suggestions: _getBrandSuggestions(controller),
                        onAccept: (id) {
                          controller.setSelectedBrand(id);
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
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                ValueListenableBuilder(
                  valueListenable: controller.selectedBrand,
                  builder: (context, _, __) {
                    return Expanded(
                      child: AutocompleteFormField(
                        controller: _deviceModelController,
                        labelText: 'Modelo Aparelho',
                        suggestions: _getModelSuggestions(controller),
                        onAccept: (id) {
                          controller.setSelectedModel(id);
                        },
                        onClear: () {
                          controller.setSelectedModel(null);
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
                  child: TextFormField(
                    controller: _budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      CurrencyInputFormatter(),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Valor Orçamento (Opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                Expanded(
                  child: AutocompleteFormField(
                    controller: _deviceColorsController,
                    labelText: 'Cores',
                    tooltipText:
                        'Selecione uma cor existente ou digite uma nova e pressione enter para adicionar',
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    suggestions: _getColorSuggestions(controller),
                    onAccept: (id) {
                      if (id == null) return;
                      final color = controller.allColors.value
                          .firstWhere((c) => c.idColor == id);
                      controller.addColor(color);
                      _deviceColorsController.clear();
                      setState(() {});
                    },
                    onSubmit: (id, name) {
                      controller
                          .addColor(ColorModel(idColor: null, color: name));
                      _deviceColorsController.clear();
                      setState(() {});
                    },
                  ),
                ),
                const Expanded(child: SelectedColorsFormField()),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Technician>(
              value: _selectedTechnician,
              items: _getTechnicianSuggestions(controller)
                  .map((technician) => DropdownMenuItem(
                      value: technician,
                      child: Text(technician.name.capitalizeAll)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTechnician = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Técnico Responsável (Opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 180,
              child: UrgencySwitch(
                value: _isUrgent,
                onChanged: (value) {
                  setState(() {
                    _isUrgent = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder(
                valueListenable: controller.isCreatingDevice,
                builder: (context, isCreatingDevice, _) {
                  return ElevatedButton(
                    onPressed: isCreatingDevice
                        ? null
                        : () => _createDevice(context, controller),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isCreatingDevice
                        ? const CircularProgressIndicator.adaptive(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          )
                        : const Text('Cadastrar Aparelho'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
