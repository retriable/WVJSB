//
//  Protocols.h
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol WVJSBOperation;

typedef void (^WVJSBResultBlock)(id<WVJSBOperation> operation,id _Nullable result, NSError *_Nullable error);

@protocol WVJSBOperation <NSObject>

- (id<WVJSBOperation>)onAck:(WVJSBResultBlock)ack;

- (id<WVJSBOperation>)timeout:(NSTimeInterval)timeout;

- (void)cancel;

@end

@protocol WVJSBConnection <NSObject>

@property (readonly)id _Nullable info;

- (id<WVJSBOperation>)event:(NSString*)type parameter:(id _Nullable)parameter NS_SWIFT_NAME(event(type:parameter:));

@end

typedef void (^WVJSBAckBlock)(id _Nullable result, NSError *_Nullable error);

typedef void (^WVJSBCancelBlock)(id _Nullable context);

typedef id _Nullable (^WVJSBEventBlock)(id<WVJSBConnection> connection, id _Nullable parameter, WVJSBAckBlock(^done)(void));

@protocol WVJSBHandler <NSObject>

- (id<WVJSBHandler>)onEvent:(WVJSBEventBlock)onEvent;

- (void)onCancel:(WVJSBCancelBlock)onCancel;

@end

NS_ASSUME_NONNULL_END
