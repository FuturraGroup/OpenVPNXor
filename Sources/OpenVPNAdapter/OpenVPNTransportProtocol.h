//
//  OpenVPNTransportProtocol.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import <Foundation/Foundation.h>

/**
 Transport protocol options
 */
typedef NS_ENUM(NSInteger, OpenVPNTransportProtocol) {
    ///
    OpenVPNTransportProtocolUDP,
    ///
    OpenVPNTransportProtocolTCP,
    ///
    OpenVPNTransportProtocolAdaptive,
    /// Use a transport protocol specified in the profile
    OpenVPNTransportProtocolDefault
};
