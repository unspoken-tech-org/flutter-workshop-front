import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String? headerLabel;
  final String? fieldLabel;
  final String? value;
  final IconData? icon;
  final TextEditingController? controller;
  final bool readOnly;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final String? prefixText;
  final int? maxLines;
  final int? errorMaxLines;
  final String? hintText;
  final FocusNode? focusNode;
  final Widget? suffixIcon;
  final Color? selectedBorderColor;
  final String? Function(String?)? validator;
  final void Function(String?)? onSave;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    this.headerLabel,
    this.fieldLabel,
    this.value,
    this.icon,
    this.controller,
    this.readOnly = false,
    this.enabled = true,
    this.inputFormatters,
    this.keyboardType,
    this.prefixText,
    this.hintText,
    this.focusNode,
    this.suffixIcon,
    this.selectedBorderColor,
    this.validator,
    this.onSave,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.errorMaxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Controller próprio, de vida longa, usado quando o pai não fornece um.
  // Criar o controller no build apagava o texto digitado a cada rebuild.
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.value);
    }
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && _internalController == null) {
      _internalController = TextEditingController(text: widget.value);
      return;
    }
    if (widget.controller != null && _internalController != null) {
      _internalController!.dispose();
      _internalController = null;
      return;
    }
    if (_internalController == null) return;

    // Só sobrescreve o texto quando o valor de origem muda ou quando o campo
    // sai do modo de edição (ex.: cancelar); rebuilds comuns preservam o
    // rascunho digitado.
    final valueChanged = widget.value != oldWidget.value;
    final editingEnded = widget.readOnly && !oldWidget.readOnly;
    if (valueChanged || editingEnded) {
      _syncTextAfterBuild();
    }
  }

  // Alterar o texto notifica o TextFormField, que avisa o Form ancestral
  // (setState). Fazer isso dentro de didUpdateWidget dispara
  // "setState() called during build"; por isso a sincronização vai para
  // depois do frame.
  void _syncTextAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _internalController;
      if (!mounted || controller == null) return;
      final text = widget.value ?? '';
      if (controller.text != text) controller.text = text;
    });
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headerLabel = widget.headerLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (headerLabel != null) ...[
          Text(
            headerLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: _effectiveController,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          inputFormatters: widget.inputFormatters,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
          focusNode: widget.focusNode,
          validator: widget.validator,
          onSaved: widget.onSave,
          onFieldSubmitted: widget.onFieldSubmitted,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: widget.fieldLabel,
            hintText: widget.hintText,
            suffixIcon: widget.suffixIcon,
            errorMaxLines: widget.errorMaxLines,
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            prefixText: widget.prefixText,
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, size: 20, color: Colors.grey.shade600)
                : null,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 12.0,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                color: widget.selectedBorderColor ?? Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(color: Color(0xFF1F2937), fontSize: 14),
        ),
      ],
    );
  }
}
