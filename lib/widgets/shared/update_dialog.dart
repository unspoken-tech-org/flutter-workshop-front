import 'package:flutter_workshop_front/utils/snackbar_util.dart';
import 'package:flutter_workshop_front/core/format/br_format.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_workshop_front/core/extensions/date_time_extension.dart';

import '../../core/logging/app_logger.dart';
import '../../services/update/update_service.dart';

const String _logTag = 'UpdateDialog';

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
        AppLogger.info(_logTag, 'Download URL opened in browser');
        if (context.mounted) {
          SnackBarUtil().showSuccess('Download iniciado no navegador');
        }
      } catch (e, st) {
        AppLogger.error(
          _logTag,
          'Failed to open download URL',
          error: e,
          stackTrace: st,
        );
        if (context.mounted) {
          SnackBarUtil().showError('Erro ao abrir download: $e');
        }
      }
    }

    final canSilentInstall =
        Platform.isWindows && updateInfo.supportsSilentInstall;

    return _showAndLog(
      context,
      canSilentInstall: canSilentInstall,
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

  static Future<void> _showAndLog(
    BuildContext context, {
    required bool canSilentInstall,
    required WidgetBuilder builder,
  }) async {
    AppLogger.info(_logTag, 'Showing dialog (silentInstall=$canSilentInstall)');
    try {
      await showDialog<void>(context: context, builder: builder);
      AppLogger.info(_logTag, 'Dialog route completed');
    } catch (e, st) {
      AppLogger.error(_logTag, 'Dialog route failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isInstalling = false;
  double? _progress;
  UpdateInstallStage? _stage;
  String? _installError;

  @override
  void initState() {
    super.initState();
    AppLogger.info(
      _logTag,
      'Opened: ${widget.updateInfo.currentVersion} -> '
      '${widget.updateInfo.latestVersion} '
      'hasUpdate=${widget.updateInfo.hasUpdate} '
      'silentInstall=${widget.onSilentInstall != null}',
    );
  }

  @override
  void dispose() {
    AppLogger.info(_logTag, 'Closed (installing=$_isInstalling)');
    super.dispose();
  }

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
    AppLogger.info(
      _logTag,
      'Button "Atualizar Agora" clicked (installing=$_isInstalling)',
    );
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
          AppLogger.info(_logTag, 'Install stage: ${stage.name}');
          if (!mounted) return;
          setState(() => _stage = stage);
        },
      );
    } catch (e) {
      AppLogger.warning(_logTag, 'Silent install failed; showing fallback');
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
        Semantics(
          identifier: 'updateDialog.later',
          child: TextButton(
            onPressed: _isInstalling
                ? null
                : () {
                    AppLogger.info(_logTag, 'Button "Depois" clicked');
                    Navigator.of(context).pop();
                  },
            child: const Text('Depois'),
          ),
        ),
        if (updateInfo.hasUpdate)
          if (_installError != null || widget.onSilentInstall == null)
            Semantics(
              identifier: 'updateDialog.openBrowser',
              child: ElevatedButton.icon(
                onPressed: () {
                  AppLogger.info(
                    _logTag,
                    'Button "${_installError != null ? 'Abrir no Navegador' : 'Baixar Atualização'}" clicked',
                  );
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
              ),
            )
          else
            Semantics(
              identifier: 'updateDialog.download',
              child: ElevatedButton.icon(
                onPressed: _isInstalling ? null : _startSilentInstall,
                icon: const Icon(Icons.download),
                label: const Text('Atualizar Agora'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
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

class UpdateReleaseNotesSection extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateReleaseNotesSection({super.key, required this.updateInfo});

  @override
  State<UpdateReleaseNotesSection> createState() =>
      _UpdateReleaseNotesSectionState();
}

class _UpdateReleaseNotesSectionState extends State<UpdateReleaseNotesSection> {
  static const int _initialVisibleCount = 3;

  final ScrollController _scrollController = ScrollController();
  bool _expanded = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.updateInfo.releaseHistory;
    final headerText = entries.length > 1
        ? 'Novidades (${entries.length} versões)'
        : 'Novidades';
    final hasMore = entries.length > _initialVisibleCount;
    final visibleEntries = (!hasMore || _expanded)
        ? entries
        : entries.take(_initialVisibleCount).toList(growable: false);
    final remaining = entries.length - _initialVisibleCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headerText,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: entries.isEmpty
                  ? _FallbackReleaseNotesCard(
                      notes: widget.updateInfo.releaseNotes,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < visibleEntries.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          _ReleaseNoteEntryCard(
                            entry: visibleEntries[i],
                            isLatest: entries.length > 1 && i == 0,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              identifier: 'updateDialog.toggleNotes',
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? 'Mostrar menos'
                      : remaining == 1
                      ? 'Ver mais 1 versão anterior'
                      : 'Ver mais $remaining versões anteriores',
                ),
              ),
            ),
          ),
        ],
        if (widget.updateInfo.hasTruncatedHistory) ...[
          const SizedBox(height: 8),
          const _TruncatedHistoryNotice(),
        ],
      ],
    );
  }
}

class _FallbackReleaseNotesCard extends StatelessWidget {
  final String notes;

  const _FallbackReleaseNotesCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(notes),
    );
  }
}

class _ReleaseNoteEntryCard extends StatelessWidget {
  final ReleaseNoteEntry entry;
  final bool isLatest;

  const _ReleaseNoteEntryCard({required this.entry, required this.isLatest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = BrFormat.date(entry.publishedAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'v${entry.version}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isLatest) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Mais recente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                dateText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(entry.notes),
        ],
      ),
    );
  }
}

class _TruncatedHistoryNotice extends StatelessWidget {
  const _TruncatedHistoryNotice();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Exibindo apenas as versões mais recentes. Consulte o GitHub para o histórico completo.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey.shade600,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}

class UpdatePublishDateRow extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdatePublishDateRow({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          'Publicado em ${updateInfo.publishedAt.formatDateTime()}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
