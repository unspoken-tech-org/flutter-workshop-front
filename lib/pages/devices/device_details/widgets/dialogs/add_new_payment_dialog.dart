import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:intl/intl.dart';

class AddNewPaymentDialog extends StatefulWidget {
  const AddNewPaymentDialog({super.key});

  @override
  State<AddNewPaymentDialog> createState() => _AddNewPaymentDialogState();
}

class _AddNewPaymentDialogState extends State<AddNewPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  late InputPayment _inputPayment;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  double _parseMoneyValue(String value) {
    final onlyNumbers =
        value.replaceAll('R\$', '').replaceAll('.', '').replaceAll(',', '.');
    return double.parse(onlyNumbers);
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    _inputPayment =
        InputPayment.empty(controller.deviceCustomer.value.deviceId);
    _dateController.text = _formatDate(_inputPayment.paymentDate) ?? '';

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('+ Adicionar Pagamento'),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.3,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomDropdownButtonFormField(
                headerLabel: 'Tipo de Pagamento',
                items: PaymentType.values.map((e) => e.displayName).toList(),
                onSave: (value) {
                  final paymentType = PaymentType.values.firstWhere(
                    (e) => e.displayName == value,
                  );
                  _inputPayment = _inputPayment.copyWith(
                    paymentType: paymentType,
                  );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione um tipo de pagamento';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                headerLabel: 'Valor',
                value: _inputPayment.value.toBrCurrency,
                onSave: (value) {
                  _inputPayment = _inputPayment.copyWith(
                    value: _parseMoneyValue(value ?? '0'),
                  );
                },
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      _parseMoneyValue(value) == 0) {
                    return 'Informe o valor do pagamento';
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [
                  CurrencyInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              CustomDateFormField(
                dateController: _dateController,
                context: context,
                label: 'Data do Pagamento',
                onSave: (value) => _inputPayment = _inputPayment.copyWith(
                  paymentDate: DateFormat('dd/MM/yyyy').parse(value),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione a data do pagamento';
                  }
                  return null;
                },
              )
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(color: Colors.grey.shade300),
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.black),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              try {
                await controller.createCustomerDevicePayment(_inputPayment);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                // do nothing
              }
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(color: Colors.indigo.shade900),
            backgroundColor: Colors.indigo.shade900,
          ),
          child: const Text(
            'Adicionar Pagamento',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
