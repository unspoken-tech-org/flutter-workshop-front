import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/update/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;
  final VoidCallback onDownload;
  final Future<void> Function({
    void Function(double? progress)? onProgress,
    void Function(UpdateInstallStage stage)? onStageChange,
  })?
  onSilentInstall;

  const UpdateDialog({
    super.key,
    required this.updateInfo,
    required this.onDownload,
    this.onSilentInstall,
  });

  static Future<void> show(
    BuildContext context,
    UpdateInfo updateInfo,
    UpdateService updateService,
  ) {
    Future<void> openBrowser() async {
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
    }

    final canSilentInstall =
        Platform.isWindows && updateInfo.supportsSilentInstall;

    return showDialog(
      context: context,
      builder: (_) => UpdateDialog(
        updateInfo: updateInfo,
        onDownload: openBrowser,
        onSilentInstall: canSilentInstall
            ? ({onProgress, onStageChange}) => updateService.downloadAndInstall(
                updateInfo,
                onProgress: onProgress,
                onStageChange: onStageChange,
              )
            : null,
      ),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isInstalling = false;
  double? _progress;
  UpdateInstallStage? _stage;
  String? _installError;

  String get _stageLabel => switch (_stage) {
    UpdateInstallStage.downloading =>
      _progress != null
          ? 'Baixando atualização... ${(_progress! * 100).round()}%'
          : 'Baixando atualização...',
    UpdateInstallStage.verifying => 'Verificando integridade do instalador...',
    UpdateInstallStage.launching => 'Iniciando instalador...',
    null => 'Preparando atualização...',
  };

  Future<void> _startSilentInstall() async {
    final install = widget.onSilentInstall;
    if (install == null || _isInstalling) return;
    setState(() {
      _isInstalling = true;
      _progress = null;
      _stage = UpdateInstallStage.downloading;
      _installError = null;
    });
    try {
      await install(
        onProgress: (value) {
          if (!mounted) return;
          setState(() => _progress = value);
        },
        onStageChange: (stage) {
          if (!mounted) return;
          setState(() => _stage = stage);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInstalling = false;
        _installError =
            'Não foi possível instalar automaticamente ($e). Você pode baixar pelo navegador.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateInfo = widget.updateInfo;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.system_update, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Text(
            updateInfo.hasUpdate
                ? 'Atualização Disponível'
                : 'Você está atualizado',
          ),
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
              if (_isInstalling) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 8),
                Text(_stageLabel, style: Theme.of(context).textTheme.bodySmall),
              ],
              if (_installError != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _installError!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isInstalling ? null : () => Navigator.of(context).pop(),
          child: const Text('Depois'),
        ),
        if (updateInfo.hasUpdate)
          if (_installError != null || widget.onSilentInstall == null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDownload();
              },
              icon: const Icon(Icons.open_in_browser),
              label: Text(
                _installError != null
                    ? 'Abrir no Navegador'
                    : 'Baixar Atualização',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isInstalling ? null : _startSilentInstall,
              icon: const Icon(Icons.download),
              label: const Text('Atualizar Agora'),
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
    final bg = updateInfo.hasUpdate
        ? Colors.blue.shade50
        : Colors.green.shade50;
    final border = updateInfo.hasUpdate
        ? Colors.blue.shade200
        : Colors.green.shade200;

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
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
