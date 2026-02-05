import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/update/update_service.dart';

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onDownload;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDownload,
  });

  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateService updateService,
  ) {
    return showDialog(
      context: context,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        onDownload: () async {
          try {
            await updateService.openDownloadUrl(updateInfo.downloadUrl);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download iniciado no navegador'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao abrir download: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Text(updateInfo.hasUpdate ? 'Atualização Disponível' : 'Você está atualizado'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UpdateVersionInfoCard(updateInfo: updateInfo),
              if (updateInfo.hasUpdate) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                UpdateReleaseNotesSection(updateInfo: updateInfo),
                const SizedBox(height: 12),
                UpdatePublishDateRow(updateInfo: updateInfo),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Depois'),
        ),
        if (updateInfo.hasUpdate)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onDownload();
            },
            icon: const Icon(Icons.download),
            label: const Text('Baixar Atualização'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }
}

class UpdateVersionInfoCard extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateVersionInfoCard({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final bg = updateInfo.hasUpdate ? Colors.blue.shade50 : Colors.green.shade50;
    final border = updateInfo.hasUpdate ? Colors.blue.shade200 : Colors.green.shade200;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _VersionColumn(
            title: 'Versão Atual',
            value: updateInfo.currentVersion,
            valueColor: null,
            alignEnd: false,
          ),
          if (updateInfo.hasUpdate) ...[
            Icon(Icons.arrow_forward, color: Colors.blue.shade700),
            _VersionColumn(
              title: 'Nova Versão',
              value: updateInfo.latestVersion,
              valueColor: Colors.blue.shade700,
              alignEnd: true,
            ),
          ] else ...[
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
          ],
        ],
      ),
    );
  }
}

class _VersionColumn extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _VersionColumn({
    required this.title,
    required this.value,
    required this.valueColor,
    required this.alignEnd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor ?? cs.onSurface,
              ),
        ),
      ],
    );
  }
}

class UpdateReleaseNotesSection extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateReleaseNotesSection({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Novidades',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(updateInfo.releaseNotes),
        ),
      ],
    );
  }
}

class UpdatePublishDateRow extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdatePublishDateRow({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          'Publicado em ${df.format(updateInfo.publishedAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
