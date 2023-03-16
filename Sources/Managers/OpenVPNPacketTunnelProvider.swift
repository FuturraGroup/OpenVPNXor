//
//  OpenVPNPacketTunnelProvider.swift
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 13/06/2021.
//

import Foundation
import NetworkExtension
import OSLog

// Extend NEPacketTunnelFlow to adopt OpenVPNAdapterPacketFlow protocol so that
// `self.packetFlow` could be sent to `completionHandler` callback of OpenVPNAdapterDelegate
// method openVPNAdapter(openVPNAdapter:configureTunnelWithNetworkSettings:completionHandler).
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}


open class OpenVPNPacketTunnelProvider : NEPacketTunnelProvider {
    
    lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()
    
    let vpnReachability = OpenVPNReachability()
    
    var startHandler: ((Error?) -> Void)?
    var stopHandler: (() -> Void)?
    
    var uniqueID: String?
    var wormhole: MMWormhole?
    
    override init() {
    }
    
    private func initializeDependencies(appGroup : String){
        wormhole = MMWormhole(
            applicationGroupIdentifier: appGroup,
            optionalDirectory: "openvpnlogs")
    }
    
    
    open override func startTunnel(options: [String : NSObject]? = nil, completionHandler: @escaping (Error?) -> Void) {
        
        // There are many ways to provide OpenVPN settings to the tunnel provider. For instance,
        // you can use `options` argument of `startTunnel(options:completionHandler:)` method or get
        // settings from `protocolConfiguration.providerConfiguration` property of `NEPacketTunnelProvider`
        // class. Also you may provide just content of a ovpn file or use key:value pairs
        // that may be provided exclusively or in addition to file content.
        // In our case we need providerConfiguration dictionary to retrieve content
        // of the OpenVPN configuration file. Other options related to the tunnel
        // provider also can be stored there.
        
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            fatalError()
        }
        
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else {
            fatalError()
        }
        
        guard let appGroup: String = providerConfiguration["app-group"] as? String else {
            fatalError()
        }
        
        uniqueID = UUID().uuidString
        
        initializeDependencies(appGroup: appGroup)
        
        let configuration = OpenVPNConfiguration()
        configuration.fileContent = ovpnFileContent
        configuration.clockTick = 1000
        configuration.settings = ["verb": "3"]
        configuration.disableClientCert = false
        configuration.forceCiphersuitesAESCBC = true
        
        // Uncomment this line if you want to keep TUN interface active during pauses or reconnections
        // configuration.tunPersist = true
        // Apply OpenVPN configuration
        let properties: OpenVPNProperties
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }
        
        
        if !properties.autologin {
            
            // Provide credentials if needed
            
            // If your VPN configuration requires user credentials you can provide them by
            // `protocolConfiguration.username` and `protocolConfiguration.passwordReference`
            // properties. It is recommended to use persistent keychain reference to a keychain
            // item containing the password.
            
            let credentials = OpenVPNCredentials()

            if let user = providerConfiguration["user"] as? String, let pass = providerConfiguration["pass"] as? String {
                credentials.username = user
                credentials.password = pass
                wormhole?.passMessageObject("OpenVPNXor: user \(user) pass \(pass)" as NSCoding, identifier: "openvpn_log")
            }
            
            do {
                try vpnAdapter.provide(credentials: credentials)
            } catch {
                completionHandler(error)
                return
            }
        }
        
        // Checking reachability. In some cases after switching from cellular to
        // WiFi the adapter still uses cellular data. Changing reachability forces
        // reconnection so the adapter will use actual connection.
        vpnReachability.startTracking { [weak self] status in
            guard status == .reachableViaWiFi else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }
        
        startHandler = completionHandler
        vpnAdapter.connect()
        
        if let uniqueid = uniqueID {
            wormhole?.passMessageObject("OpenVPNXor: Session \(uniqueid) started " as NSCoding, identifier: "openvpn_log")
        }
        
    }
    
    open override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        
        vpnAdapter.disconnect()
        
        if let uniqueid = uniqueID {
            wormhole?.passMessageObject("OpenVPNXor: Session \(uniqueid) disconnected because of NEProviderStopReason = \(reason.rawValue)" as NSCoding, identifier: "openvpn_log")
        }
    }
    
    open override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    open  override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }
    
    open  override func wake() {
        
    }
}

extension OpenVPNPacketTunnelProvider : OpenVPNAdapterDelegate {
    
    public func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings, completionHandler: @escaping (OpenVPNAdapterPacketFlow?) -> Void) {
        setTunnelNetworkSettings(networkSettings) { (error) in
            completionHandler(error == nil ? self.packetFlow : nil)
        }
    }
    
    public func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
        // Handle only fatal errors
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        wormhole?.passMessageObject("OpenVPNXor: Session disconnected error \((error as NSError).userInfo)" as NSCoding, identifier: "openvpn_log")
        
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        
        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }
    
    public func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
        
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            
            guard let startHandler = startHandler else { return }
            
            startHandler(nil)
            self.startHandler = nil
            wormhole?.passMessageObject("OpenVPNXor: Session connected" as NSCoding, identifier: "openvpn_log")
            
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            
            stopHandler()
            self.stopHandler = nil
            
        case .reconnecting:
            reasserting = true
            wormhole?.passMessageObject("OpenVPNXor: Session reconnecting" as NSCoding, identifier: "openvpn_log")
            
        case .info:
            break
        default:
            break
        }
    }
    
    public func openVPNAdapterDidReceiveClockTick(_ openVPNAdapter: OpenVPNAdapter) {
        var toSave = ""
        let formatter = ByteCountFormatter();
        formatter.countStyle = ByteCountFormatter.CountStyle.binary

        toSave+="_"
        toSave += formatter.string(for: openVPNAdapter.transportStatistics.bytesIn)!
        toSave+="_"
        toSave += formatter.string(for: openVPNAdapter.transportStatistics.bytesOut)!
        
        if #available(iOSApplicationExtension 10.0, *) {
            os_log("openVPNAdapter %{public}@ ", log: .default, type: .debug, openVPNAdapter.connectionInformation.debugDescription)
        } else {
            // Fallback on earlier versions
        }
    }
    
    public func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
        wormhole?.passMessageObject("OpenVPNXor: \(logMessage)" as NSCoding, identifier: "openvpn_log")
    }    
}
