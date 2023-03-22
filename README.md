# OpenVPNXor
<p align="center">
  <img width="280" height="280" src="https://user-images.githubusercontent.com/7910769/225934094-82104453-cc6e-4723-a763-8f664eea2cab.png">
</p>

Library for connecting via OpenVPN protocol for iOS and macOS platforms. The library supports [Xor patch](https://github.com/clayface/openvpn_xorpatch).

## Overview
OpenVPNXor is a library that allows to configure and establish VPN connection using OpenVPN protocol easily. It is based on the original [openvpn3](https://github.com/OpenVPN/openvpn3) library so it has every feature the library has.

The library is designed to use in conjunction with [`NetworkExtension`](https://developer.apple.com/documentation/networkextension) framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly.

## Installation

OpenVPNXor is available with CocoaPods.

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate OpenVPNXor into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '11.0'
use_frameworks!

def sharedPods
  pod 'OpenVPNXor'
end

target 'Example VPN' do
sharedPods
end

target 'PacketTunnelOpenVPN' do
sharedPods
end
```
## Usage

First, you need to add a [Packet Tunnel Provider extension](https://developer.apple.com/documentation/networkextension/packet_tunnel_provider) and create [App Group identifier](https://developer.apple.com/documentation/xcode/configuring-app-groups).

Next, you need to call the `setup` method to initialize the library. You need to pass the bundle id of the Packet Tunnel extension and the App Group identifier to this method. App Group identifier to be same for App and packet tunnel provider.

```swift
import OpenVPNXor

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        OpenVPNManager.setup(openvpnPacketTunnelIdentifier: "com.example.bundle.PacketTunnelOpenVPN", appGroupIdentifier: "group.com.example.bundle")
        
        return true
    }
```

`PacketTunnelProvider` class configuration.
```swift
import NetworkExtension
import OpenVPNXor
import os.log

extension OSLog {
    private static var subsystem = Bundle.main.bundleIdentifier!
    /// Logs the view cycles like viewDidLoad.
    static let viewCycle = OSLog(subsystem: subsystem, category: "PacketTunnel")
}

class PacketTunnelProvider: OpenVPNPacketTunnelProvider {

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        /// Add code here to start the process of connecting the tunnel.
        os_log("startTunnel!", log: OSLog.viewCycle, type: .info)
        super.startTunnel(options: options, completionHandler: completionHandler)
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        /// Add code here to start the process of stopping the tunnel.
        super.stopTunnel(with: reason, completionHandler: completionHandler)
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        super.handleAppMessage(messageData, completionHandler: completionHandler)
    }
}
```
Saving configuration of the profile in the Network Extension preferences of the `.ovpn` file.
```swift
let configurationFileContent = // .ovpn config file
let login = "login"
let pass = "password"
            
OpenVPNManager.shared.configureVPN(openVPNConfiguration: configurationFileContent, login: login, pass:pass) { success in
    if success {
        /// Profile saved successfully.
    } else {
        /// Error saving profile. See the description of the error in the delegate method - `VpnManagerConnectionFailed`
    }
}
```
Start VPN connection by calling the following code.
```swift
OpenVPNManager.shared.connectVPN { errorDescription in
    /// If an error occurred while connecting, the `errorDescription` variable will contain a description of the error.
}
```
Disconnect VPN
```swift
OpenVPNManager.shared.disconnectVPN()
```
Using the `onVPNStatusChange` block, you can track changes in connection status.
```swift
OpenVPNManager.shared.onVPNStatusChange = { (status) in
    switch status {
    case .invalid:
        /** @const VPNStatusDisconnected The VPN is disconnected. */
        break
    case .disconnected:
        /** @const VPNStatusDisconnected The VPN is disconnected. */
        break
    case .connecting:
        /** @const VPNStatusConnecting The VPN is connecting. */
        break
    case .connected:
        /** @const VPNStatusConnected The VPN is connected. */
        break
    case .reasserting:
        /** @const VPNStatusReasserting The VPN is reconnecting following loss of underlying network connectivity. */
        break
    case .disconnecting:
        /** @const VPNStatusDisconnecting The VPN is disconnecting. */
        break
    }
}
```
Also at any time you can take the status with a variable `OpenVPNManager.shared.vpnStatus`
### VPNManagerDelegate
If an error occurred while saving the profile or connecting, this method will return a description of the error.
```swift
func VpnManagerConnectionFailed(error : VPNCollectionErrorType , localizedDescription : String)
```
The method will be called upon successful connection.
```swift
func VpnManagerConnected()
```
The method to be called after disconnecting from the VPN server.
```swift
func VpnManagerDisconnected()
```
The method will be called after successfully saving the configuration of the profile in the Network Extension preferences.
```swift
func VpnManagerProfileSaved()
```
Network Traffic Statistics
```swift
func VpnManagerPacketTransmitted(with bitrate: Bitrate) {
    print("NetworkTrafficStatistics - ", NetworkTrafficStatistics.formBitrateString(with: bitrate))
}
```
VPN session logs.
```swift
func VpnManagerLogs(log : String?)
```
## Contribute

Contributions for improvements are welcomed. Feel free to submit a pull request to help grow the library. If you have any questions, feature suggestions, or bug reports, please send them to [Issues](https://github.com/FuturraGroup/OpenVPNXor/issues).

## License

```
MIT License

Copyright (c) 2023 Futurra Group

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
