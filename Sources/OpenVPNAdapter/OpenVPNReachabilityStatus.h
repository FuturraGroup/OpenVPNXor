//
//  OpenVPNReachabilityStatus.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 17.07.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNReachabilityStatus) {
    OpenVPNReachabilityStatusNotReachable,
    OpenVPNReachabilityStatusReachableViaWiFi,
    OpenVPNReachabilityStatusReachableViaWWAN
};
