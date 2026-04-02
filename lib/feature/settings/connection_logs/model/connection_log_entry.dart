/// {@template connection_log_entry}
/// Запись лога подключения VPN.
///
/// Содержит информацию о событиях подключения/отключения и ошибках.
/// {@endtemplate}
class ConnectionLogEntry {
  /// {@template connection_log_entry_timestamp}
  /// Временная метка события.
  /// {@endtemplate}
  final DateTime timestamp;

  /// {@template connection_log_entry_level}
  /// Уровень важности лога.
  /// {@endtemplate}
  final ConnectionLogLevel level;

  /// {@template connection_log_entry_message}
  /// Сообщение лога.
  /// {@endtemplate}
  final String message;

  /// {@template connection_log_entry_server}
  /// Имя сервера (опционально).
  /// {@endtemplate}
  final String? serverName;

  /// {@macro connection_log_entry}
  const ConnectionLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.serverName,
  });

  /// Создает запись с уровнем info.
  ConnectionLogEntry.info({
    required DateTime timestamp,
    required String message,
    String? serverName,
  }) : this(
          timestamp: timestamp,
          level: ConnectionLogLevel.info,
          message: message,
          serverName: serverName,
        );

  /// Создает запись с уровнем error.
  ConnectionLogEntry.error({
    required DateTime timestamp,
    required String message,
    String? serverName,
  }) : this(
          timestamp: timestamp,
          level: ConnectionLogLevel.error,
          message: message,
          serverName: serverName,
        );

  /// Создает запись с уровнем debug.
  ConnectionLogEntry.debug({
    required DateTime timestamp,
    required String message,
    String? serverName,
  }) : this(
          timestamp: timestamp,
          level: ConnectionLogLevel.debug,
          message: message,
          serverName: serverName,
        );

  /// Форматирует временную метку.
  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  @override
  String toString() => '[$formattedTime] ${level.icon} $message';

  @override
  bool operator ==(covariant ConnectionLogEntry other) {
    if (identical(this, other)) return true;

    return other.timestamp == timestamp &&
        other.level == level &&
        other.message == message &&
        other.serverName == serverName;
  }

  @override
  int get hashCode => Object.hashAll([
    timestamp,
    level,
    message,
    serverName,
  ]);
}

/// {@template connection_log_level}
/// Уровень важности лога подключения.
/// {@endtemplate}
enum ConnectionLogLevel {
  /// Отладочная информация.
  debug,

  /// Обычная информация.
  info,

  /// Ошибка.
  error;

  /// Иконка для уровня.
  String get icon {
    return switch (this) {
      ConnectionLogLevel.debug => '🔍',
      ConnectionLogLevel.info => 'ℹ️',
      ConnectionLogLevel.error => '❌',
    };
  }
}
