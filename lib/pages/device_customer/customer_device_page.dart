import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/input_payment.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/widgets/customer_device_payments.dart';
import 'package:flutter_workshop_front/widgets/core/ws_scaffold.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_infos_widget.dart';
import 'package:flutter_workshop_front/widgets/customer_device/device_tabs_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/custom_dropdown_widget.dart';
import 'package:flutter_workshop_front/widgets/shared/money_input_widget.dart';

class CustomerDevicePage extends StatefulWidget {
  final int deviceId;
  const CustomerDevicePage({super.key, required this.deviceId});

  @override
  State<CustomerDevicePage> createState() => _CustomerDevicePageState();
}

class _CustomerDevicePageState extends State<CustomerDevicePage>
    with SingleTickerProviderStateMixin {
  final DeviceCustomerPageController deviceCustomerPageController =
      DeviceCustomerPageController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    deviceCustomerPageController.init(widget.deviceId);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 330),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -0.4,
      end: 0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    deviceCustomerPageController.isPaymentsWidgetVisible
        .addListener(_toggleNewPaymentWidget);
  }

  @override
  void dispose() {
    deviceCustomerPageController.isPaymentsWidgetVisible
        .removeListener(_toggleNewPaymentWidget);
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNewPaymentWidget() {
    bool isNewPaymentVisible =
        deviceCustomerPageController.isPaymentsWidgetVisible.value;
    if (isNewPaymentVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InheritedDeviceCustomerController(
      controller: deviceCustomerPageController,
      child: WsScaffold(
        child: ValueListenableBuilder(
          valueListenable: deviceCustomerPageController.isLoading,
          builder: (context, value, child) {
            if (value) {
              return const Center(child: CircularProgressIndicator());
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 500,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 20,
                          children: [
                            CustomerDeviceInfosWidget(),
                            Expanded(child: CustomerDevicePayments()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16).copyWith(
                        bottom: 16,
                      ),
                      child: Stack(
                        alignment: Alignment.bottomLeft,
                        children: [
                          Align(
                            alignment: Alignment.bottomRight,
                            child: AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(
                                    MediaQuery.of(context).size.width *
                                        _animation.value,
                                    0,
                                  ),
                                  child: ValueListenableBuilder(
                                    valueListenable:
                                        deviceCustomerPageController.newPayment,
                                    builder: (context, payment, child) {
                                      return NewPaymentWidget(
                                        deviceId: widget.deviceId,
                                        isEditing: payment != null,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                          const DeviceTabsWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

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
      height: MediaQuery.of(context).size.height * 0.37,
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
