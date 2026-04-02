import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:trusttunnel/feature/settings/connection_logs/model/connection_log_entry.dart';

/// {@template connection_logger}
/// Сервис для логирования событий подключения VPN.
///
/// Сохраняет последние N записей лога в памяти.
/// {@endtemplate}
class ConnectionLogger extends ChangeNotifier {
  /// Максимальное количество записей в логе.
  static const int _maxLogs = 100;

  final List<ConnectionLogEntry> _logs = [];

  /// Текущие логи подключения.
  List<ConnectionLogEntry> get logs => List.unmodifiable(_logs);

  /// Добавляет запись в лог.
  void log({
    required ConnectionLogLevel level,
    required String message,
    String? serverName,
  }) {
    final entry = ConnectionLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      serverName: serverName,
    );

    _logs.add(entry);

    // Удаляем старые записи, если превышен лимит
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    notifyListeners();
  }

  /// Добавляет запись с уровнем info.
  void info(String message, {String? serverName}) {
    log(level: ConnectionLogLevel.info, message: message, serverName: serverName);
  }

  /// Добавляет запись с уровнем error.
  void error(String message, {String? serverName}) {
    log(level: ConnectionLogLevel.error, message: message, serverName: serverName);
  }

  /// Добавляет запись с уровнем debug.
  void debug(String message, {String? serverName}) {
    log(level: ConnectionLogLevel.debug, message: message, serverName: serverName);
  }

  /// Очищает все логи.
  void clear() {
    _logs.clear();
    notifyListeners();
  }

  /// Экспортирует логи в виде строки.
  String export() {
    return _logs.map((e) => e.toString()).join('\n');
  }
}
