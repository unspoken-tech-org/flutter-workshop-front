import 'package:flutter_workshop_front/core/validators/form_validators.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_contact.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/widgets/dialogs/contact_modal_shared.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';
import 'package:flutter_workshop_front/models/customer_device/input_customer_contact.dart';
import 'package:flutter_workshop_front/models/home_table/status_enum.dart';
import 'package:flutter_workshop_front/models/technician/technician.dart';
import 'package:flutter_workshop_front/pages/devices/device_details/controllers/device_customer_page_controller.dart';
import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_date_form_field.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_dropdown_button_form_field.dart';
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

    _dateController.text = widget.contact.lastContact.formatDate();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String? _initialContactTypeDisplayName() {
    return ContactType.values
        .firstWhereOrNull((e) => e.name == inputCustomerContact.contactType)
        ?.displayName;
  }

  String? _initialContactStatusDisplayName() {
    return ContactStatus.values
        .firstWhereOrNull((e) => e.name == inputCustomerContact.contactStatus)
        ?.displayName;
  }

  String? _initialTechnicianName(List<Technician> technicians) {
    return technicians
        .firstWhereOrNull((e) => e.id == widget.contact.technicianId)
        ?.name;
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
            child:
                Selector<
                  DeviceCustomerPageController,
                  (DeviceCustomer?, List<Technician>, bool)
                >(
                  selector: (context, controller) => (
                    controller.deviceCustomer,
                    controller.technicians,
                    controller.isEditingContact,
                  ),
                  builder: (context, values, child) {
                    final (deviceCustomer, technicians, isSaving) = values;
                    if (deviceCustomer == null) return const SizedBox.shrink();
                    final initialTechName = _initialTechnicianName(technicians);
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
                                    semanticsIdentifier: 'contactDialog.type',
                                    headerLabel: 'Tipo de contato',
                                    initialValue:
                                        _initialContactTypeDisplayName(),
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
                                      if (value != null) {
                                        inputCustomerContact.contactType =
                                            ContactType.tryParse(value)?.name;
                                      }
                                      isContactTypePersonally =
                                          value ==
                                          ContactType.pessoalmente.displayName;
                                      setState(() {});
                                    },
                                    validator: FormValidators.selected(
                                      'Selecione um tipo de contato',
                                    ),
                                  ),
                                  if (inputCustomerContact.contactType ==
                                          null &&
                                      widget.contact.type.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Tipo atual: ${widget.contact.type} — selecione uma opção',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  CustomDropdownButtonFormField(
                                    semanticsIdentifier:
                                        'contactDialog.contactant',
                                    headerLabel: 'Contactante',
                                    hintText: initialTechName == null
                                        ? widget.contact.technicianName
                                        : null,
                                    initialValue: initialTechName,
                                    items: technicians
                                        .map((e) => e.name)
                                        .toList(),
                                    onSave: (value) {
                                      inputCustomerContact.technicianId =
                                          technicians
                                              .firstWhereOrNull(
                                                (e) => e.name == value,
                                              )
                                              ?.id ??
                                          inputCustomerContact.technicianId;
                                    },
                                    validator: FormValidators.selected(
                                      'Selecione um contactante',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomDropdownButtonFormField(
                                    semanticsIdentifier: 'contactDialog.phone',
                                    key: ValueKey(isContactTypePersonally),
                                    headerLabel: 'Número de telefone',
                                    enabled: !isContactTypePersonally,
                                    initialValue: BrFormat.phone(
                                      inputCustomerContact.phoneNumber,
                                    ),
                                    items: () {
                                      final formattedContactPhone =
                                          inputCustomerContact.phoneNumber !=
                                              null
                                          ? BrFormat.phone(
                                              inputCustomerContact.phoneNumber,
                                            )
                                          : null;
                                      final items = <String>[];
                                      if (formattedContactPhone != null) {
                                        items.add(formattedContactPhone);
                                      }
                                      for (final phone
                                          in deviceCustomer.customerPhones) {
                                        final formatted = BrFormat.phone(
                                          phone.number,
                                        );
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
                                    semanticsIdentifier:
                                        'contactDialog.deviceStatus',
                                    headerLabel: 'Status do aparelho',
                                    initialValue:
                                        widget.contact.deviceStatus ==
                                            StatusEnum.unknown
                                        ? null
                                        : widget
                                              .contact
                                              .deviceStatus
                                              .displayName,
                                    items: StatusEnum.selectableValues
                                        .map((e) => e.displayName)
                                        .toList(),
                                    onSave: (value) {
                                      final statusValue = StatusEnum
                                          .selectableValues
                                          .firstWhereOrNull(
                                            (e) => e.displayName == value,
                                          );
                                      if (statusValue != null) {
                                        inputCustomerContact.deviceStatus =
                                            statusValue.dbName;
                                      }
                                    },
                                    validator: FormValidators.selected(
                                      'Selecione um status do aparelho',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomDropdownButtonFormField(
                                    semanticsIdentifier:
                                        'contactDialog.contactStatus',
                                    headerLabel: 'Status do contato',
                                    initialValue:
                                        _initialContactStatusDisplayName(),
                                    items: InputCustomerContact.contactStatuses
                                        .map((e) => e.displayName)
                                        .toList(),
                                    onSave: (value) {
                                      inputCustomerContact.contactStatus =
                                          ContactStatus.fromDisplayName(
                                            value,
                                          ).name;
                                    },
                                    validator: FormValidators.selected(
                                      'Selecione um status do contato',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomDateFormField(
                                    semanticsIdentifier: 'contactDialog.date',
                                    label: 'Data do contato',
                                    dateController: _dateController,
                                    onSave: (value) {
                                      inputCustomerContact.contactDate =
                                          BrFormat.parseDate(value);
                                    },
                                    validator: FormValidators.required(
                                      'Selecione uma data',
                                    ),
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
                                  Semantics(
                                    identifier: 'contactDialog.message',
                                    child: TextFormField(
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
                                      validator: FormValidators.required(
                                        'Digite aqui os detalhes da conversa',
                                      ),
                                    ),
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
                          isSaving: isSaving,
                          onSave: () => controller.updateCustomerContact(
                            widget.contact.id,
                            inputCustomerContact,
                          ),
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
        Semantics(
          identifier: 'contactDialog.close',
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }
}
