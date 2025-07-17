import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_text_styles.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/models/customer/minified_customer.dart';
import 'package:flutter_workshop_front/utils/cpf_utils.dart';
import 'package:flutter_workshop_front/utils/phone_utils.dart';
import 'package:flutter_workshop_front/widgets/hoverable_card.dart';

class CustomerCard extends StatelessWidget {
  final MinifiedCustomerModel customer;
  final Function(int) onTap;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String formatedPhone = PhoneUtils.formatPhone(customer.mainPhone);
    String formatedCpf = CpfUtils.formatCpf(customer.cpf);
    return HoverableCard(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      padding: const EdgeInsets.all(24.0),
      onTap: () => onTap(customer.customerId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            customer.name.capitalizeAllWords,
            style: WsTextStyles.h2,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                        icon: Icons.tag,
                        label: 'ID',
                        value: customer.customerId.toString()),
                    const SizedBox(height: 12),
                    if (customer.email != null)
                      _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: customer.email ?? ''),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'CPF',
                        value: formatedCpf),
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Telefone',
                        value: formatedPhone),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text('$label: ',
            style: WsTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
        Text(value, style: WsTextStyles.body2),
      ],
    );
  }
}
