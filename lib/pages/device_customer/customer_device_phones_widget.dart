import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/models/customer_device/customer_phones.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';

class CustomerDevicePhonesWidget extends StatefulWidget {
  final List<CustomerPhones> phones;
  const CustomerDevicePhonesWidget({super.key, required this.phones});

  @override
  State<CustomerDevicePhonesWidget> createState() =>
      _CustomerDevicePhonesWidgetState();
}

class _CustomerDevicePhonesWidgetState extends State<CustomerDevicePhonesWidget>
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      isExpanded = !isExpanded;
      if (isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
                'Numero Principal: ${PhoneUtils.formatPhone(widget.phones.firstWhere((e) => e.isMain).number)}'),
            const SizedBox(width: 4),
            IconButton(
              onPressed: _toggleExpanded,
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
            ),
          ],
        ),
        SizeTransition(
          sizeFactor: _animation,
          child: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
                'Numeros Secundários: ${widget.phones.where((e) => !e.isMain).map((e) => PhoneUtils.formatPhone(e.number)).join(', ')}'),
          ),
        ),
      ],
    );
  }
}
