import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/types_brands_models/types_brands_models.dart';
import 'package:flutter_workshop_front/widgets/form_fields/custom_text_field.dart';

class AutocompleteFormField extends StatefulWidget {
  final TextEditingController? _controller;
  final String? headerLabelText;
  final String? hintText;
  final List<ITypeBrandModelColor> suggestions;
  final List<TextInputFormatter> inputFormatters;
  final Widget? suffixIcon;
  final void Function(String name)? suffixIconAction;
  final Function(int? id) onAccept;
  final VoidCallback? onClear;
  final Function(int? id, String name)? onSubmit;
  final String? Function(String? value)? fieldValidator;
  final void Function(String? name)? onSave;

  AutocompleteFormField({
    super.key,
    TextEditingController? controller,
    this.headerLabelText,
    this.hintText,
    required this.suggestions,
    required this.onAccept,
    this.onClear,
    this.onSubmit,
    this.fieldValidator,
    this.inputFormatters = const [],
    this.suffixIcon,
    this.suffixIconAction,
    this.onSave,
  }) : _controller = controller ?? TextEditingController();

  @override
  State<AutocompleteFormField> createState() => _AutocompleteFormFieldState();
}

class _AutocompleteFormFieldState extends State<AutocompleteFormField> {
  @override
  void dispose() {
    widget._controller!.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AutocompleteFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suggestions != widget.suggestions) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<ITypeBrandModelColor>(
      displayStringForOption: (ITypeBrandModelColor option) =>
          option.getName().capitalizeAllWords,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<ITypeBrandModelColor>.empty();
        }
        return widget.suggestions.where((ITypeBrandModelColor option) {
          return option
              .getName()
              .toLowerCase()
              .contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (ITypeBrandModelColor selection) {
        widget._controller!.text = selection.getName().capitalizeAllWords;
        widget.onAccept(selection.getId());
      },
      optionsViewBuilder: (BuildContext context,
          AutocompleteOnSelected<ITypeBrandModelColor> onSelected,
          Iterable<ITypeBrandModelColor> options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
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
                        widget.onAccept(option.getId());
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
          if (fieldTextEditingController.text != widget._controller!.text) {
            fieldTextEditingController.text =
                widget._controller!.text.capitalizeAllWords;
          }
        });

        return CustomTextField(
          headerLabel: widget.headerLabelText,
          hintText: widget.hintText,
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          suffixIcon: widget.suffixIcon != null
              ? IconButton(
                  onPressed: () {
                    if (fieldTextEditingController.text.isEmpty) return;
                    widget.suffixIconAction
                        ?.call(fieldTextEditingController.text);
                  },
                  icon: widget.suffixIcon!,
                )
              : null,
          onFieldSubmitted: (String text) {
            widget.onSubmit?.call(null, text);
          },
          onChanged: (String text) {
            if (text.isEmpty) {
              widget.onClear?.call();
            }
            widget._controller!.value = TextEditingValue(
              text: text.capitalizeAllWords,
              selection: fieldTextEditingController.selection,
            );
          },
          onSave: widget.onSave,
          inputFormatters: widget.inputFormatters,
          validator: widget.fieldValidator,
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
