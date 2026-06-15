import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/currency_input_formatter.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_device_payment.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddNewPaymentDialog extends StatefulWidget {
  const AddNewPaymentDialog({super.key});

  @override
  State<AddNewPaymentDialog> createState() => _AddNewPaymentDialogState();
}

class _AddNewPaymentDialogState extends State<AddNewPaymentDialog> {
  late DeviceCustomerPageController controller;
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  late InputPayment _inputPayment;
  PaymentCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    controller = context.read<DeviceCustomerPageController>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    return DateFormat('dd/MM/yyyy').format(date);
  }

  Future<void> _createNewPayment(BuildContext context) async {
    if (controller.isCreatingPayment) return;

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      await controller.createCustomerDevicePayment(_inputPayment);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    _inputPayment = InputPayment.empty(controller.deviceCustomer.deviceId);
    _dateController.text = _formatDate(_inputPayment.paymentDate) ?? '';

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                headerLabel: 'Categoria',
                items: PaymentCategory.values
                    .map((e) => e.displayName)
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = PaymentCategory.values.firstWhere(
                      (e) => e.displayName == value,
                    );
                  });
                },
                onSave: (value) {
                  final category = PaymentCategory.values.firstWhere(
                    (e) => e.displayName == value,
                  );
                  _inputPayment = _inputPayment.copyWith(category: category);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecione uma categoria';
                  }
                  final budgetFee = controller.deviceCustomer.budgetFee ?? 0;
                  if (budgetFee <= 0 &&
                      _selectedCategory == PaymentCategory.budgetFee) {
                    return 'Taxa de orçamento não definida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                    value: value?.fromCurrency(),
                  );
                },
                errorMaxLines: 2,
                validator: (value) {
                  final inputValue = value?.fromCurrency() ?? 0;

                  if (inputValue == 0) return 'Informe o valor do pagamento';

                  if (_selectedCategory == PaymentCategory.budgetFee) {
                    final budgetFee = controller.deviceCustomer.budgetFee ?? 0;
                    final totalPaidFee = controller.deviceCustomer.totalPaidFee;
                    final remaining = budgetFee - totalPaidFee;

                    if (budgetFee > 0 && inputValue > remaining) {
                      return 'As taxas já pagas (${totalPaidFee.toBrCurrency}) excedem o valor da taxa de orçamento';
                    }
                  }
                  return null;
                },
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 16),
              CustomDateFormField(
                dateController: _dateController,
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
              ),
              const SizedBox(height: 16),
              CustomDropdownButtonFormField(
                headerLabel: 'Recebido por',
                hintText: 'Opcional',
                items: controller.technicians
                    .map((e) => e.name.capitalizeAllWords)
                    .toList(),
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    _inputPayment = _inputPayment.copyWith(receivedBy: value);
                  }
                },
                onSave: (value) {
                  if (value.isNotEmpty) {
                    _inputPayment = _inputPayment.copyWith(receivedBy: value);
                  }
                },
              ),
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
          child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
        ),
        ElevatedButton(
          onPressed: () async => await _createNewPayment(context),
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
