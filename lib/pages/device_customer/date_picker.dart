import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';

class DatePicker extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const DatePicker({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  DateTime date = DateTime.now();

  void showDatePicker(BuildContext context) async {
    var results = await showCalendarDatePicker2Dialog(
      context: context,
      dialogSize: const Size(400, 400),
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
    );

    if (results == null) return;

    setState(() {
      date = results.first ?? DateTime.now();
    });

    widget.onDateSelected(date);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDatePicker(context),
      child: Container(
        width: 170,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range_sharp, size: 24),
            const SizedBox(width: 8),
            Text(date.formatDate()),
          ],
        ),
      ),
    );
  }
}
