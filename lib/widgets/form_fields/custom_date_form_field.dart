import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DatePickerType {
  single,
  range,
}

class CustomDateFormField extends StatefulWidget {
  final TextEditingController? dateController;
  final String? label;
  final String? headerLabel;
  final String? hintText;
  final String? value;
  final DatePickerType datePickerType;
  final void Function(String value)? onSave;
  final void Function(DateTime initialDate, DateTime? endDate)? onSelected;
  final void Function()? onClear;
  final String? Function(String? value)? validator;

  const CustomDateFormField({
    super.key,
    this.dateController,
    this.onSave,
    this.label,
    this.headerLabel,
    this.hintText,
    this.validator,
    this.value,
    this.onSelected,
    this.datePickerType = DatePickerType.single,
    this.onClear,
  });

  @override
  State<CustomDateFormField> createState() => _CustomDateFormFieldState();
}

class _CustomDateFormFieldState extends State<CustomDateFormField> {
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    dateController =
        widget.dateController ?? TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.headerLabel != null) ...[
          Text(
            widget.headerLabel!,
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
          controller: dateController,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: dateController.text.isEmpty
                  ? null
                  : () {
                      dateController.text = '';
                      widget.onClear?.call();
                    },
              icon: Icon(
                dateController.text.isEmpty
                    ? Icons.calendar_today
                    : Icons.close,
                color: Colors.grey.shade500,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.blue.shade300, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          validator: widget.validator,
          onSaved: (value) {
            widget.onSave?.call(value ?? '');
          },
          readOnly: true,
          onTap: () async {
            if (widget.datePickerType == DatePickerType.single) {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                dateController.text = DateFormat('dd/MM/yyyy').format(date);
                widget.onSelected?.call(date, null);
                setState(() {});
              }
            } else {
              final date = await showCalendarDatePicker2Dialog(
                context: context,
                dialogSize: const Size(400, 400),
                config: CalendarDatePicker2WithActionButtonsConfig(
                  calendarType: CalendarDatePicker2Type.range,
                ),
              );
              if (date != null) {
                var dates = List.of(date.nonNulls);
                if (dates.length == 1) {
                  dates.add(DateTime.now());
                }
                dateController.text = dates
                    .map((e) => DateFormat('dd/MM/yyyy').format(e))
                    .join(' - ');

                widget.onSelected?.call(
                  dates[0],
                  dates[1],
                );
                setState(() {});
              }
            }
          },
        ),
      ],
    );
  }
}
