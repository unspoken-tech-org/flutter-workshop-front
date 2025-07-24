import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/pages/devices/device_register/controller/device_register_controller.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/searchable_dropdown_button_form_field.dart';
import 'package:provider/provider.dart';

class CustomerInfos extends StatelessWidget {
  const CustomerInfos({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        spacing: 16,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline),
              SizedBox(width: 16),
              Text(
                'Informações do Cliente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Selector<DeviceRegisterController, (int?, String?)>(
            selector: (context, controller) =>
                (controller.customerId, controller.customerName),
            builder: (context, values, child) {
              final (customerId, customerName) = values;
              if (customerId != null && customerName != null) {
                return CustomerNameAndId(
                    customerId: customerId, customerName: customerName);
              }
              return const CustomerSearchField();
            },
          ),
        ],
      ),
    );
  }
}

class CustomerNameAndId extends StatelessWidget {
  final int customerId;
  final String customerName;
  const CustomerNameAndId(
      {super.key, required this.customerId, required this.customerName});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 16,
      children: [
        Expanded(
          child: CustomTextField(
            headerLabel: 'ID do Cliente',
            value: customerId.toString(),
            readOnly: true,
          ),
        ),
        Expanded(
          child: CustomTextField(
            headerLabel: 'Nome do Cliente',
            value: customerName,
            readOnly: true,
          ),
        ),
      ],
    );
  }
}

class CustomerSearchField extends StatelessWidget {
  const CustomerSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DeviceRegisterController>();

    return Selector<DeviceRegisterController, List<MinifiedCustomerModel>>(
      selector: (context, controller) => controller.customers,
      builder: (context, customers, child) {
        Map<String, int> itemsMap = {};
        for (var customer in customers) {
          itemsMap[customer.name.capitalizeAllWords] = customer.customerId;
        }

        return SearchableDropdownButtonFormField(
          items: itemsMap.keys.toList(),
          fieldLabel: 'Buscar Cliente',
          hintText: 'Busque por um cliente',
          onItemSelected: (value) {
            controller.setCustomerInfos(itemsMap[value], value);
          },
        );
      },
    );
  }
}
