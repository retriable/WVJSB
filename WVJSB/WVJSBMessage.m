//
//  WVJSBMessage.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBMessage.h"

@implementation WVJSBMessage

- (instancetype)initWithString:(NSString *)string{
    if (string.length==0){
        return nil;
    }
    NSError *e;
    NSDictionary *message=[NSJSONSerialization JSONObjectWithData:[string dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&e];
    if (e||!message){
        NSParameterAssert(0);
        return nil;
    }
    NSString *mid=message[@"id"];
    NSString *from=message[@"from"];
    NSString *to=message[@"to"];
    NSString *type=message[@"type"];
    id error=message[@"error"];
    id parameter = message[@"parameter"];
    self=[self init];
    if (!self) return nil;
    self.from=from;
    self.to=to;
    self.mid=mid;
    self.type=type;
    self.parameter=parameter;
    if ([error isKindOfClass:NSString.class]||[error isKindOfClass:NSNumber.class]){
        self.error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString([error description], nil)}];
    }else if ([error isKindOfClass:NSDictionary.class]){
        NSInteger code=[error[@"code"] integerValue];
        NSString *domain=error[@"domain"];
        NSString *description=error[@"description"];
        if (description) self.error=[NSError errorWithDomain:domain?domain:NSURLErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
        else self.error=[NSError errorWithDomain:domain?domain:NSURLErrorDomain code:code userInfo:nil];
    }
    return self;
}

- (NSString*)string{
    NSMutableDictionary *message=[NSMutableDictionary dictionary];
    message[@"from"]=self.from;
    message[@"to"]=self.to;
    message[@"id"]=self.mid;
    message[@"type"]=self.type;
    message[@"parameter"]=self.parameter;
    if (self.error.code!=0){
        NSMutableDictionary *error=[NSMutableDictionary dictionary];
        error[@"domain"]=self.error.domain;
        error[@"code"]=@(self.error.code);
        error[@"description"]=self.error.localizedDescription;
        message[@"error"]=error;
    }
    NSError *e;
    NSData *data=[NSJSONSerialization dataWithJSONObject:message options:0 error:&e];
    if (e){
        NSParameterAssert(0);
        return nil;
    }
    return [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
}

@end
