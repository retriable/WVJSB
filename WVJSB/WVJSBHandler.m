//
//  WVJSBHandler.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBHandler.h"
#import "WVJSBMessage.h"
#import "WVJSBServer.h"

@interface WVJSBHandler()

@property (nonatomic,strong)WVJSBOnEventBlock onEvent;

@property (nonatomic,strong)WVJSBOnCancelBlock onCancel;

@end

@implementation WVJSBHandler

- (WVJSBHandler*)onEvent:(WVJSBOnEventBlock)onEvent{
    if (self.onEvent) return self;
    self.onEvent = ^id (WVJSBConnection *connection,WVJSBMessage* _Nullable message, WVJSBAckBlock(^done)(void)) {
        return onEvent(connection,message.body,done);
    };
    return self;
}

- (void)onCancel:(void (^)(id _Nullable context))onCancel{
    if (self.onCancel) return;
    self.onCancel=onCancel;
}

@end
