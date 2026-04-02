import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:trusttunnel/common/extensions/context_extensions.dart';
import 'package:trusttunnel/data/model/server.dart';
import 'package:trusttunnel/data/model/vpn_state.dart';
import 'package:trusttunnel/feature/routing/routing/widgets/scope/routing_scope.dart';
import 'package:trusttunnel/feature/server/server_details/widgets/server_details_popup.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope.dart';
import 'package:trusttunnel/feature/server/servers/widget/scope/servers_scope_aspect.dart';
import 'package:trusttunnel/feature/server/servers/widget/servers_card_connection_button.dart';
import 'package:trusttunnel/feature/settings/connection_logs/model/connection_logger_singleton.dart';
import 'package:trusttunnel/feature/settings/excluded_routes/widgets/scope/excluded_routes_scope.dart';
import 'package:trusttunnel/feature/vpn/widgets/vpn_scope.dart';
import 'package:trusttunnel/widgets/common/custom_list_tile_separated.dart';

class ServersCard extends StatefulWidget {
  final Server server;

  const ServersCard({
    super.key,
    required this.server,
  });

  @override
  State<ServersCard> createState() => _ServersCardState();
}

class _ServersCardState extends State<ServersCard> {
  late VpnState _vpnStatus;

  late Server? _pickedServer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _vpnStatus = VpnScope.vpnControllerOf(context).state;
    _pickedServer = ServersScope.controllerOf(
      context,
      aspect: ServersScopeAspect.selectedServer,
    ).selectedServer;
  }

  @override
  Widget build(BuildContext context) {
    final vpnManagerState = _pickedServer?.id == widget.server.id ? _vpnStatus : VpnState.disconnected;
    final isCurrentServer = _pickedServer?.id == widget.server.id;

    log('[ServersCard] Build: serverId=${widget.server.id}, serverName=${widget.server.serverData.name}, '
        'isCurrentServer=$isCurrentServer, vpnState=$vpnManagerState, pickedServerId=${_pickedServer?.id}');

    return CustomListTileSeparated(
      title: widget.server.serverData.name,
      titleStyle: context.textTheme.titleSmall,
      subtitle: widget.server.serverData.ipAddress,
      onTileTap: () => _pushServerDetailsScreen(
        context,
        server: widget.server,
      ),
      trailing: ServersCardConnectionButton(
        vpnManagerState: vpnManagerState,
        onPressed: () {
          log('[ServersCard] Button tapped: serverId=${widget.server.id}, vpnState=$vpnManagerState, isCurrent=$isCurrentServer');
          if (vpnManagerState != VpnState.disconnected && widget.server.id == _pickedServer?.id) {
            log('[ServersCard] Disconnecting from VPN');
            _disconnectFromVpn(context);
            _changeServer(context, null);
          } else {
            log('[ServersCard] Connecting to VPN: ${widget.server.serverData.name}');
            _connectToVpn(context, widget.server);
            _changeServer(context, widget.server.id);
          }
        },
        serverId: widget.server.id,
      ),
    );
  }

  void _changeServer(BuildContext context, String? serverId) =>
      ServersScope.controllerOf(context, listen: false).pickServer(serverId);

  Future<void> _disconnectFromVpn(BuildContext context) {
    final controller = VpnScope.vpnControllerOf(context);

    return controller.stop();
  }

  Future<void> _connectToVpn(
    BuildContext context,
    Server server,
  ) async {
    try {
      final controller = VpnScope.vpnControllerOf(context, listen: false);
      final excludedRoutes = ExcludedRoutesScope.controllerOf(context, listen: false).excludedRoutes;
      final routingProfile = RoutingScope.controllerOf(context, listen: false).routingList.firstWhere(
        (element) => element.id == server.serverData.routingProfileId,
      );

      final serverName = server.serverData.name;
      final serverIp = server.serverData.ipAddress;
      final serverDomain = server.serverData.domain;

      log('[ServersCard] Starting VPN connection to server: $serverName');
      log('[ServersCard] Server IP: $serverIp, Domain: $serverDomain');
      log('[ServersCard] Routing profile: ${routingProfile.data.name}, Excluded routes: ${excludedRoutes.length}');

      connectionLogger.info('Starting VPN connection', serverName: serverName);
      connectionLogger.debug('Server: $serverName, IP: $serverIp, Domain: $serverDomain');

      await controller.start(
        server: server,
        routingProfile: routingProfile,
        excludedRoutes: excludedRoutes,
      );

      log('[ServersCard] VPN start request completed');
      connectionLogger.info('VPN connection request sent', serverName: serverName);
    } catch (e, st) {
      final errorMessage = 'ERROR starting VPN: $e';
      log('[ServersCard] $errorMessage', error: e, stackTrace: st);
      connectionLogger.error('Connection failed: $e', serverName: server.serverData.name);

      if (context.mounted) {
        context.showInfoSnackBar(
          message: 'Ошибка подключения: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  void _pushServerDetailsScreen(
    BuildContext context, {
    required Server server,
  }) => context.push(
    ServerDetailsPopUp(
      serverId: server.id,
    ),
  );
}
