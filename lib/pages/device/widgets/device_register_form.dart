import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/colors/color_input.dart';
import 'package:flutter_workshop_front/models/device/device_input.dart';
import 'package:flutter_workshop_front/models/types_brands_models/type_brand_model_input.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/pages/device/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/controller/inherited_device_register_controller.dart';
import 'package:flutter_workshop_front/pages/device/widgets/autocomplete_form_field.dart';
import 'package:flutter_workshop_front/pages/device/widgets/customer_info.dart';
import 'package:flutter_workshop_front/pages/device/widgets/urgency_switch.dart';

class DeviceRegisterForm extends StatefulWidget {
  const DeviceRegisterForm({super.key});

  @override
  State<DeviceRegisterForm> createState() => _DeviceRegisterFormState();
}

class _DeviceRegisterFormState extends State<DeviceRegisterForm> {
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
  String? _selectedTechnician;

  // Mock data for dropdowns and suggestions
  final List<String> _technicians = ['João', 'Maria', 'José'];

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

  List<ITypeBrandModel> _getTypeSuggestions(
      DeviceRegisterController controller) {
    var types = controller.typesBrandsModels.value;
    return types;
  }

  List<ITypeBrandModel> _getBrandSuggestions(
      DeviceRegisterController controller) {
    var brands = controller.selectedType.value?.brands ?? [];
    return brands;
  }

  List<ITypeBrandModel> _getModelSuggestions(
      DeviceRegisterController controller) {
    var models = controller.selectedBrand.value?.models ?? [];
    return models;
  }

  DeviceInput _getDeviceInput(DeviceRegisterController controller) {
    return DeviceInput(
      customerId: controller.customerId,
      problem: _problemController.text,
      observation: _observationController.text,
      typeBrandModel: TypeBrandModelInput(
        type: TypeInput(
            idType: controller.selectedType.value?.idType,
            type: controller.selectedType.value?.type ??
                _deviceTypeController.text),
        brand: BrandInput(
            idBrand: controller.selectedBrand.value?.idBrand,
            brand: controller.selectedBrand.value?.brand ??
                _deviceBrandController.text),
        model: ModelInput(
            idModel: controller.selectedModel.value?.idModel,
            model: controller.selectedModel.value?.model ??
                _deviceModelController.text),
      ),
      color: ColorInput(
          idColor: controller.selectedColor.value?.idColor,
          color: controller.selectedColor.value?.color ??
              _deviceColorsController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceRegisterController.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cadastro de Aparelho',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 32),
          CustomerInfo(
            customerId: controller.customerId,
            customerName: controller.customerName,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _problemController,
            decoration: const InputDecoration(
              labelText: 'Problema',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
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
                ),
              ),
              const SizedBox(width: 16),
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
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
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
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _budgetController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor Orçamento (Opcional)',
                    border: OutlineInputBorder(),
                    prefixText: 'R\$ ',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AutocompleteFormField(
                  controller: _deviceColorsController,
                  labelText: 'Cores',
                  suggestions: const [],
                  onAccept: (id) {},
                  onClear: () {},
                ),
              ),
              const SizedBox(width: 16),
              const SelectedColors(),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTechnician,
            items: _technicians
                .map((label) => DropdownMenuItem(
                      value: label,
                      child: Text(label),
                    ))
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
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement save logic
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Cadastrar Aparelho'),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectedColors extends StatelessWidget {
  const SelectedColors({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
