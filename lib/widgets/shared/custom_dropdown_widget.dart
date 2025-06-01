import 'package:flutter/material.dart';

class CustomDropdownWidget<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final Function(T?)? onChanged;
  final double borderRadius;
  final Color borderColor;
  final double width;
  final double height;
  final bool isInvalid;

  const CustomDropdownWidget({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.borderRadius = 8,
    this.borderColor = Colors.grey,
    this.width = 170,
    this.height = 40,
    this.isInvalid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isInvalid ? Colors.red : borderColor,
              width: 1,
            ),
          ),
          child: DropdownButton(
            value: value,
            borderRadius: BorderRadius.circular(borderRadius),
            underline: Container(),
            dropdownColor: Colors.white,
            focusColor: Colors.white,
            isExpanded: true,
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
