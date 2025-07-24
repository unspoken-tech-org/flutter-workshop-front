import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/cpf_formatter.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';
import 'package:flutter_workshop_front/models/customer/customer_model.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/controllers/customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_detail/widgets/edit_action_buttons_view.dart';
import 'package:flutter_workshop_front/utils/cpf_utils.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/utils/validators/cpf_validator.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/secondary_phone_form_field.dart';
import 'package:flutter_workshop_front/widgets/shared/secondary_phones_widget.dart';

class CustomerDetailForm extends StatefulWidget {
  final CustomerModel customer;
  final CustomerDetailController controller;
  final ValueNotifier<bool> isEditingNotifier;

  const CustomerDetailForm({
    super.key,
    required this.customer,
    required this.controller,
    required this.isEditingNotifier,
  });

  @override
  State<CustomerDetailForm> createState() => CustomerDetailFormState();
}

class CustomerDetailFormState extends State<CustomerDetailForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<SecondaryPhoneFormField> _secondaryPhoneFields = [];

  @override
  void initState() {
    super.initState();
    _initSecondaryPhoneFields();
  }

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    super.dispose();
  }

  void _initSecondaryPhoneFields() {
    widget.customer.phones.where((phone) => !phone.main).forEach((phone) {
      _secondaryPhoneFields.add(
        SecondaryPhoneFormField(
          name: phone.name,
          number: PhoneUtils.formatPhone(phone.number),
          onSaved: (value) {
            _onSaveSecondaryPhone(widget.controller, value);
          },
        ),
      );
    });
  }

  void _onSaveSecondaryPhone(
      CustomerDetailController controller, PhoneFieldParameters? value) {
    controller.updatedCustomerData = controller.updatedCustomerData.copyWith(
      phones: [
        ...controller.updatedCustomerData.phones,
        InputCustomerPhone(
          id: null,
          number: value?.number ?? '',
          name: value?.name ?? '',
          isPrimary: false,
        ),
      ],
    );
  }

  void resetForm() {
    _secondaryPhoneFields.clear();
    _initSecondaryPhoneFields();
    _formKey.currentState?.reset();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.isEditingNotifier,
          builder: (context, isEditing, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detalhes do Cliente', style: WsTextStyles.h1),
                const SizedBox(height: 16),
                if (!isEditing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          var customer = widget.customer;
                          WsNavigator.pushDeviceRegister(
                            context,
                            customerId: customer.customerId,
                            customerName: customer.name,
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar aparelho'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: CustomTextField(
                        fieldLabel: 'Id',
                        value: widget.customer.customerId.toString(),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomDropdownButtonFormField(
                        value: widget.customer.gender.capitalizeFirst,
                        fieldLabel: 'Sexo',
                        items: const ['Masculino', 'Feminino', 'Outro'],
                        onSave: (value) {
                          widget.controller.updatedCustomerData =
                              widget.controller.updatedCustomerData.copyWith(
                            gender: value,
                          );
                        },
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
                      child: CustomTextField(
                        fieldLabel: 'Nome',
                        readOnly: !isEditing,
                        value: widget.customer.name.capitalizeAllWords,
                        keyboardType: TextInputType.name,
                        onSave: (value) {
                          widget.controller.updatedCustomerData =
                              widget.controller.updatedCustomerData.copyWith(
                            name: value,
                          );
                        },
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
                      child: CustomTextField(
                        fieldLabel: 'CPF',
                        readOnly: !isEditing,
                        value: CpfUtils.formatCpf(widget.customer.cpf),
                        inputFormatters: [CpfFormatter()],
                        keyboardType: TextInputType.number,
                        onSave: (value) {
                          widget.controller.updatedCustomerData =
                              widget.controller.updatedCustomerData.copyWith(
                            cpf: value,
                          );
                        },
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
                      child: CustomTextField(
                        fieldLabel: 'Telefone Principal',
                        value: PhoneUtils.formatPhone(
                          widget.customer.phones
                              .firstWhere((phone) => phone.main)
                              .number,
                        ),
                        readOnly: !isEditing,
                        inputFormatters: [PhoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                        onSave: (value) {
                          widget.controller.updatedCustomerData =
                              widget.controller.updatedCustomerData.copyWith(
                            phones: [
                              ...widget.controller.updatedCustomerData.phones,
                              InputCustomerPhone(
                                id: widget.customer.phones
                                    .firstWhere((phone) => phone.main)
                                    .idCellphone,
                                number: value ?? '',
                                isPrimary: true,
                              ),
                            ],
                          );
                        },
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
                      child: CustomTextField(
                        fieldLabel: 'Email',
                        readOnly: !isEditing,
                        value: widget.customer.email,
                        onSave: (value) {
                          widget.controller.updatedCustomerData =
                              widget.controller.updatedCustomerData.copyWith(
                            email: value,
                          );
                        },
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
                ValueListenableBuilder<CustomerModel?>(
                  valueListenable: widget.controller.customer,
                  builder: (context, customer, _) {
                    return SecondaryPhonesWidget(
                      key: ValueKey(customer?.phones.hashCode),
                      initialPhones: customer?.phones
                          .where((phone) => !phone.main)
                          .map((phone) => PhoneFieldParameters(
                                name: phone.name,
                                number: phone.number,
                              ))
                          .toList(),
                      isEditing: isEditing,
                      onSaved: (value) {
                        _onSaveSecondaryPhone(widget.controller, value);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                EditActionButtons(
                  customerId: widget.customer.customerId,
                  isEditingNotifier: widget.isEditingNotifier,
                  onCancel: () {
                    resetForm();
                    widget.isEditingNotifier.value = false;
                  },
                  onSave: () async {
                    if (!(_formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    widget.controller.updatedCustomerData =
                        InputCustomer.empty();

                    _formKey.currentState?.save();

                    final success = await widget.controller.updateCustomer(
                      widget.customer.customerId,
                    );
                    if (success) {
                      widget.isEditingNotifier.value = false;
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
