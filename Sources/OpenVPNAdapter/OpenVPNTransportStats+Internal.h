//
//  OpenVPNTransportStats+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import "OpenVPNTransportStats.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNTransportStats (Internal)

- (instancetype)initWithTransportStats:(ClientAPI::TransportStats)stats;

@end
