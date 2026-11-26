import 'package:flutter_workshop_front/core/validators/form_validators.dart';
import 'package:collection/collection.dart';
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
import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/secondary_phone_form_field.dart';
import 'package:flutter_workshop_front/widgets/shared/secondary_phones_widget.dart';

class CustomerDetailForm extends StatefulWidget {
  final CustomerModel customer;
  final CustomerDetailController controller;

  const CustomerDetailForm({
    super.key,
    required this.customer,
    required this.controller,
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

  String? _normalizeGender(String raw) {
    switch (raw.trim().toUpperCase()) {
      case 'MALE':
      case 'MASCULINO':
      case 'M':
        return 'Masculino';
      case 'FEMALE':
      case 'FEMININO':
      case 'F':
        return 'Feminino';
      case 'OTHER':
      case 'OUTRO':
      case 'O':
        return 'Outro';
      default:
        return null;
    }
  }

  void _initSecondaryPhoneFields() {
    widget.customer.phones.where((phone) => !phone.main).forEach((phone) {
      _secondaryPhoneFields.add(
        SecondaryPhoneFormField(
          name: phone.name,
          number: BrFormat.phone(phone.number),
          onSaved: (value) {
            _onSaveSecondaryPhone(widget.controller, value);
          },
        ),
      );
    });
  }

  void _onSaveSecondaryPhone(
    CustomerDetailController controller,
    PhoneFieldParameters? value,
  ) {
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
    final isEditing = widget.controller.isEditing;
    final customer = widget.controller.customer ?? widget.customer;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalhes do Cliente', style: WsTextStyles.h1),
            const SizedBox(height: 16),
            if (!isEditing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    identifier: 'customerDetail.registerDevice',
                    child: TextButton.icon(
                      onPressed: () {
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
                    value: customer.customerId.toString(),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomDropdownButtonFormField(
                    semanticsIdentifier: 'customerDetail.gender',
                    initialValue: _normalizeGender(customer.gender),
                    fieldLabel: 'Sexo',
                    items: const ['Masculino', 'Feminino', 'Outro'],
                    onSave: (value) {
                      widget.controller.updatedCustomerData = widget
                          .controller
                          .updatedCustomerData
                          .copyWith(gender: value);
                    },
                    validator: FormValidators.required(
                      'Por favor, selecione o sexo',
                    ),
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
                    semanticsIdentifier: 'customerDetail.name',
                    fieldLabel: 'Nome',
                    readOnly: !isEditing,
                    value: customer.name.capitalizeAllWords,
                    keyboardType: TextInputType.name,
                    onSave: (value) {
                      widget.controller.updatedCustomerData = widget
                          .controller
                          .updatedCustomerData
                          .copyWith(name: value);
                    },
                    validator: FormValidators.name,
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    semanticsIdentifier: 'customerDetail.cpf',
                    fieldLabel: 'CPF',
                    readOnly: !isEditing,
                    value: BrFormat.cpf(customer.cpf),
                    inputFormatters: [CpfFormatter()],
                    keyboardType: TextInputType.number,
                    onSave: (value) {
                      widget.controller.updatedCustomerData = widget
                          .controller
                          .updatedCustomerData
                          .copyWith(cpf: value);
                    },
                    validator: FormValidators.cpf,
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
                  child: Builder(
                    builder: (context) {
                      final mainPhone =
                          customer.phones.firstWhereOrNull(
                            (phone) => phone.main,
                          ) ??
                          customer.phones.firstOrNull;
                      return CustomTextField(
                        semanticsIdentifier: 'customerDetail.mainPhone',
                        fieldLabel: 'Telefone Principal',
                        value: BrFormat.phone(mainPhone?.number ?? ''),
                        readOnly: !isEditing,
                        inputFormatters: [PhoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                        onSave: (value) {
                          widget.controller.updatedCustomerData = widget
                              .controller
                              .updatedCustomerData
                              .copyWith(
                                phones: [
                                  ...widget
                                      .controller
                                      .updatedCustomerData
                                      .phones,
                                  InputCustomerPhone(
                                    id: mainPhone?.idCellphone,
                                    number: value ?? '',
                                    isPrimary: true,
                                  ),
                                ],
                              );
                        },
                        validator: FormValidators.mainPhone,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: CustomTextField(
                    semanticsIdentifier: 'customerDetail.email',
                    fieldLabel: 'Email',
                    readOnly: !isEditing,
                    value: customer.email,
                    onSave: (value) {
                      widget.controller.updatedCustomerData = widget
                          .controller
                          .updatedCustomerData
                          .copyWith(email: value);
                    },
                    validator: FormValidators.optionalEmail,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SecondaryPhonesWidget(
              key: ValueKey(customer.phones.hashCode),
              initialPhones: customer.phones
                  .where((phone) => !phone.main)
                  .map(
                    (phone) => PhoneFieldParameters(
                      name: phone.name?.capitalizeAllWords,
                      number: phone.number,
                    ),
                  )
                  .toList(),
              isEditing: isEditing,
              onSaved: (value) {
                _onSaveSecondaryPhone(widget.controller, value);
              },
            ),
            const SizedBox(height: 16),
            EditActionButtons(
              customerId: customer.customerId,
              onCancel: () {
                resetForm();
                widget.controller.setEditing(false);
              },
              onSave: () async {
                if (!(_formKey.currentState?.validate() ?? false)) {
                  return;
                }
                widget.controller.updatedCustomerData = InputCustomer.empty();

                _formKey.currentState?.save();

                await widget.controller.updateCustomer(
                  widget.customer.customerId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
