import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/localization/localization.dart';
import 'package:trusttunnel/feature/settings/connection_logs/model/connection_log_entry.dart';
import 'package:trusttunnel/feature/settings/connection_logs/model/connection_logger.dart';
import 'package:trusttunnel/widgets/custom_app_bar.dart';

/// {@template connection_logs_screen}
/// Экран с логами подключения VPN.
/// {@endtemplate}
class ConnectionLogsScreen extends StatefulWidget {
  const ConnectionLogsScreen({super.key});

  @override
  State<ConnectionLogsScreen> createState() => _ConnectionLogsScreenState();
}

class _ConnectionLogsScreenState extends State<ConnectionLogsScreen> {
  late final ConnectionLogger _logger;

  @override
  void initState() {
    super.initState();
    _logger = ConnectionLogger();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: CustomAppBar(
      title: context.ln.connectionLogs,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: context.ln.copyLogs,
          onPressed: _copyLogs,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: context.ln.clearLogs,
          onPressed: _clearLogs,
        ),
      ],
    ),
    body: ValueListenableBuilder<List<ConnectionLogEntry>>(
      valueListenable: _logger,
      builder: (context, logs, _) {
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: context.colors.neutralDarkDisabled,
                ),
                const SizedBox(height: 16),
                Text(
                  context.ln.noConnectionLogs,
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: context.colors.neutralDarkDisabled,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[logs.length - 1 - index];
            return _LogTile(log: log);
          },
        );
      },
    ),
  );

  void _copyLogs() {
    final logsText = _logger.export();
    Clipboard.setData(ClipboardData(text: logsText));
    if (mounted) {
      context.showInfoSnackBar(message: context.ln.logsCopied);
    }
  }

  void _clearLogs() {
    _logger.clear();
    if (mounted) {
      context.showInfoSnackBar(message: context.ln.logsCleared);
    }
  }
}

class _LogTile extends StatelessWidget {
  final ConnectionLogEntry log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          log.formattedTime,
          style: context.textTheme.labelSmall?.copyWith(
            fontFamily: 'monospace',
            color: context.colors.neutralDarkDisabled,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          log.level.icon,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.message,
                style: context.textTheme.bodySmall?.copyWith(
                  color: log.level == ConnectionLogLevel.error
                      ? context.colors.error
                      : null,
                ),
              ),
              if (log.serverName != null) ...[
                const SizedBox(height: 4),
                Text(
                  log.serverName!,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colors.neutralDarkDisabled,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}
