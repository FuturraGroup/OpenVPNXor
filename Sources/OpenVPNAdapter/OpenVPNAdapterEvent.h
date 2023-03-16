//
//  OpenVPNXorEvent.h
//  OpenVPNXor
//
//  Created by Sergey Zhuravel on 05.11.16.
//  Copyright © 2016 Sergey Zhuravel. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 OpenVPN event codes
 */
typedef NS_ENUM(NSInteger, OpenVPNAdapterEvent) {
    OpenVPNAdapterEventDisconnected,
    OpenVPNAdapterEventConnected,
    OpenVPNAdapterEventReconnecting,
    OpenVPNAdapterEventResolve,
    OpenVPNAdapterEventWait,
    OpenVPNAdapterEventWaitProxy,
    OpenVPNAdapterEventConnecting,
    OpenVPNAdapterEventGetConfig,
    OpenVPNAdapterEventAssignIP,
    OpenVPNAdapterEventAddRoutes,
    OpenVPNAdapterEventEcho,
    OpenVPNAdapterEventInfo,
    OpenVPNAdapterEventPause,
    OpenVPNAdapterEventResume,
    OpenVPNAdapterEventRelay,
    OpenVPNAdapterEventUnknown
};
