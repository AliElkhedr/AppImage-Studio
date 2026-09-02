import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/models/build_log_entry.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class BuildConsoleDialog extends StatefulWidget {
  final Stream<BuildLogEntry> logStream;
  final Future<String> buildFuture;

  const BuildConsoleDialog({
    super.key,
    required this.logStream,
    required this.buildFuture,
  });

  @override
  State<BuildConsoleDialog> createState() => _BuildConsoleDialogState();
}

class _BuildConsoleDialogState extends State<BuildConsoleDialog> {
  final List<BuildLogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _isBuilding = true;
  String? _resultPath;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.logStream.listen((entry) {
      if (mounted) {
        setState(() {
          _logs.add(entry);
        });
        _scrollToBottom();
      }
    });

    widget.buildFuture.then((path) {
      if (mounted) {
        setState(() {
          _isBuilding = false;
          _resultPath = path;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isBuilding = false;
          String msg = error.toString();
          if (msg.startsWith('Exception: ')) {
            msg = msg.substring(11);
          }
          _errorMessage = msg;
        });
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openOutputFolder() async {
    if (_resultPath != null) {
      final dir = File(_resultPath!).parent.path;
      try {
        await Process.run('xdg-open', [dir]);
      } catch (_) {}
    }
  }

  Future<void> _testRunAppImage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (_resultPath != null) {
      try {
        await Process.start(_resultPath!, []);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToRun(e.toString()))),
          );
        }
      }
    }
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.header:
        return AppTheme.primaryCyan;
      case LogLevel.success:
        return const Color(0xFF00E676);
      case LogLevel.warning:
        return const Color(0xFFFFD600);
      case LogLevel.error:
        return const Color(0xFFFF5252);
      case LogLevel.info:
        return const Color(0xFFCFD8DC);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      backgroundColor: const Color(0xFF0D1117),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: Container(
        width: 780,
        height: 540,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _isBuilding ? Icons.sync : (_errorMessage != null ? Icons.error_outline : Icons.check_circle_outline),
                    color: _isBuilding ? AppTheme.primaryCyan : (_errorMessage != null ? Colors.red : Colors.green),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isBuilding
                            ? l10n.buildingTitle
                            : (_errorMessage != null ? l10n.buildFailedTitle : l10n.buildSuccessTitle),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        _isBuilding
                            ? l10n.buildingSubtitle
                            : (_resultPath ?? _errorMessage ?? ''),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isBuilding)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryCyan),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Terminal Screen
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF05080C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E2638)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        log.message,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12.5,
                          color: _getColorForLevel(log.level),
                          fontWeight: log.level == LogLevel.header ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_isBuilding && _resultPath != null) ...[
                  OutlinedButton.icon(
                    onPressed: _openOutputFolder,
                    icon: const Icon(Icons.folder_open, size: 16),
                    label: Text(l10n.openFolder),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryCyan,
                      side: const BorderSide(color: AppTheme.primaryCyan),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _testRunAppImage(context),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: Text(l10n.testRunApp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E676),
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                ElevatedButton(
                  onPressed: _isBuilding ? null : () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surfaceElevated,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
