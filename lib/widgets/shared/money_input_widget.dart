import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/double_extensions.dart';

class MoneyInputWidget extends StatefulWidget {
  final String? label;
  final double initialValue;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Function(double) onChanged;

  const MoneyInputWidget({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.padding = const EdgeInsets.all(8),
    this.width = 200,
    this.boxShadow = const [
      BoxShadow(
        color: Colors.grey,
        spreadRadius: 1,
        blurRadius: 2,
      ),
    ],
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.borderRadius = 8,
  });

  @override
  State<MoneyInputWidget> createState() => _MoneyInputWidgetState();
}

class _MoneyInputWidgetState extends State<MoneyInputWidget> {
  final _controller = TextEditingController();
  double _lastLaborValue = 0;

  void _formatText() {
    String current = _controller.text;

    String digitsOnly = current.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      _controller.text = '';
      return;
    }

    int number = int.parse(digitsOnly);
    double formatted = _formatCurrency(number);
    _controller.value = TextEditingValue(
      text: formatted.toBrCurrency,
      selection: TextSelection.collapsed(offset: formatted.toBrCurrency.length),
    );
    _lastLaborValue = formatted;
  }

  double _formatCurrency(int value) {
    num reals = value ~/ 100;
    double cents = (value % 100) / 100;
    double total = reals + cents;
    return total;
  }

  @override
  void didUpdateWidget(covariant MoneyInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastLaborValue != widget.initialValue) {
      _controller.text = widget.initialValue.toBrCurrency;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialValue.toBrCurrency;
    _controller.addListener(_formatText);
  }

  @override
  void dispose() {
    _controller.removeListener(_formatText);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: widget.padding,
      width: widget.width,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
        boxShadow: widget.boxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label != null) ...[
            Text(widget.label!),
            const SizedBox(height: 8),
          ],
          TextFormField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.borderRadius!),
                borderSide: BorderSide(color: widget.borderColor!),
              ),
            ),
            onChanged: (value) {
              widget.onChanged(_lastLaborValue);
            },
          ),
        ],
      ),
    );
  }
}
