//
//  WVJSBHandler+Private.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBHandler.h"
#import "WVJSBMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBHandler (Private)

@property (nonatomic,strong)WVJSBOnEventBlock onEvent;

@property (nonatomic,strong)WVJSBOnCancelBlock onCancel;

@end

NS_ASSUME_NONNULL_END
