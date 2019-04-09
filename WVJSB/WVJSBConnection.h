//
//  WVJSBConnection.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WVJSBOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBConnection : NSObject

@property (readonly)id info;

- (WVJSBOperation*)event:(NSString*)type parameter:(id _Nullable)parameter NS_SWIFT_NAME(event(type:parameter:));

- (instancetype)initWithInfo:(id)info NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
