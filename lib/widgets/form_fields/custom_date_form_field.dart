import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DatePickerType { single, range }

/// Pure date logic behind [CustomDateFormField], kept apart for tests.
@visibleForTesting
class DateFieldSelection {
  DateFieldSelection._();

  static final DateFormat _format = DateFormat('dd/MM/yyyy');

  /// Dates shown in the field: `dd/MM/yyyy` or `dd/MM/yyyy - dd/MM/yyyy`.
  /// Unparseable parts are dropped.
  static List<DateTime> parse(String text) {
    final dates = <DateTime>[];
    for (final part in text.split(' - ')) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      try {
        dates.add(_format.parseStrict(trimmed));
      } on FormatException {
        // Not a date the field wrote; ignore it.
      }
    }
    return dates;
  }

  /// Date the single picker opens on: the selected one, else [now],
  /// clamped to `[firstDate, lastDate]`.
  static DateTime initialDate({
    required String text,
    required DateTime now,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    final selected = parse(text);
    final date = selected.isEmpty ? now : selected.first;
    if (date.isBefore(firstDate)) return firstDate;
    if (date.isAfter(lastDate)) return lastDate;
    return date;
  }

  /// Start and end of a range pick. With a single date the range runs
  /// until [now], or is that same day when the date is in the future,
  /// so the end is never before the start.
  static (DateTime, DateTime) range(List<DateTime> picked, DateTime now) {
    final sorted = List.of(picked)..sort();
    final start = sorted.first;
    if (sorted.length > 1) return (start, sorted.last);
    return (start, now.isBefore(start) ? start : now);
  }
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
  final bool enabled;
  final int errorMaxLines;
  final bool allowFutureDates;

  /// `Semantics.identifier` of the text field (`<page>.<field>`); the
  /// header label is a separate text, so the field itself has no label.
  final String? semanticsIdentifier;

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
    this.enabled = true,
    this.errorMaxLines = 1,
    this.allowFutureDates = false,
    this.semanticsIdentifier,
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
  void didUpdateWidget(CustomDateFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateController == null &&
        dateController.text != (widget.value ?? '')) {
      dateController.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    if (widget.dateController == null) {
      dateController.dispose();
    }
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
        Semantics(
          identifier: widget.semanticsIdentifier,
          child: TextFormField(
            controller: dateController,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
              ),
              border: const OutlineInputBorder(),
              suffixIcon: widget.enabled
                  ? IconButton(
                      onPressed: dateController.text.isEmpty
                          ? null
                          : () {
                              setState(dateController.clear);
                              widget.onClear?.call();
                            },
                      icon: Icon(
                        dateController.text.isEmpty
                            ? Icons.calendar_today
                            : Icons.close,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : Icon(Icons.calendar_today, color: Colors.grey.shade500),
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
              errorMaxLines: widget.errorMaxLines,
            ),
            validator: widget.validator,
            onSaved: (value) {
              widget.onSave?.call(value ?? '');
            },
            readOnly: true,
            onTap: () async {
              if (!widget.enabled) return;
              if (widget.datePickerType == DatePickerType.single) {
                final now = DateTime.now();
                final firstDate = DateTime(2000);
                final lastDate = widget.allowFutureDates ? DateTime(2100) : now;
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateFieldSelection.initialDate(
                    text: dateController.text,
                    now: now,
                    firstDate: firstDate,
                    lastDate: lastDate,
                  ),
                  firstDate: firstDate,
                  lastDate: lastDate,
                );
                if (!mounted) return;
                if (date != null) {
                  dateController.text = DateFormat('dd/MM/yyyy').format(date);
                  widget.onSelected?.call(date, null);
                  setState(() {});
                }
              } else {
                final lastDate = widget.allowFutureDates
                    ? DateTime(2100)
                    : DateTime.now();
                final date = await showCalendarDatePicker2Dialog(
                  context: context,
                  dialogSize: const Size(400, 400),
                  value: DateFieldSelection.parse(dateController.text),
                  config: CalendarDatePicker2WithActionButtonsConfig(
                    calendarType: CalendarDatePicker2Type.range,
                    lastDate: lastDate,
                  ),
                );
                if (!mounted) return;
                if (date != null) {
                  final picked = List.of(date.nonNulls);
                  if (picked.isEmpty) return;
                  final (start, end) = DateFieldSelection.range(
                    picked,
                    DateTime.now(),
                  );
                  dateController.text = [
                    start,
                    end,
                  ].map((e) => DateFormat('dd/MM/yyyy').format(e)).join(' - ');

                  widget.onSelected?.call(start, end);
                  setState(() {});
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
