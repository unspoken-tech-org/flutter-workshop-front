import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';

class AutocompleteFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final List<ITypeBrandModelColor> suggestions;
  final String? tooltipText;
  final Function(int? id) onAccept;
  final VoidCallback? onClear;
  final Function(int? id, String name)? onSubmit;
  final String? Function(String? value)? fieldValidator;

  const AutocompleteFormField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.suggestions,
    required this.onAccept,
    this.tooltipText,
    this.onClear,
    this.onSubmit,
    this.fieldValidator,
  });

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ITypeBrandModelColor>(
      displayStringForOption: (ITypeBrandModelColor option) =>
          option.getName().capitalizeAllWords,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<ITypeBrandModelColor>.empty();
        }
        return suggestions.where((ITypeBrandModelColor option) {
          return option
              .getName()
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (ITypeBrandModelColor selection) {
        controller.text = selection.getName().capitalizeAllWords;
        onAccept(selection.getId());
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<ITypeBrandModelColor> onSelected,
          Iterable<ITypeBrandModelColor> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: SizedBox(
              width: _calculateWidth(context, options),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final ITypeBrandModelColor option =
                        options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                        onAccept(option.getId());
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(option.getName().capitalizeAllWords),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      fieldViewBuilder: (BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted) {
        // Sincroniza o controller do Autocomplete com o controller externo
        // para evitar que o estado se perca.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (fieldTextEditingController.text != controller.text) {
            fieldTextEditingController.text =
                controller.text.capitalizeAllWords;
          }
        });

        return Tooltip(
          message: tooltipText ?? '',
          child: TextFormField(
            controller: fieldTextEditingController,
            focusNode: fieldFocusNode,
            onFieldSubmitted: (String text) {
              onSubmit?.call(null, text);
            },
            onChanged: (String text) {
              if (text.isEmpty) {
                onClear?.call();
              }
              controller.value = TextEditingValue(
                text: text.capitalizeAllWords,
                selection: fieldTextEditingController.selection,
              );
            },
            decoration: InputDecoration(
              labelText: labelText,
              border: const OutlineInputBorder(),
            ),
            validator: fieldValidator,
          ),
        );
      },
    );
  }

  double? _calculateWidth(
      BuildContext context, Iterable<ITypeBrandModelColor> options) {
    if (options.isEmpty) {
      return null;
    }

    const double padding = 32;
    double maxWidth = 0.0;
    final style = DefaultTextStyle.of(context).style;

    for (final option in options) {
      final textPainter = TextPainter(
        text: TextSpan(text: option.getName().capitalizeFirst, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: double.infinity);
      if (textPainter.width > maxWidth) {
        maxWidth = textPainter.width;
      }
    }

    return maxWidth + padding;
  }
}
