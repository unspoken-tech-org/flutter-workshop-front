import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/text_input_formatters/phone_number_formatter.dart';

class SecondaryPhoneFormField extends StatelessWidget {
  final String? name;
  final String? number;
  final String? headerLabel;
  final bool readOnly;

  final void Function(PhoneFieldParameters? value)? onSaved;

  const SecondaryPhoneFormField({
    super.key,
    this.name,
    this.number,
    this.headerLabel,
    this.readOnly = false,
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerLabel != null) ...[
          Text(
            headerLabel!,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        FormField<PhoneFieldParameters>(
          initialValue: PhoneFieldParameters(name: name, number: number),
          onSaved: onSaved,
          validator: (value) {
            final int digitCount =
                (value?.number ?? '').replaceAll(RegExp(r'\D'), '').length;
            if (value?.number?.isNotEmpty == true && digitCount < 10) {
              return 'Telefone incompleto';
            }

            return null;
          },
          builder: (FormFieldState<PhoneFieldParameters> state) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: TextFormField(
                    initialValue: name,
                    readOnly: readOnly,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      labelText: 'Nome secundário (opcional)',
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 12.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide:
                            BorderSide(color: Colors.blue.shade300, width: 1.5),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                    ),
                    onChanged: (value) {
                      state.didChange(PhoneFieldParameters(
                        name: value,
                        number: state.value?.number,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: number,
                        readOnly: readOnly,
                        inputFormatters: [PhoneNumberFormatter()],
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Telefone',
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(
                                color: Colors.blue.shade300, width: 1.5),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          fillColor: Colors.white,
                          filled: true,
                        ),
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                        ),
                        onChanged: (value) {
                          state.didChange(PhoneFieldParameters(
                            name: state.value?.name,
                            number: value,
                          ));
                        },
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(
                              color: Theme.of(state.context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        )
      ],
    );
  }
}

class PhoneFieldParameters {
  final String? name;
  final String? number;

  PhoneFieldParameters({
    this.name,
    this.number,
  });
}
