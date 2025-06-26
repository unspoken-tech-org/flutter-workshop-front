import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/pages/customers/controllers/customer_detail/inherited_customer_detail_controller.dart';
import 'package:flutter_workshop_front/pages/customers/widgets/customer_detail/customer_detail_form.dart';

class EditActionButtons extends StatelessWidget {
  const EditActionButtons({
    super.key,
    required this.customerId,
    required this.isEditingNotifier,
    required this.formKey,
  });

  final int customerId;
  final ValueNotifier<bool> isEditingNotifier;
  final GlobalKey<CustomerDetailFormState> formKey;

  @override
  Widget build(BuildContext context) {
    final controller = InheritedCustomerDetailController.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: isEditingNotifier,
      builder: (context, isEditing, _) {
        if (isEditing) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  formKey.currentState?.resetForm();
                  isEditingNotifier.value = false;
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () async {
                  final input = formKey.currentState?.getInput();
                  if (input != null) {
                    final success = await controller.updateCustomer(
                      customerId,
                      input,
                    );
                    if (success) {
                      isEditingNotifier.value = false;
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750a4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salvar'),
              ),
            ],
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => isEditingNotifier.value = true,
              child: const Text('Editar'),
            ),
          ],
        );
      },
    );
  }
}
