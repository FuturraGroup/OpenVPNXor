//
//  OpenVPNConnectionInfo+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import "OpenVPNConnectionInfo.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNConnectionInfo (Internal)

- (instancetype)initWithConnectionInfo:(ClientAPI::ConnectionInfo)info;

@end
