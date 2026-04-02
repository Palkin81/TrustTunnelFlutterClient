import 'package:flutter/material.dart';
import 'package:trusttunnel/common/assets/asset_icons.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/common/extensions/theme_extensions.dart';
import 'package:trusttunnel/data/model/vpn_state.dart';
import 'package:trusttunnel/feature/settings/connection_logs/model/connection_logger_singleton.dart';
import 'package:trusttunnel/widgets/buttons/custom_icon_button.dart';
import 'package:trusttunnel/widgets/rotating_wrapper.dart';

/// {@template servers_card_connection_button}
/// Кнопка подключения/отключения VPN на карточке сервера.
///
/// Имеет три состояния с цветовой индикацией:
/// - **Синий** (connected) — VPN подключен
/// - **Красный** (disconnected) — VPN отключен, готов к подключению
/// - **Серый** (pending) — процесс подключения/отключения
/// {@endtemplate}
class ServersCardConnectionButton extends StatelessWidget {
  final VpnState vpnManagerState;
  final VoidCallback onPressed;
  final String serverId;
  final bool canInteract;

  const ServersCardConnectionButton({
    super.key,
    required this.serverId,
    required this.vpnManagerState,
    required this.onPressed,
    this.canInteract = true,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = isPendingResult(vpnManagerState);
    final isConnected = vpnManagerState == VpnState.connected;

    // Определяем цвет кнопки по состоянию:
    // - Синий (accent) — VPN подключен
    // - Красный (error) — VPN отключен, готов к подключению
    // - Серый (neutralDarkDisabled) — процесс подключения/отключения
    final Color buttonColor = switch (vpnManagerState) {
      VpnState.connected => context.colors.accent, // Синий
      VpnState.disconnected => context.colors.error, // Красный
      _ => context.colors.neutralDarkDisabled, // Серый для pending
    };

    connectionLogger.debug(
      'Button build: serverId=$serverId, state=$vpnManagerState, canInteract=$canInteract, color=$buttonColor',
    );

    return Theme(
      data: context.theme.copyWith(
        iconButtonTheme: pendingTheme(isPending, context),
      ),
      child: isPending
          ? RotatingWidget(
              duration: const Duration(seconds: 1),
              child: CustomIconButton.square(
                icon: AssetIcons.update,
                onPressed: canInteract
                    ? () {
                        connectionLogger.info('Tap ignored: pending state');
                      }
                    : null,
                size: 24,
                selected: true,
              ),
            )
          : CustomIconButton.square(
              icon: AssetIcons.powerSettingsNew,
              onPressed: canInteract
                  ? () {
                      connectionLogger.info('Button tapped: serverId=$serverId, fromState=$vpnManagerState');
                      onPressed();
                    }
                  : null,
              size: 24,
              selected: isConnected,
              color: buttonColor,
            ),
    );
  }

  /// Возвращает тему для кнопки в зависимости от состояния
  IconButtonThemeData pendingTheme(bool isPending, BuildContext context) {
    if (isPending) {
      return context.theme.extension<CustomFilledIconButtonTheme>()!.iconButtonInProgress;
    }
    return context.theme.extension<CustomFilledIconButtonTheme>()!.iconButton;
  }

  /// Проверяет, находится ли VPN в промежуточном состоянии
  bool isPendingResult(VpnState state) => state != VpnState.connected && state != VpnState.disconnected;
}
