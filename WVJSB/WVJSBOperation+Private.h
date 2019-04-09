//
//  WVJSBOperation+Private.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBOperation (Private)

@property (nonatomic,copy)void(^retainBlock )(WVJSBOperation *operation);
@property (nonatomic,copy)void(^releaseBlock)(WVJSBOperation *operation);
@property (nonatomic,copy)void(^cancelBlock )(WVJSBOperation *operation);

- (void)ack:(id _Nullable)result error:(NSError* _Nullable)error;

@end

NS_ASSUME_NONNULL_END
