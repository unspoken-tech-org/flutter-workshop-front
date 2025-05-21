import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';

class DeviceLaborValueWidget extends StatefulWidget {
  const DeviceLaborValueWidget({super.key});

  @override
  State<DeviceLaborValueWidget> createState() => _DeviceLaborValueWidgetState();
}

class _DeviceLaborValueWidgetState extends State<DeviceLaborValueWidget> {
  final _controller = TextEditingController();
  String _lastValue = '';
  double _lastLaborValue = 0;

  void _formatText() {
    String current = _controller.text;
    if (current == _lastValue) return;

    String digitsOnly = current.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      _controller.text = '';
      _lastValue = '';
      return;
    }

    int number = int.parse(digitsOnly);
    double formatted = _formatCurrency(number);
    _controller.value = TextEditingValue(
      text: formatted.toBrCurrency,
      selection: TextSelection.collapsed(offset: formatted.toBrCurrency.length),
    );
    _lastLaborValue = formatted;
    _lastValue = formatted.toBrCurrency;
  }

  double _formatCurrency(int value) {
    num reals = value ~/ 100;
    double cents = (value % 100) / 100;
    double total = reals + cents;
    return total;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_formatText);
  }

  @override
  void dispose() {
    _controller.removeListener(_formatText);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    var deviceCustomer = controller.currentDeviceCustomer.value;
    _controller.text = (deviceCustomer.laborValue ?? 0).toBrCurrency;

    return Container(
      padding: const EdgeInsets.all(8),
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 1,
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Valor Orçamento'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Digite um valor',
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              controller.updateNewDeviceCustomer(
                deviceCustomer.copyWith(laborValue: _lastLaborValue),
              );
            },
          ),
        ],
      ),
    );
  }
}
