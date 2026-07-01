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

  const CustomerCard({super.key, required this.customer, required this.onTap});

  bool get hasEmail => customer.email?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return HoverableCard(
      padding: const EdgeInsets.all(16),
      onTap: () => onTap(customer.customerId),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  customer.name.capitalizeAllWords,
                  style: WsTextStyles.h3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade300, thickness: 0.5, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.tag,
                  label: 'ID',
                  value: customer.customerId.toString(),
                ),
              ),
              Expanded(
                child: _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: hasEmail ? customer.email! : '—',
                  mutedValue: !hasEmail,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoRow(
                  icon: Icons.person_outline,
                  label: 'CPF',
                  value: CpfUtils.formatCpf(customer.cpf),
                ),
              ),
              Expanded(
                child: _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: PhoneUtils.formatPhone(customer.mainPhone),
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
  final bool mutedValue;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mutedValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: WsTextStyles.body2.copyWith(color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: mutedValue ? Colors.grey.shade400 : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
