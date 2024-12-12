import Foundation

public struct Bitrate {
    public var download: UInt32
    public var upload: UInt32
}

public class NetworkTrafficStatistics {
    
    private struct NetworkTraffic {
        var downloadCount: UInt32 = 0
        var uploadCount: UInt32 = 0
        
        mutating func updateCountsByAdding(_ statistics: NetworkTraffic) {
            downloadCount = UInt32((UInt64(downloadCount) + UInt64(statistics.downloadCount)) % UInt64(UInt32.max))
            uploadCount = UInt32((UInt64(uploadCount) + UInt64(statistics.uploadCount)) % UInt64(UInt32.max))
        }
    }
    
    private var timer: Timer! = nil
    private var timeInterval: TimeInterval = 1
    private var traffic: NetworkTraffic! = nil
    private var updateWithBitrate: ((Bitrate) -> Void)?
    
    init(with timeInterval: TimeInterval, and updateHandler: @escaping (Bitrate) -> Void) {
        self.timeInterval = timeInterval
        updateWithBitrate = updateHandler
        
        traffic = getTrafficStatistics()
        
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(updateBitrate), userInfo: nil, repeats: true)
        updateBitrate()
    }
    
    class public func formBitrateString(with bitrate: Bitrate) -> String {
           let downloadString = " \(rateString(for: bitrate.download))"
           let uploadString = " \(rateString(for: bitrate.upload))"
           return "download \(downloadString) | upload \(uploadString)"
       }
    
    class func rateString(for rate: UInt32) -> String {
        let rateString: String
        
        switch rate {
        case let rate where rate >= UInt32(pow(1024.0, 3)):
            rateString = "\(String(format: "%.1f", Double(rate) / pow(1024.0, 3))) GB/s"
        case let rate where rate >= UInt32(pow(1024.0, 2)):
            rateString = "\(String(format: "%.1f", Double(rate) / pow(1024.0, 2))) MB/s"
        case let rate where rate >= 1024:
            rateString = "\(String(format: "%.1f", Double(rate) / 1024.0)) KB/s"
        default:
            rateString = "\(String(format: "%.1f", Double(rate))) B/s"
        }
        
        return rateString
    }
    
    func stopGathering() {
        timer.invalidate()
    }
    
    @objc private func updateBitrate() {
        guard let updateWithBitrate = updateWithBitrate else { return }
        
        let latestTraffic = self.getTrafficStatistics()
        
        // usage can overflow
        let bitrate = Bitrate(download: UInt32(TimeInterval(latestTraffic.downloadCount >= self.traffic.downloadCount
                                                            ? latestTraffic.downloadCount - self.traffic.downloadCount
                                                            : latestTraffic.downloadCount)
                                                            / timeInterval),
                              upload: UInt32(TimeInterval(latestTraffic.uploadCount >= self.traffic.uploadCount
                                                          ? latestTraffic.uploadCount - self.traffic.uploadCount
                                                          : latestTraffic.uploadCount)
                                                          / timeInterval))
        
        self.traffic = latestTraffic
        
        updateWithBitrate(bitrate)
    }
    
    private func getTrafficStatistics() -> NetworkTraffic {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        var tempifaddr: UnsafeMutablePointer<ifaddrs>?
        var traffic = NetworkTraffic()
        
        guard getifaddrs(&ifaddr) == 0 else { return traffic }
        tempifaddr = ifaddr
        while let addr = tempifaddr {
            if let traf = trafficStatistics(from: addr) {
                traffic.updateCountsByAdding(traf)
            }
            
            tempifaddr = addr.pointee.ifa_next
        }
        
        freeifaddrs(ifaddr)
        return traffic
    }
    
    private func trafficStatistics(from trafficPointer: UnsafeMutablePointer<ifaddrs>) -> NetworkTraffic? {
        let addr = trafficPointer.pointee.ifa_addr.pointee
        guard addr.sa_family == UInt8(AF_LINK) else { return nil }
        
        let wwanInterfacePrefix = "pdp_ip"
        let wifiInterfacePrefix = "en"
        let name: String! = String(cString: trafficPointer.pointee.ifa_name)
        var networkData: UnsafeMutablePointer<if_data>?
        var traffic = NetworkTraffic()
        
        if name.hasPrefix(wifiInterfacePrefix) || name.hasPrefix(wwanInterfacePrefix) {
            networkData = unsafeBitCast(trafficPointer.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
            if let data = networkData {
                traffic.uploadCount += data.pointee.ifi_obytes
                traffic.downloadCount += data.pointee.ifi_ibytes
            }
            
        }
        
        return traffic
    }
}
