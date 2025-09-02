import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/form_fields/secondary_phone_form_field.dart';

class SecondaryPhonesWidget extends StatefulWidget {
  final List<PhoneFieldParameters>? initialPhones;
  final bool isEditing;
  final void Function(PhoneFieldParameters?)? onSaved;

  const SecondaryPhonesWidget({
    super.key,
    this.initialPhones,
    this.isEditing = false,
    this.onSaved,
  });

  @override
  State<SecondaryPhonesWidget> createState() => _SecondaryPhonesWidgetState();
}

class _SecondaryPhonesWidgetState extends State<SecondaryPhonesWidget> {
  final List<SecondaryPhoneFormField> _secondaryPhoneFields = [];

  @override
  void initState() {
    super.initState();
    _initSecondaryPhoneFields();
  }

  @override
  void dispose() {
    _secondaryPhoneFields.clear();
    super.dispose();
  }

  @override
  void didUpdateWidget(SecondaryPhonesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEditing != widget.isEditing) {
      _secondaryPhoneFields.clear();
      _initSecondaryPhoneFields();
      setState(() {});
    }
  }

  void _initSecondaryPhoneFields() {
    widget.initialPhones?.forEach((phone) {
      _secondaryPhoneFields.add(
        SecondaryPhoneFormField(
          key:
              ValueKey('phone_field_name_${phone.name}_number_${phone.number}'),
          name: phone.name,
          number: PhoneUtils.formatPhone(phone.number),
          readOnly: !widget.isEditing,
          onSaved: widget.onSaved,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._secondaryPhoneFields.mapIndexed((index, phoneWidget) {
          return Column(
            children: [
              if (index > 0) const SizedBox(height: 16),
              Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: phoneWidget),
                  if (widget.isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      style: IconButton.styleFrom(
                        iconSize: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          _secondaryPhoneFields.removeAt(index);
                        });
                      },
                    )
                ],
              ),
            ],
          );
        }),
        if (widget.isEditing && _secondaryPhoneFields.length < 3) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _secondaryPhoneFields.add(
                  SecondaryPhoneFormField(
                    key: const ValueKey('phone_field_name_number_'),
                    readOnly: !widget.isEditing,
                    onSaved: widget.onSaved,
                  ),
                );
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Adicionar telefone secundário'),
          ),
        ],
      ],
    );
  }
}
