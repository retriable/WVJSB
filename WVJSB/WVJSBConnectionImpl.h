//
//  WVJSBConnectionImpl.h
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBDefine.h"
#import "WVJSBOperationImpl.h"

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBConnectionImpl : NSObject <WVJSBConnection>

@property (nonatomic,strong)id info;

@property (nonatomic,copy)void(^send)(NSString *mid,NSString *type,id _Nullable parameter);

- (WVJSBOperationImpl*)event:(NSString*)type parameter:(id _Nullable)parameter NS_SWIFT_NAME(event(type:parameter:));

- (void)ack:(NSString*)mid result:(id _Nullable)result error:(NSError* _Nullable)error;

- (instancetype)initWithInfo:(id)info NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
