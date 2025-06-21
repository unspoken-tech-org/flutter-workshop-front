import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/pages/device_customer/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/widgets/customer_device/customer_device_text_field.dart';
import 'package:flutter_workshop_front/widgets/customer_device/date_picker.dart';
import 'package:flutter_workshop_front/widgets/customer_device/dialogs/unfinished_payment_dialog.dart';
import 'package:flutter_workshop_front/widgets/customer_device/validators/contact_form_validator.dart';
import 'package:flutter_workshop_front/widgets/shared/custom_dropdown_widget.dart';

class AddContactWidget extends StatefulWidget {
  final int deviceId;
  final Function() onClose;
  final VoidCallback onSave;

  const AddContactWidget({
    super.key,
    required this.deviceId,
    required this.onClose,
    required this.onSave,
  });

  @override
  State<AddContactWidget> createState() => _AddContactWidgetState();
}

class _AddContactWidgetState extends State<AddContactWidget>
    with ContactFormValidator {
  final SnackBarUtil snackBarUtil = SnackBarUtil();
  late InputCustomerContact inputCustomerContact;

  void _saveContact(DeviceCustomerPageController controller,
      InputCustomerContact input) async {
    if (!validateAll(input)) {
      setState(() {});
      snackBarUtil
          .showError('Por favor, preencha todos os campos obrigatórios');
      return;
    }

    final isPaymentWidgetVisible = controller.isPaymentsWidgetVisible.value;
    final newPayment = controller.newPayment.value;
    if (isPaymentWidgetVisible && newPayment == null) {
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return const UnfinishedPaymentDialog();
        },
      );

      if (shouldProceed != true) {
        return;
      }
    }
    controller.isPaymentsWidgetVisible.value = false;
    await controller.createCustomerContact(input);
    widget.onSave();
  }

  @override
  void initState() {
    super.initState();
    inputCustomerContact = InputCustomerContact.empty(widget.deviceId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    var deviceCustomer = controller.newDeviceCustomer.value;
    var technicians = controller.technicians;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () {
                controller.isPaymentsWidgetVisible.value = false;
                widget.onClose();
              },
              icon: const Icon(Icons.close, size: 18),
            ),
            ValueListenableBuilder(
              valueListenable: controller.newPayment,
              builder: (context, value, child) {
                var isPaymentAdded = value != null;

                return TextButton.icon(
                  onPressed: () {
                    controller.isPaymentsWidgetVisible.value =
                        !controller.isPaymentsWidgetVisible.value;
                  },
                  icon: isPaymentAdded
                      ? Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.red.withAlpha(200),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: isPaymentAdded
                      ? Text(
                          'Editar Pagamento',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.withAlpha(200),
                          ),
                        )
                      : const Text('Adicionar Pagamento',
                          style: TextStyle(fontSize: 16)),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomDropdownWidget(
                                  label: 'Tipo de contato',
                                  value: inputCustomerContact.contactType,
                                  items: InputCustomerContact.contactTypes
                                      .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(e),
                                            ],
                                          )))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      inputCustomerContact.contactType = value;
                                      clearFieldValidation(
                                          ContactField.contactType);
                                    });
                                  },
                                  isInvalid:
                                      isFieldInvalid(ContactField.contactType),
                                ),
                                const SizedBox(height: 16),
                                CustomDropdownWidget<String?>(
                                  label: 'Número de telefone',
                                  value: inputCustomerContact.phoneNumber,
                                  items: deviceCustomer.customerPhones
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e.number,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(PhoneUtils.formatPhone(
                                                  e.number)),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: inputCustomerContact.contactType !=
                                          'Pessoalmente'
                                      ? (value) {
                                          setState(() {
                                            inputCustomerContact.phoneNumber =
                                                value;
                                            clearFieldValidation(
                                                ContactField.phoneNumber);
                                          });
                                        }
                                      : null,
                                  isInvalid:
                                      isFieldInvalid(ContactField.phoneNumber),
                                ),
                                const SizedBox(height: 16),
                                CustomDropdownWidget(
                                  label: 'Status do contato',
                                  value: inputCustomerContact.contactStatus,
                                  items: InputCustomerContact.contactStatuses
                                      .map((e) => DropdownMenuItem<String>(
                                          value: e,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(e),
                                            ],
                                          )))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      inputCustomerContact.contactStatus =
                                          value;
                                      clearFieldValidation(
                                          ContactField.contactStatus);
                                    });
                                  },
                                  isInvalid: isFieldInvalid(
                                      ContactField.contactStatus),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomDropdownWidget(
                                  label: 'Contatante',
                                  value: inputCustomerContact.technicianId,
                                  items: technicians
                                      .map((e) => DropdownMenuItem(
                                          value: e.id,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(e.name,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ],
                                          )))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      inputCustomerContact.technicianId = value;
                                      clearFieldValidation(
                                          ContactField.technician);
                                    });
                                  },
                                  isInvalid:
                                      isFieldInvalid(ContactField.technician),
                                ),
                                const SizedBox(height: 16),
                                CustomDropdownWidget(
                                  label: 'Status do aparelho',
                                  value: inputCustomerContact.deviceStatus,
                                  items: StatusEnum.values
                                      .map((e) => DropdownMenuItem(
                                          value: e.value,
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(e.name,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ],
                                          )))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      inputCustomerContact.deviceStatus = value;
                                      clearFieldValidation(
                                          ContactField.deviceStatus);
                                    });
                                  },
                                  isInvalid:
                                      isFieldInvalid(ContactField.deviceStatus),
                                ),
                                const SizedBox(height: 16),
                                const Text('Data do contato'),
                                const SizedBox(height: 8),
                                DatePicker(
                                  onDateSelected: (date) {
                                    setState(() {
                                      inputCustomerContact.contactDate = date;
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Dialogo'),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: CustomerDeviceTextField(
                                      initialValue:
                                          inputCustomerContact.message,
                                      expandHeight: true,
                                      isInvalid:
                                          isFieldInvalid(ContactField.message),
                                      onUpdate: (value) {
                                        setState(() {
                                          inputCustomerContact.message = value;
                                          clearFieldValidation(
                                              ContactField.message);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  inputCustomerContact =
                      InputCustomerContact.empty(widget.deviceId);
                  clearAllValidations();
                });
              },
              child: const Text('Limpar'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                _saveContact(controller, inputCustomerContact);
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Salvar'),
            ),
          ],
        ),
      ],
    );
  }
}
