import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/route/ws_navigator.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/cpf_formatter.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';
import 'package:flutter_workshop_front/models/customer/input_customer.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/controllers/customer_register_controller.dart';
import 'package:flutter_workshop_front/pages/customers/customer_register/widgets/customer_registration_header.dart';
import 'package:flutter_workshop_front/utils/validators/cpf_validator.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:flutter_workshop_front/widgets/shared/secondary_phones_widget.dart';
import 'package:provider/provider.dart';

class CustomerRegisterForm extends StatefulWidget {
  const CustomerRegisterForm({super.key});

  @override
  State<CustomerRegisterForm> createState() => _CustomerRegisterFormState();
}

class _CustomerRegisterFormState extends State<CustomerRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  InputCustomer _inputCustomer = InputCustomer.empty();

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    super.dispose();
  }

  Future<void> onSave(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    var customerController = context.read<CustomerRegisterController>();

    _inputCustomer = _inputCustomer.copyWith(phones: []);
    _formKey.currentState?.save();

    final newCustomerId =
        await customerController.createCustomer(_inputCustomer);

    if (newCustomerId != null && context.mounted) {
      _formKey.currentState?.reset();
      WsNavigator.pushCustomerDetail(context, newCustomerId, replaced: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustomerRegistrationHeader(),
            const SizedBox(height: 32),
            CustomTextField(
              fieldLabel: 'Nome',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o nome';
                }
                return null;
              },
              onSave: (value) {
                _inputCustomer = _inputCustomer.copyWith(name: value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldLabel: 'CPF',
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
              onSave: (value) {
                final cpf = value?.replaceAll(RegExp(r'\D'), '');
                _inputCustomer = _inputCustomer.copyWith(cpf: cpf);
              },
            ),
            const SizedBox(height: 16),
            CustomDropdownButtonFormField(
              fieldLabel: 'Sexo',
              items: const ['Masculino', 'Feminino', 'Outro'],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, selecione o sexo';
                }
                return null;
              },
              onSave: (value) {
                _inputCustomer = _inputCustomer.copyWith(gender: value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldLabel: 'Email (opcional)',
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
              onSave: (value) {
                _inputCustomer = _inputCustomer.copyWith(email: value);
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              fieldLabel: 'Telefone Principal',
              inputFormatters: [PhoneNumberFormatter()],
              keyboardType: TextInputType.phone,
              onSave: (value) {
                _inputCustomer = _inputCustomer.copyWith(
                  phones: [
                    ..._inputCustomer.phones,
                    InputCustomerPhone(
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
            const SizedBox(height: 16),
            SecondaryPhonesWidget(
              isEditing: true,
              onSaved: (value) {
                _inputCustomer = _inputCustomer.copyWith(
                  phones: [
                    ..._inputCustomer.phones,
                    InputCustomerPhone(
                      number: value?.number ?? '',
                      name: value?.name ?? '',
                      isPrimary: false,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 16,
                children: [
                  ElevatedButton(
                    onPressed: _formKey.currentState?.reset,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white.withAlpha(230),
                    ),
                    child: const Text('Limpar'),
                  ),
                  Selector<CustomerRegisterController, bool>(
                    selector: (context, controller) =>
                        controller.isCreatingCustomer,
                    builder: (context, isCreatingCustomer, child) {
                      return SizedBox(
                        width: 150,
                        child: ElevatedButton(
                          onPressed: isCreatingCustomer
                              ? null
                              : () async => await onSave(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                          ),
                          child: isCreatingCustomer
                              ? const Center(
                                  child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black87,
                                  ),
                                ))
                              : const Text('Cadastrar'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
