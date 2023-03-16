//
//  OpenVPNProperties+Internal.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import "OpenVPNProperties.h"

#include "ovpncli.hpp"

using namespace openvpn;

@interface OpenVPNProperties (Internal)

- (instancetype)initWithEvalConfig:(ClientAPI::EvalConfig)eval;

@end
