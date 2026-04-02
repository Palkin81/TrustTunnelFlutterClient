import Flutter
import TrustTunnelClient
import VpnClientFramework

public class VpnPlugin: NSObject, FlutterPlugin {
    private static var vpnApi: IVpnManagerImpl?
    private static var deepLink: IDeepLink?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()

        // TODO: Made separated plugin initialization
        // Konstantin Gorynin <k.gorynin@adguard.com>, 25 August 2025
        // Setup all platform managers
        let vpnImpl = IVpnManagerImpl(bundleIdentifier: "com.adguard.TrustTunnel.Extension",
                                              appGroup: "group.com.adguard.TrustTunnel")
        IVpnManagerSetup.setUp(binaryMessenger: messenger, api: vpnImpl)

        let deepLinkImpl = IDeepLinkImpl()
        IDeepLinkSetup.setUp(binaryMessenger: messenger, api: deepLinkImpl)

        let events = FlutterEventChannel(
            name: "vpn_plugin_event_channel", binaryMessenger: messenger)
        events.setStreamHandler(vpnImpl)

        let events_querylog = FlutterEventChannel(
            name: "vpn_plugin_event_channel_query_log", binaryMessenger: messenger)
        events_querylog.setStreamHandler(vpnImpl.queryLogHandler)

        self.vpnApi = vpnImpl
    }
}

final class IVpnManagerImpl: NSObject, IVpnManager, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var vpnManager: VpnManager?
    var queryLogHandler = QueryLogStreamHandler()
    
    init(bundleIdentifier: String, appGroup: String) {
        super.init()
        self.vpnManager = VpnManager(bundleIdentifier: bundleIdentifier, appGroup: appGroup, stateChangeCallback: { [weak self] newState in
            self?.state = VpnManagerState(rawValue: newState)!
        },
        connectionInfoCallback: { [weak self] info in
            DispatchQueue.main.async {
                self?.queryLogHandler.emitQueryLog(info)
            }
        })
    }

    private var state: VpnManagerState = .disconnected {
        didSet {
            NSLog("[VpnPlugin] State changed: \(oldValue) -> \(state)")
            DispatchQueue.main.async {
                self.emitState(self.state)
            }
        }
    }

    // MARK: - IVpnManager (Pigeon HostApi)

    func start(serverName: String, config: String) throws {
        guard let vpnManager = vpnManager else {
            NSLog("[VpnPlugin] ERROR: VpnManager is not initialized")
            throw PigeonError(
                code: "VPN_MANAGER_NOT_INITIALIZED",
                message: "VpnManager is not initialized",
                details: nil
            )
        }
        NSLog("[VpnPlugin] Starting VPN for server: \(serverName)")
        NSLog("[VpnPlugin] Config length: \(config.count) chars")
        do {
            try vpnManager.start(serverName: serverName, config: config)
            NSLog("[VpnPlugin] VPN start request sent successfully")
        } catch {
            NSLog("[VpnPlugin] ERROR starting VPN: \(error.localizedDescription)")
            throw error
        }
    }

    func updateConfiguration(serverName: String?, config: String?) throws {
        // TODO: Implement when TrustTunnelClient supports updateConfiguration
        // Метод ещё не добавлен в библиотеку TrustTunnelClient
    }

    func stop() throws {
        guard let vpnManager = vpnManager else {
            NSLog("[VpnPlugin] ERROR: VpnManager is not initialized")
            throw PigeonError(
                code: "VPN_MANAGER_NOT_INITIALIZED",
                message: "VpnManager is not initialized",
                details: nil
            )
        }
        NSLog("[VpnPlugin] Stopping VPN")
        do {
            try vpnManager.stop()
            NSLog("[VpnPlugin] VPN stop request sent successfully")
        } catch {
            NSLog("[VpnPlugin] ERROR stopping VPN: \(error.localizedDescription)")
            throw error
        }
    }

    func getCurrentState() throws -> VpnManagerState {
        return state
    }

    // MARK: - FlutterStreamHandler (EventChannel)

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        emitState(state)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    private func emitState(_ s: VpnManagerState) {
        eventSink?(s.rawValue)
    }
}

final class QueryLogStreamHandler : NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var queue: [String] = []

    override init() {
        super.init()
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        for log in queue {
            self.eventSink!(log)
        }
        queue = []
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }

    func emitQueryLog(_ s: String) {
        if self.eventSink == nil {
            queue.append(s)
        } else {
            self.eventSink!(s)
        }
    }
}

final class IDeepLinkImpl : NSObject, IDeepLink {
    func decode(uri: String) throws -> String {
        return try TrustTunnelDeepLink.decodeDeeplink(_: uri)
    }
}
