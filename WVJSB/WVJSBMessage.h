//
//  WVJSBMessage.h
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WVJSBMessage : NSObject

@property (nonatomic,copy  ,nullable) NSString *mid;
@property (nonatomic,copy  ,nullable) NSString *type;
@property (nonatomic,copy  ,nullable) NSString *from;
@property (nonatomic,copy  ,nullable) NSString *to;
@property (nonatomic,strong,nullable) id       body;
@property (nonatomic,strong,nullable) NSError  *error;

- (instancetype)initWithString:(NSString*)string;
- (NSString* _Nullable)string;

@end

NS_ASSUME_NONNULL_END
