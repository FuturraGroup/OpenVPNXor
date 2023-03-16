//
//  OpenVPNKeyType.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 07.09.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNKeyType) {
    OpenVPNKeyTypeNone = 0,
    OpenVPNKeyTypeRSA,
    OpenVPNKeyTypeECKEY,
    OpenVPNKeyTypeECKEYDH,
    OpenVPNKeyTypeECDSA,
    OpenVPNKeyTypeRSAALT,
    OpenVPNKeyTypeRSASSAPSS,
};
