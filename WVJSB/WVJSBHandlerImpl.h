//
//  WVJSBHandlerImpl.h
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBHandlerImpl : NSObject<WVJSBHandler>

@property (nonatomic,strong)WVJSBEventBlock event;

@property (nonatomic,strong)WVJSBCancelBlock cancel;

- (WVJSBHandlerImpl*)onEvent:(WVJSBEventBlock)event;

- (void)onCancel:(WVJSBCancelBlock)cancel;

@end

NS_ASSUME_NONNULL_END
