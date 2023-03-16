//
//  OpenVPNReachability.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 17.07.17.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OpenVPNReachabilityStatus);

@interface OpenVPNReachability : NSObject

@property (readonly, nonatomic, getter=isTracking) BOOL tracking;
@property (readonly, nonatomic) OpenVPNReachabilityStatus reachabilityStatus;

- (nonnull instancetype)init;

- (void)startTrackingWithCallback:(nonnull void (^)(OpenVPNReachabilityStatus))callback;
- (void)stopTracking;

@end
