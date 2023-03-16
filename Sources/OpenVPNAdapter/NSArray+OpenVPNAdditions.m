//
//  NSArray+OpenVPNAdditions.m
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 16/10/2018.
//

#import "NSArray+OpenVPNAdditions.h"

@implementation NSArray (OpenVPNEmptyArray)

- (BOOL)ovpn_isNotEmpty {
    return (self.count > 0) ? YES : NO;
}

@end
