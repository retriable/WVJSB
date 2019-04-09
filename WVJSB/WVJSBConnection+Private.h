//
//  WVJSBConnection+Private.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBConnection.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBConnection (Private)

@property (nonatomic,copy)void(^event)(WVJSBConnection* connection,NSString *mid,NSString *type,id parameter);

- (void)ack:(NSString*)mid result:(id _Nullable)result error:(NSError* _Nullable)error;

@end

NS_ASSUME_NONNULL_END
