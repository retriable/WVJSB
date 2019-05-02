//
//  WVJSBOperationImpl.h
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBOperationImpl : NSObject<WVJSBOperation>

@property (nonatomic,copy)void(^retainBlock)(WVJSBOperationImpl *operation);
@property (nonatomic,copy)void(^releaseBlock)(WVJSBOperationImpl *operation);
@property (nonatomic,copy)void(^cancelBlock)(WVJSBOperationImpl *oepration);

- (WVJSBOperationImpl*)onAck:(WVJSBResultBlock)ack;

- (WVJSBOperationImpl*)timeout:(NSTimeInterval)timeout;

- (void)cancel;

- (void)ack:(id _Nullable)result error:(NSError* _Nullable)error;

@end

NS_ASSUME_NONNULL_END
