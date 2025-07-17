import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/inherited_device_customer_controller.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:intl/intl.dart';

class AddContactModalDialog extends StatefulWidget {
  const AddContactModalDialog({super.key});

  @override
  State<AddContactModalDialog> createState() => _AddContactModalDialogState();
}

class _AddContactModalDialogState extends State<AddContactModalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  late InputCustomerContact inputCustomerContact;
  bool isContactTypePersonally = false;

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;

    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final controller = InheritedDeviceCustomerController.of(context);
    var deviceCustomer = controller.deviceCustomer.value;
    var technicians = controller.technicians;
    inputCustomerContact = InputCustomerContact.empty(deviceCustomer.deviceId);
    _dateController.text = _formatDate(inputCustomerContact.contactDate) ?? '';

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        width: MediaQuery.of(context).size.width * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerContactHeader(context: context),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SectionTileWidget(
                            title: 'Detalhes do Contato',
                            icon: Icons.person_outline),
                        const SizedBox(height: 16),
                        CustomDropdownButtonFormField(
                          headerLabel: 'Tipo de contato',
                          items: InputCustomerContact.contactTypes
                              .map((e) => e.displayName)
                              .toList(),
                          onSave: (value) {
                            inputCustomerContact.contactType =
                                ContactType.fromDisplayName(value).name;
                          },
                          onChanged: (value) {
                            isContactTypePersonally =
                                value == ContactType.pessoalmente.displayName;
                            setState(() {});
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione um tipo de contato';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomDropdownButtonFormField(
                          headerLabel: 'Contactante',
                          items: technicians.map((e) => e.name).toList(),
                          onSave: (value) {
                            inputCustomerContact.technicianId = technicians
                                .firstWhere((e) => e.name == value)
                                .id;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione um contactante';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomDropdownButtonFormField(
                          key: ValueKey(isContactTypePersonally),
                          headerLabel: 'Número de telefone',
                          enabled: !isContactTypePersonally,
                          items: deviceCustomer.customerPhones
                              .map((e) => PhoneUtils.formatPhone(e.number))
                              .toList(),
                          onSave: (value) {
                            inputCustomerContact.phoneNumber = value;
                          },
                          validator: (value) {
                            if (isContactTypePersonally) {
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return 'Digite um número de telefone';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        const SectionTileWidget(
                            title: 'Status e Data',
                            icon: Icons.settings_outlined),
                        const SizedBox(height: 16),
                        CustomDropdownButtonFormField(
                          headerLabel: 'Status do aparelho',
                          items: StatusEnum.values
                              .map((e) => e.displayName)
                              .toList(),
                          onSave: (value) {
                            final statusValue = StatusEnum.values
                                .firstWhere((e) => e.displayName == value);
                            inputCustomerContact.deviceStatus =
                                statusValue.dbName;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione um status do aparelho';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomDropdownButtonFormField(
                          headerLabel: 'Status do contato',
                          items: InputCustomerContact.contactStatuses
                              .map((e) => e.displayName)
                              .toList(),
                          onSave: (value) {
                            inputCustomerContact.contactStatus =
                                ContactStatus.fromDisplayName(value).name;
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Selecione um status do contato';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomDateFormField(
                          label: 'Data do contato',
                          dateController: _dateController,
                          context: context,
                          onSave: (value) {
                            DateFormat format = DateFormat("dd/MM/yyyy");
                            inputCustomerContact.contactDate =
                                format.parse(value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Selecione uma data';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SectionTileWidget(
                            title: 'Diálogo', icon: Icons.message_outlined),
                        const SizedBox(height: 16),
                        TextFormField(
                          maxLines: 12,
                          decoration: const InputDecoration(
                            hintText:
                                'Digite aqui os detalhes da conversa, observações importantes ou próximos passos...',
                            border: OutlineInputBorder(),
                          ),
                          onSaved: (value) {
                            inputCustomerContact.message = value ?? '';
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite aqui os detalhes da conversa';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 24),
              ActionButtonsWidget(
                formKey: _formKey,
                dateController: _dateController,
                onSave: () async {
                  await controller.createCustomerContact(inputCustomerContact);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerContactHeader extends StatelessWidget {
  const CustomerContactHeader({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add, size: 28),
                const SizedBox(width: 8),
                Text('Adicionar Contato', style: WsTextStyles.h2),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Registre um novo contato com o cliente',
              style:
                  WsTextStyles.subtitle1.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class ActionButtonsWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController dateController;
  final void Function() onSave;

  const ActionButtonsWidget({
    super.key,
    required this.formKey,
    required this.dateController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () {
            formKey.currentState?.reset();
            dateController.clear();
          },
          child: const Text('Limpar'),
        ),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: WsColors.dark,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (formKey.currentState?.validate() ?? false) {
              formKey.currentState?.save();
              onSave();
              Navigator.of(context).pop();
            }
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class SectionTileWidget extends StatelessWidget {
  const SectionTileWidget({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(title, style: WsTextStyles.h4),
      ],
    );
  }
}
