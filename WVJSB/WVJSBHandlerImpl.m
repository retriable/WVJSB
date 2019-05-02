//
//  WVJSBHandlerImpl.m
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBHandlerImpl.h"

@implementation WVJSBHandlerImpl

- (WVJSBHandlerImpl*)onEvent:(WVJSBEventBlock)event{
    self.event = event;
    return self;
}

- (void)onCancel:(WVJSBCancelBlock)cancel{
    self.cancel=cancel;
}

@end
