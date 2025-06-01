import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/widgets/shared/custom_dropdown_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/money_input_widget.dart';

class NewPaymentWidget extends StatefulWidget {
  final int deviceId;
  final bool isEditing;

  const NewPaymentWidget({
    super.key,
    required this.deviceId,
    this.isEditing = false,
  });

  @override
  State<NewPaymentWidget> createState() => _NewPaymentWidgetState();
}

class _NewPaymentWidgetState extends State<NewPaymentWidget> {
  late InputPayment inputPayment;

  @override
  void initState() {
    super.initState();
    inputPayment = InputPayment.empty(widget.deviceId);
  }

  @override
  void didUpdateWidget(NewPaymentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isEditing) {
      inputPayment = InputPayment.empty(widget.deviceId);
      setState(() {});
    }
  }

  void _saveNewPayment(DeviceCustomerPageController controller) {
    controller.saveNewPayment(inputPayment);
    controller.isPaymentsWidgetVisible.value = false;
  }

  void _clearNewPayment(DeviceCustomerPageController controller) {
    controller.clearNewPayment();
    setState(() => inputPayment = InputPayment.empty(widget.deviceId));
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);

    return Container(
      height: 450,
      width: MediaQuery.of(context).size.width * 0.27,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      controller.isPaymentsWidgetVisible.value = false;
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    CustomDropdownWidget(
                      label: 'Tipo de pagamento',
                      value: inputPayment.paymentType,
                      items: ['Crédito', 'Débito', 'Pix', 'Dinheiro']
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(e,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              )))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          inputPayment =
                              inputPayment.copyWith(paymentType: value);
                        });
                      },
                    ),
                    MoneyInputWidget(
                      label: 'Valor',
                      initialValue: inputPayment.value,
                      padding: EdgeInsets.zero,
                      width: 170,
                      backgroundColor: Colors.transparent,
                      borderColor: Colors.transparent,
                      boxShadow: const [],
                      borderRadius: 8,
                      onChanged: (value) {
                        setState(() {
                          inputPayment = inputPayment.copyWith(value: value);
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: inputPayment.isEmpty
                      ? null
                      : () => _clearNewPayment(controller),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor:
                        inputPayment.isEmpty ? Colors.grey : Colors.blue,
                  ),
                  child: const Text('Limpar'),
                ),
                TextButton(
                  onPressed: inputPayment.isEmpty
                      ? null
                      : () => _saveNewPayment(controller),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        inputPayment.isEmpty ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
