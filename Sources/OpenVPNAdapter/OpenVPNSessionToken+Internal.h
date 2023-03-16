//
//  OpenVPNSessionToken+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 28.04.17.
//
//

#import "OpenVPNSessionToken.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNSessionToken (Internal)

- (instancetype)initWithSessionToken:(ClientAPI::SessionToken)token;

@end
