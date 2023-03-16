//
//  OpenVPNInterfaceStats+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import "OpenVPNInterfaceStats.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNInterfaceStats (Internal)

- (instancetype)initWithInterfaceStats:(ClientAPI::InterfaceStats)stats;

@end
