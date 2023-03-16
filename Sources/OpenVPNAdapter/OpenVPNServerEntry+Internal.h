//
//  OpenVPNServerEntry+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import "OpenVPNServerEntry.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNServerEntry (Internal)

- (instancetype)initWithServerEntry:(ClientAPI::ServerEntry)entry;

@end
