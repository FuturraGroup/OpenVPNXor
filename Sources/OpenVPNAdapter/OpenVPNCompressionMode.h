//
//  OpenVPNCompressionMode.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Compression mode options
 */
typedef NS_ENUM(NSInteger, OpenVPNCompressionMode) {
    /// Allow compression on both uplink and downlink
    OpenVPNCompressionModeEnabled,
    /// Support compression stubs only
    OpenVPNCompressionModeDisabled,
    /// Allow compression on downlink only (i.e. server -> client)
    OpenVPNCompressionModeAsym,
    /// Default behavior (support compression stubs only)
    OpenVPNCompressionModeDefault
};
