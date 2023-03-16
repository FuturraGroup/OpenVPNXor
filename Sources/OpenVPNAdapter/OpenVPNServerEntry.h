//
//  OpenVPNServerEntry.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 26.04.17.
//
//

#import <Foundation/Foundation.h>

@interface OpenVPNServerEntry : NSObject

@property (nullable, readonly, nonatomic) NSString *server;
@property (nullable, readonly, nonatomic) NSString *friendlyName;

- (nonnull instancetype) init NS_UNAVAILABLE;

@end
