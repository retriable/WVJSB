//
//  WVJSBHandler.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WVJSBServer.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBHandler : NSObject

- (WVJSBHandler*)onEvent:(WVJSBOnEventBlock)onEvent;

- (void)onCancel:(WVJSBOnCancelBlock)onCancel;

@end

NS_ASSUME_NONNULL_END
