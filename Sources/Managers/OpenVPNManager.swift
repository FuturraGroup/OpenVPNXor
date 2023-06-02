//
//  VPNManager.swift
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 12/06/2021.
//

import Foundation
import NetworkExtension

public enum VPNStatus : Int {
    
    /** @const VPNStatusInvalid The VPN is not configured. */
    case invalid = 0
    
    /** @const VPNStatusDisconnected The VPN is disconnected. */
    case disconnected = 1
    
    /** @const VPNStatusConnecting The VPN is connecting. */
    case connecting = 2
    
    /** @const VPNStatusConnected The VPN is connected. */
    case connected = 3
    
    /** @const VPNStatusReasserting The VPN is reconnecting following loss of underlying network connectivity. */
    case reasserting = 4
    
    /** @const VPNStatusDisconnecting The VPN is disconnecting. */
    case disconnecting = 5
}

extension NEVPNStatus {
    var vpnStatus: VPNStatus? {
        switch self {
        case .invalid: return .invalid
        case .connected: return .connected
        case .connecting: return .connecting
        case .disconnected: return .disconnected
        case .disconnecting: return .disconnecting
        case .reasserting: return .reasserting
        default : return nil
        }
    }
}

public enum VPNCollectionErrorType: Int, RawRepresentable {
    case ConfigurationInvalid
    case ConfigurationDisabled
    case UnkownError
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .ConfigurationInvalid:
            return "ConfigurationInvalid"
        case .ConfigurationDisabled:
            return "ConfigurationDisabled"
        case .UnkownError:
            return "UnkownError"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "ConfigurationInvalid":
            self = .ConfigurationInvalid
        case "ConfigurationDisabled":
            self = .ConfigurationDisabled
        case "UnkownError":
            self = .UnkownError
        default:
            return nil
        }
    }
}

public protocol VPNManagerDelegate {
    func VpnManagerConnectionFailed(error : VPNCollectionErrorType , localizedDescription : String)
    func VpnManagerConnected()
    func VpnManagerDisconnected()
    func VpnManagerProfileSaved()
    func VpnManagerPacketTransmitted(with bitrate: Bitrate)
    func VpnManagerLogs(log : String?)
}

public class OpenVPNManager: NSObject {
    
    struct Config {
        var openvpnPackettunnelIdentifier:String
        var appGroupIdentifier:String
    }
    
    public var vpnStatus = VPNStatus(rawValue: 0)
    public var onVPNStatusChange: ((_ status: VPNStatus) -> Void)?
    public var delegate : VPNManagerDelegate?
    public var disconnectOnSleep:Bool = false
    public var appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    public var isOnDemandEnabled:Bool? = true
    
    // Shared singleton
    public static let shared = OpenVPNManager()
    
    var statistics: NetworkTrafficStatistics?
    var providerManager: NETunnelProviderManager?
    private static var config:Config!
    var wormhole: MMWormhole?
    
    // Private init
    override private init() {
        guard OpenVPNManager.config != nil else {
            fatalError("OpenVPNXor Error - you must call setup before accessing ExtensionManager.shared")
        }
        super.init()
        
    }
    
    class public func setup(openvpnPacketTunnelIdentifier:String,appGroupIdentifier:String){
        
        OpenVPNManager.config = Config(openvpnPackettunnelIdentifier: openvpnPacketTunnelIdentifier, appGroupIdentifier: appGroupIdentifier)
        OpenVPNManager.shared.initializeDependencies()
        OpenVPNManager.shared.listenToChangeLogs()
        OpenVPNManager.shared.initializeProviderManager { completed in
            print("OpenVPNXor: initialization completed");
        }
    }
    
    private func initializeProviderManager(callback: @escaping ((Bool) -> Void)) {
        // load any existing managers
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            guard error == nil else {
                callback(false)
                return
            }
            guard let strongSelf = self else {
                callback(false)
                return
            }
            
            let vpnProfileAllowed = (managers?.count ?? 0) > 0
            
            // if there isn't an existing manager, create one
            if let existingManager = managers?.first {
                strongSelf.providerManager = existingManager
                callback(vpnProfileAllowed)
            } else {
                strongSelf.providerManager = NETunnelProviderManager()
                strongSelf.providerManager?.loadFromPreferences { error in
                    guard error == nil else {
                        callback(false)
                        return
                    }
                    callback(vpnProfileAllowed)
                }
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onUpdateVpnStatus(_:)), name: .NEVPNStatusDidChange, object: nil)
    }
    
    private func initializeDependencies(){
        wormhole = MMWormhole(
            applicationGroupIdentifier: OpenVPNManager.config.appGroupIdentifier,
            optionalDirectory: "openvpnlogs")
    }
    
    private func startNetworkStatistics() {
        statistics?.stopGathering()
        statistics = nil
        
        statistics = NetworkTrafficStatistics(with: 1.0) { [weak self] (bitrate) in
            guard let `self` = self else { return }
            self.delegate?.VpnManagerPacketTransmitted(with: bitrate)
        }
    }
    
    private func listenToChangeLogs() {
        wormhole?.listenForMessage(withIdentifier: "openvpn_log", listener: { messageObject in
            
            if let messageObject = messageObject as? String {
                self.delegate?.VpnManagerLogs(log: messageObject)
            }
        })
    }
    
    @objc private func onUpdateVpnStatus(_ notification: NSNotification){
        
        let nevpnconn = notification.object as! NEVPNConnection
        let status = nevpnconn.status
        vpnStatus = nevpnconn.status.vpnStatus
        
        if let callback = onVPNStatusChange {
            callback (vpnStatus ?? .invalid)
        }
        if delegate == nil{
            return
        }
        if status == .disconnected{
            statistics?.stopGathering()
            statistics = nil
            self.delegate!.VpnManagerDisconnected()
        }
        else if status == .connected{
            OpenVPNManager.shared.startNetworkStatistics()
            self.delegate!.VpnManagerConnected()
        }
    }
    
    /* You can change this method. Currently it requires the name of file and extension will be added.
     */
    public func configureVPN(openVPNConfiguration: Data?, login:String, pass:String, callback: ((Bool) -> Void)?) {
        
        guard let openVPNData = openVPNConfiguration else {
            fatalError("OpenVPNXor Error: Configuration not provided")
        }
        
        let tunnelProtocol = NETunnelProviderProtocol()
        // must be non-nil
        tunnelProtocol.serverAddress = "ServerAddress" // just to display
        tunnelProtocol.providerBundleIdentifier = OpenVPNManager.config.openvpnPackettunnelIdentifier
        
        // Set this to true so the system handles the disconnect when the main app isn't running
        tunnelProtocol.disconnectOnSleep = self.disconnectOnSleep
        
        // Use `providerConfiguration` to save content of the ovpn file.
        // if you need to use credential pass two extra keys "user" and "pass" in Data type
        
        var configuration: Dictionary = [String: Any]()
        configuration["ovpn"] = openVPNData
        configuration["app-group"] = OpenVPNManager.config.appGroupIdentifier
        configuration["user"] = login
        configuration["pass"] = pass
        tunnelProtocol.providerConfiguration = configuration
        
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                callback?(false)
                return
            }
            guard let strongSelf = self else { return }
            
            strongSelf.providerManager?.protocolConfiguration = tunnelProtocol
            strongSelf.providerManager?.localizedDescription = self?.appName
            strongSelf.providerManager?.isEnabled = true
            strongSelf.providerManager?.isOnDemandEnabled = self?.isOnDemandEnabled ?? true

            // Save configuration in the Network Extension preferences
            strongSelf.providerManager?.saveToPreferences { error in
                if let error = error {
                    print("error in saving to preferences: \(error.localizedDescription)")
                    self?.delegate?.VpnManagerConnectionFailed(error: .UnkownError, localizedDescription: error.localizedDescription)
                    callback?(false)
                } else {
                    callback?(true)
                    self?.delegate?.VpnManagerProfileSaved()
                }
            }
        }
    }
    
    public func connectVPN(callback: @escaping (String?) -> Void) {
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                callback(error?.localizedDescription)
                return
            }
            do {
                try self?.providerManager?.connection.startVPNTunnel()
            } catch {
                self?.delegate?.VpnManagerConnectionFailed(error: .UnkownError, localizedDescription: error.localizedDescription)
                callback("error in starting tunnel \(error)")
                print("OpenVPNXor: error in starting tunnel")
            }
        }
    }
    
    public func disconnectVPN(callback: (() -> Void)? = nil) {
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else { return }
            self?.providerManager?.connection.stopVPNTunnel()
            if let callbackFunction = callback {
                callbackFunction()
            }
        }
    }
    
    private func sendMessageToProvider(message: String, callback: @escaping (String?) -> Void) {
        guard let messageData = message.data(using: .utf8) else { return }
        providerManager?.loadFromPreferences { [weak self] error in
            guard error == nil else {
                callback(nil)
                return
            }
            
            if let session = self?.providerManager?.connection as? NETunnelProviderSession {
                do {
                    try session.sendProviderMessage(messageData) { response in
                        if let messageResponse = response, let responseString = String(data: messageResponse, encoding: .utf8) {
                            print("send message response: \(responseString)")
                            callback(responseString)
                        } else {
                            print("No response")
                            callback("")
                        }
                    }
                } catch {
                    print("Couldn't send message")
                    callback(nil)
                }
            } else {
                callback(nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .NEVPNStatusDidChange, object: nil)
    }
}
