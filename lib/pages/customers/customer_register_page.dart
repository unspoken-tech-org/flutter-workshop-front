import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/cpf_formatter.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/create_customer/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/create_customer/inherited_create_customer_controller.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customer_registration_header.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/secondary_phone_fields.dart';
import 'package:flutter_workshop_front/repositories/customer/customer_remote_data_source.dart';
import 'package:flutter_workshop_front/utils/validators/cpf_validator.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';

class CustomerRegisterPage extends StatefulWidget {
  static const String route = 'customer_register';

  const CustomerRegisterPage({super.key});

  @override
  State<CustomerRegisterPage> createState() => _CustomerRegisterPageState();
}

class _CustomerRegisterPageState extends State<CustomerRegisterPage> {
  final controller = CustomerRegisterController(CustomerRemoteDataSource());

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return InheritedCreateCustomerController(
      controller: controller,
      child: WsScaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            width: width * 0.5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CustomerRegisterForm(),
          ),
        ),
      ),
    );
  }
}

class CustomerRegisterForm extends StatefulWidget {
  const CustomerRegisterForm({super.key});

  @override
  State<CustomerRegisterForm> createState() => _CustomerRegisterFormState();
}

class _CustomerRegisterFormState extends State<CustomerRegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _primaryPhoneController = TextEditingController();
  final List<Map<String, TextEditingController>>
      _secondaryPhoneAndNameControllers = [];

  String? _name;
  String? _cpf;
  String? _email;
  String? _selectedGender;

  @override
  void dispose() {
    _formKey.currentState?.dispose();

    for (var controllersMap in _secondaryPhoneAndNameControllers) {
      controllersMap['number']?.dispose();
      controllersMap['name']?.dispose();
    }
    super.dispose();
  }

  void _removeSecondaryPhoneField(int index) {
    setState(() {
      var controller = _secondaryPhoneAndNameControllers[index];
      controller['number']?.dispose();
      controller['name']?.dispose();
      _secondaryPhoneAndNameControllers.removeAt(index);
    });
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _primaryPhoneController.clear();
    _secondaryPhoneAndNameControllers.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedCreateCustomerController.of(context);
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const CustomerRegistrationHeader(),
            const SizedBox(height: 32),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o nome';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _name = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'CPF',
                border: OutlineInputBorder(),
              ),
              inputFormatters: [CpfFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o CPF';
                }
                if (!CpfValidator.isValid(value)) {
                  return 'CPF inválido';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _cpf = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Sexo',
                border: OutlineInputBorder(),
              ),
              value: _selectedGender,
              items: ['Masculino', 'Feminino', 'Outro']
                  .map((label) => DropdownMenuItem(
                        value: label,
                        child: Text(label),
                      ))
                  .toList(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione o sexo';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Email (opcional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null;
                }
                if (!value.contains('@')) {
                  return 'Por favor, insira um email válido';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {
                  _email = value;
                });
              },
            ),
            const SizedBox(height: 16),
            PrimaryPhoneField(controller: _primaryPhoneController),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: SecondaryPhoneFields(
                controllers: _secondaryPhoneAndNameControllers,
                onRemoveController: (index) {
                  _removeSecondaryPhoneField(index);
                },
              ),
            ),
            if (_secondaryPhoneAndNameControllers.length < 3)
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _secondaryPhoneAndNameControllers.add({
                          'name': TextEditingController(),
                          'number': TextEditingController(),
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar telefone secundário'),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: _clearForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Limpar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      int? createdCustomerId = await controller.createCustomer(
                        InputCustomer(
                          cpf: _cpf,
                          email: _email,
                          gender: _selectedGender,
                          name: _name,
                          phones: [
                            InputCustomerPhone(
                              number: _primaryPhoneController.text,
                              isPrimary: true,
                            ),
                            ..._secondaryPhoneAndNameControllers.map(
                              (controller) => InputCustomerPhone(
                                  number: controller['number']!.text,
                                  name: controller['name']!.text),
                            )
                          ],
                        ),
                      );
                      if (createdCustomerId != null) {
                        await Future.delayed(
                            const Duration(milliseconds: 100), () {});
                        if (context.mounted) {
                          WsNavigator.pushCustomerDetail(
                              context, createdCustomerId);
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750a4),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Cadastrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PrimaryPhoneField extends StatelessWidget {
  final TextEditingController controller;
  const PrimaryPhoneField({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Telefone Principal',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
      inputFormatters: [PhoneNumberFormatter()],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, insira o telefone';
        }
        final int digitCount = value.replaceAll(RegExp(r'\D'), '').length;
        if (digitCount < 10) {
          return 'Telefone incompleto';
        }
        return null;
      },
    );
  }
}
