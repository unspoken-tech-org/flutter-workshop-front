import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/design/ws_colors.dart';
import 'package:flutter_workshop_front/core/extensions/string_extensions.dart';
import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'package:flutter_workshop_front/models/customer_device/device_customer.dart';

/// Confirma a abertura de uma OS de revisão a partir da OS encerrada
/// [origin]. Mostra o que vai para a nova OS e o que acontece com a atual.
///
/// [onConfirm] cria a revisão e devolve o id da OS nova, ou `null` em erro
/// (a mensagem já foi publicada pelo controller). Enquanto cria, o diálogo
/// não fecha e os botões ficam desabilitados; com sucesso, fecha devolvendo
/// o id; com erro, continua aberto para tentar de novo.
class OpenRevisionDialog extends StatefulWidget {
  const OpenRevisionDialog({
    super.key,
    required this.origin,
    required this.onConfirm,
  });

  final DeviceCustomer origin;
  final Future<int?> Function() onConfirm;

  /// Abre o diálogo; devolve o id da OS de revisão criada, ou `null`.
  static Future<int?> show(
    BuildContext context, {
    required DeviceCustomer origin,
    required Future<int?> Function() onConfirm,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => OpenRevisionDialog(origin: origin, onConfirm: onConfirm),
    );
  }

  @override
  State<OpenRevisionDialog> createState() => _OpenRevisionDialogState();
}

class _OpenRevisionDialogState extends State<OpenRevisionDialog> {
  bool _opening = false;

  Future<void> _confirm() async {
    if (_opening) return;
    setState(() => _opening = true);
    final newId = await widget.onConfirm();
    if (!mounted) return;
    if (newId != null) {
      Navigator.of(context).pop(newId);
    } else {
      setState(() => _opening = false);
    }
  }

  void _close() {
    if (!_opening) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.origin;
    final width = MediaQuery.sizeOf(context).width;
    return PopScope(
      canPop: !_opening,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: WsColors.surface,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 560 ? width : 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(origin: origin, onClose: _opening ? null : _close),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      _Section(
                        icon: Icons.smartphone_outlined,
                        title: 'O que vai para a nova OS',
                        child: _Summary(origin: origin),
                      ),
                      _Section(
                        icon: Icons.info_outline,
                        title: 'O que acontece',
                        child: _Effects(originId: origin.deviceId),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Semantics(
                      identifier: 'deviceDetail.openRevision.cancel',
                      child: OutlinedButton(
                        onPressed: _opening ? null : _close,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    Semantics(
                      identifier: 'deviceDetail.openRevision.confirm',
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: WsColors.primary,
                          minimumSize: const Size(168, 40),
                        ),
                        onPressed: _opening ? null : _confirm,
                        icon: _opening
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.history, size: 18),
                        label: Text(_opening ? 'Abrindo…' : 'Abrir revisão'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.origin, required this.onClose});

  final DeviceCustomer origin;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final departure = origin.departureDate;
    final subtitle = departure == null
        ? 'A partir da OS #${origin.deviceId}'
        : 'A partir da OS #${origin.deviceId} · entregue em '
              '${BrFormat.date(departure)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: Color(0xFFE8EAF6),
            foregroundColor: WsColors.primary,
            child: Icon(Icons.history, size: 22),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  'Abrir revisão',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),
          Semantics(
            identifier: 'deviceDetail.openRevision.close',
            child: IconButton(
              tooltip: 'Fechar',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Colors.grey.shade700;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(icon, size: 16, color: color),
            Flexible(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.origin});

  final DeviceCustomer origin;

  @override
  Widget build(BuildContext context) {
    final technician = origin.technicianName;
    final device = [
      origin.typeName,
      '${origin.brandName} ${origin.modelName}',
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          _SummaryRow(
            label: 'Cliente',
            child: _Value(origin.customerName.capitalizeAllWords),
          ),
          _SummaryRow(label: 'Aparelho', child: _Value(device)),
          _SummaryRow(
            label: 'Cores',
            child: origin.deviceColors.isEmpty
                ? const _NotInformed()
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final color in origin.deviceColors)
                        _ColorChip(color),
                    ],
                  ),
          ),
          _SummaryRow(
            label: 'Técnico',
            child: technician == null || technician.trim().isEmpty
                ? const _NotInformed()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      _Value(technician.capitalizeAllWords),
                      Text(
                        'Copiado da OS #${origin.deviceId}. Dá para trocar '
                        'depois.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
          ),
          _SummaryRow(
            label: 'Defeito',
            child: origin.problem.trim().isEmpty
                ? const _NotInformed()
                : Tooltip(
                    message: origin.problem,
                    child: Text(
                      origin.problem,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final labelText = Text(
      label,
      style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Estreito: rótulo em cima do valor.
        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [labelText, child],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 76, child: labelText),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w500));
  }
}

class _NotInformed extends StatelessWidget {
  const _NotInformed();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Não informado',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip(this.color);

  final String color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: WsColors.surface,
        border: Border.all(color: const Color(0xFFE3E5EA)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(color, style: const TextStyle(fontSize: 13)),
    );
  }
}

class _Effects extends StatelessWidget {
  const _Effects({required this.originId});

  final int originId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        const _Effect(
          icon: Icons.check,
          color: WsColors.secondaryDark,
          text: TextSpan(
            children: [
              TextSpan(text: 'Uma nova OS é aberta em '),
              TextSpan(
                text: 'Novo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: ', marcada como '),
              TextSpan(
                text: 'revisão',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: '.'),
            ],
          ),
        ),
        _Effect(
          icon: Icons.lock_outline,
          color: WsColors.secondaryDark,
          text: TextSpan(
            text:
                'A OS #$originId continua encerrada, com os pagamentos e a '
                'data de saída.',
          ),
        ),
        _Effect(
          icon: Icons.edit_outlined,
          color: Colors.blue.shade800,
          muted: true,
          text: const TextSpan(
            text:
                'Valores começam zerados (sem taxa de orçamento). O técnico '
                'pode ser trocado no detalhe da nova OS.',
          ),
        ),
      ],
    );
  }
}

class _Effect extends StatelessWidget {
  const _Effect({
    required this.icon,
    required this.color,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final TextSpan text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: color),
        ),
        Expanded(
          child: Text.rich(
            text,
            style: TextStyle(
              height: 1.4,
              color: muted ? Colors.grey.shade700 : null,
            ),
          ),
        ),
      ],
    );
  }
}
