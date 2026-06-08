import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/contact_modal_shared.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EditContactModalDialog extends StatefulWidget {
  final CustomerContact contact;

  const EditContactModalDialog({super.key, required this.contact});

  @override
  State<EditContactModalDialog> createState() => _EditContactModalDialogState();
}

class _EditContactModalDialogState extends State<EditContactModalDialog> {
  late final DeviceCustomerPageController controller;

  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  late InputCustomerContact inputCustomerContact;
  bool isContactTypePersonally = false;

  @override
  void initState() {
    super.initState();
    controller = context.read<DeviceCustomerPageController>();
    inputCustomerContact = InputCustomerContact.fromCustomerContact(
      widget.contact,
    );
    isContactTypePersonally =
        inputCustomerContact.contactType == ContactType.pessoalmente.name;

    _dateController.text = widget.contact.lastContact;
  }

  String? _initialContactTypeDisplayName() {
    try {
      return ContactType.values
          .firstWhere(
            (e) => e.name == inputCustomerContact.contactType,
          )
          .displayName;
    } catch (_) {
      return null;
    }
  }

  String? _initialContactStatusDisplayName() {
    try {
      return ContactStatus.values
          .firstWhere(
            (e) => e.name == inputCustomerContact.contactStatus,
          )
          .displayName;
    } catch (_) {
      return null;
    }
  }

  String? _initialTechnicianName(List<Technician> technicians) {
    try {
      return technicians
          .firstWhere((e) => e.id == widget.contact.technicianId)
          .name;
    } catch (_) {
      return widget.contact.technicianName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          width: MediaQuery.of(context).size.width * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Form(
            key: _formKey,
            child: Selector<
              DeviceCustomerPageController,
              (DeviceCustomer, List<Technician>)
            >(
              selector: (context, controller) =>
                  (controller.deviceCustomer, controller.technicians),
              builder: (context, values, child) {
                final (deviceCustomer, technicians) = values;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _EditContactHeader(context: context),
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
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              CustomDropdownButtonFormField(
                                headerLabel: 'Tipo de contato',
                                value: _initialContactTypeDisplayName(),
                                items: InputCustomerContact.contactTypes
                                    .map((e) => e.displayName)
                                    .toList(),
                                onSave: (value) {
                                  inputCustomerContact.contactType =
                                      ContactType.fromDisplayName(
                                        value,
                                      ).name;
                                },
                                onChanged: (value) {
                                  isContactTypePersonally =
                                      value ==
                                      ContactType.pessoalmente.displayName;
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
                                value: _initialTechnicianName(technicians),
                                items: technicians
                                    .map((e) => e.name)
                                    .toList(),
                                onSave: (value) {
                                  inputCustomerContact.technicianId =
                                      technicians
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
                                value: PhoneUtils.formatPhone(
                                  inputCustomerContact.phoneNumber,
                                ),
                items: () {
                  final formattedContactPhone =
                      inputCustomerContact.phoneNumber != null
                          ? PhoneUtils.formatPhone(
                              inputCustomerContact.phoneNumber,
                            )
                          : null;
                  final items = <String>[];
                  if (formattedContactPhone != null) {
                    items.add(formattedContactPhone);
                  }
                  for (final phone in deviceCustomer.customerPhones) {
                    final formatted = PhoneUtils.formatPhone(phone.number);
                    if (!items.contains(formatted)) {
                      items.add(formatted);
                    }
                  }
                  return items;
                }(),
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
                                icon: Icons.settings_outlined,
                              ),
                              const SizedBox(height: 16),
                              CustomDropdownButtonFormField(
                                headerLabel: 'Status do aparelho',
                                value: widget.contact.deviceStatus.displayName,
                                items: StatusEnum.values
                                    .map((e) => e.displayName)
                                    .toList(),
                                onSave: (value) {
                                  final statusValue = StatusEnum.values
                                      .firstWhere(
                                        (e) => e.displayName == value,
                                      );
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
                                value: _initialContactStatusDisplayName(),
                                items: InputCustomerContact.contactStatuses
                                    .map((e) => e.displayName)
                                    .toList(),
                                onSave: (value) {
                                  inputCustomerContact.contactStatus =
                                      ContactStatus.fromDisplayName(
                                        value,
                                      ).name;
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
                                onSave: (value) {
                                  DateFormat format = DateFormat(
                                    "dd/MM/yyyy",
                                  );
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
                                title: 'Diálogo',
                                icon: Icons.message_outlined,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                initialValue: widget.contact.conversation,
                                maxLines: 12,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Digite aqui os detalhes da conversa, observações importantes ou próximos passos...',
                                  border: OutlineInputBorder(),
                                ),
                                onSaved: (value) {
                                  inputCustomerContact.message =
                                      value ?? '';
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
                        await controller.updateCustomerContact(
                          widget.contact.id,
                          inputCustomerContact,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _EditContactHeader extends StatelessWidget {
  const _EditContactHeader({required this.context});

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
                const Icon(Icons.edit, size: 28),
                const SizedBox(width: 8),
                Text('Editar Contato', style: WsTextStyles.h2),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Atualize os dados do contato com o cliente',
              style: WsTextStyles.subtitle1.copyWith(
                color: Colors.grey.shade600,
              ),
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
