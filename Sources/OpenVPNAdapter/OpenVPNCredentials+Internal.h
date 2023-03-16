//
//  OpenVPNCredentials+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 24.04.17.
//
//
#import "OpenVPNCredentials.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNCredentials (Internal)

@property (readonly) ClientAPI::ProvideCreds credentials;

@end
