import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/cpf_formatter.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/customer_detail/inherited_customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customer_detail/customer_detail_header.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customer_detail/edit_action_buttons_view.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/secondary_phone_fields.dart';
import 'package:flutter_workshop_front/utils/validators/cpf_validator.dart';

class CustomerDetailForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final CustomerModel customer;
  final ValueNotifier<bool> isEditingNotifier;

  const CustomerDetailForm({
    super.key,
    required this.formKey,
    required this.customer,
    required this.isEditingNotifier,
  });

  @override
  State<CustomerDetailForm> createState() => CustomerDetailFormState();
}

class CustomerDetailFormState extends State<CustomerDetailForm> {
  // Controllers
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _cpfController;
  late final TextEditingController _emailController;
  late final TextEditingController _primaryPhoneController;
  // Formatters
  final PhoneNumberFormatter _phoneNumberFormatter = PhoneNumberFormatter();
  final CpfFormatter _cpfFormatter = CpfFormatter();

  int? _primaryPhoneId;
  String? _selectedGender;
  final List<Map<String, dynamic>> _secondaryPhoneControllers = [];

  @override
  void initState() {
    super.initState();
    _idController =
        TextEditingController(text: widget.customer.customerId.toString());
    _nameController = TextEditingController(text: widget.customer.name);
    _emailController = TextEditingController(text: widget.customer.email);
    _selectedGender = widget.customer.gender.capitalizeFirst;
    String formattedCpf = _formatField(_cpfFormatter, widget.customer.cpf);
    _cpfController = TextEditingController(text: formattedCpf);

    _primaryPhoneController = TextEditingController();
    for (var phone in widget.customer.phones) {
      String formattedPhone = _formatField(_phoneNumberFormatter, phone.number);
      if (phone.main) {
        _primaryPhoneId = phone.idCellphone;
        _primaryPhoneController.text = formattedPhone;
      } else {
        _secondaryPhoneControllers.add({
          'id': phone.idCellphone,
          'name': TextEditingController(text: phone.name),
          'number': TextEditingController(text: formattedPhone),
        });
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _primaryPhoneController.dispose();
    for (var controllerMap in _secondaryPhoneControllers) {
      (controllerMap['name'] as TextEditingController?)?.dispose();
      (controllerMap['number'] as TextEditingController?)?.dispose();
    }
    super.dispose();
  }

  String _formatField<T extends TextInputFormatter>(T formatter, String value) {
    return formatter
        .formatEditUpdate(
          TextEditingValue(text: value),
          TextEditingValue(text: value),
        )
        .text;
  }

  void resetForm() {
    setState(() {
      _nameController.text = widget.customer.name;
      _cpfController.text = _formatField(_cpfFormatter, widget.customer.cpf);
      _emailController.text = widget.customer.email ?? '';
      _selectedGender = widget.customer.gender.capitalizeFirst;

      _secondaryPhoneControllers.clear();
      for (var phone in widget.customer.phones) {
        final formattedPhone =
            _formatField(_phoneNumberFormatter, phone.number);
        if (phone.main) {
          _primaryPhoneController.text = formattedPhone;
          _primaryPhoneId = phone.idCellphone;
        } else {
          _secondaryPhoneControllers.add({
            'id': phone.idCellphone,
            'name': TextEditingController(text: phone.name),
            'number': TextEditingController(text: formattedPhone),
          });
        }
      }
    });
  }

  InputCustomer getInput() {
    final phones = _secondaryPhoneControllers.map((controllerMap) {
      return InputCustomerPhone(
        id: controllerMap['id'],
        number: (controllerMap['number'] as TextEditingController).text,
        name: (controllerMap['name'] as TextEditingController).text,
        isPrimary: false,
      );
    }).toList();

    phones.add(InputCustomerPhone(
      id: _primaryPhoneId,
      number: _primaryPhoneController.text,
      isPrimary: true,
    ));

    return InputCustomer(
      name: _nameController.text,
      cpf: _cpfController.text.replaceAll(RegExp(r'\D'), ''),
      email: _emailController.text,
      gender: _selectedGender,
      phones: phones,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedCustomerDetailController.of(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: widget.formKey,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.isEditingNotifier,
          builder: (context, isEditing, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomerDetailHeader(),
                const SizedBox(height: 32),
                if (!isEditing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          var customer = widget.customer;
                          WsNavigator.pushDeviceRegister(
                            context,
                            customer.customerId,
                            customer.name,
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar aparelho'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: TextFormField(
                        controller: _idController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Id',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        items: ['Masculino', 'Feminino', 'Outro']
                            .map((label) => DropdownMenuItem(
                                  value: label,
                                  child: Text(label),
                                ))
                            .toList(),
                        onChanged: isEditing
                            ? (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              }
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Sexo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione o sexo';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        controller: _nameController,
                        readOnly: !isEditing,
                        keyboardType: TextInputType.name,
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira um nome';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 1,
                      child: TextFormField(
                        controller: _cpfController,
                        readOnly: !isEditing,
                        inputFormatters: [_cpfFormatter],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira um CPF';
                          }
                          if (!CpfValidator.isValid(value)) {
                            return 'CPF inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 1,
                      child: TextFormField(
                        controller: _primaryPhoneController,
                        readOnly: !isEditing,
                        inputFormatters: [PhoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefone Principal',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'O telefone principal é obrigatório';
                          }
                          final int digitCount =
                              value.replaceAll(RegExp(r'\D'), '').length;
                          if (digitCount < 10) {
                            return 'Telefone incompleto';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 1,
                      child: TextFormField(
                        controller: _emailController,
                        readOnly: !isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          if (!value.contains('@')) {
                            return 'O email é inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SecondaryPhoneFields(
                  controllers: _secondaryPhoneControllers,
                  isEditing: isEditing,
                  onRemoveController: (index) {
                    setState(() {
                      (_secondaryPhoneControllers[index]['name']
                              as TextEditingController?)
                          ?.dispose();
                      (_secondaryPhoneControllers[index]['number']
                              as TextEditingController?)
                          ?.dispose();
                      _secondaryPhoneControllers.removeAt(index);
                    });
                  },
                ),
                if (isEditing && _secondaryPhoneControllers.length < 3)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _secondaryPhoneControllers.add({
                          'id': null,
                          'name': TextEditingController(),
                          'number': TextEditingController(),
                        });
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Adicionar telefone secundário'),
                  ),
                const SizedBox(height: 16),
                EditActionButtons(
                  onCancel: () {
                    resetForm();
                    widget.isEditingNotifier.value = false;
                  },
                  onSave: () async {
                    if (!(widget.formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final input = getInput();
                    final success = await controller.updateCustomer(
                      widget.customer.customerId,
                      input,
                    );
                    if (success) {
                      widget.isEditingNotifier.value = false;
                    }
                  },
                  customerId: widget.customer.customerId,
                  isEditingNotifier: widget.isEditingNotifier,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
