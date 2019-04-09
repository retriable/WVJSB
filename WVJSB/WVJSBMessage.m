//
//  WVJSBMessage.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBMessage.h"
#import "WVJSBServer+Private.h"

@implementation WVJSBMessage

- (instancetype)initWithString:(NSString *)string{
    if (WVJSBIsStringEmpty(string)){
        NSParameterAssert(0);
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
    id body = message[@"body"];
    self=[self init];
    if (!self) return nil;
    self.from=from;
    self.to=to;
    self.mid=mid;
    self.type=type;
    self.body=body;
    if ([error isKindOfClass:NSString.class]||[error isKindOfClass:NSNumber.class]){
        self.error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString([error description], nil)}];
    }else if ([error isKindOfClass:NSDictionary.class]){
        NSInteger code=[error[@"code"] integerValue];
        NSString *domain=error[@"domain"];
        NSString *description=error[@"description"];
        if (description) self.error=[NSError errorWithDomain:domain code:code userInfo:@{NSLocalizedDescriptionKey:description}];
        else self.error=[NSError errorWithDomain:domain code:code userInfo:nil];
    }
    return self;
}

- (NSString*)string{
    if (WVJSBIsStringEmpty(self.from)){
        NSParameterAssert(0);
        return nil;
    }
    if (WVJSBIsStringEmpty(self.to)){
        NSParameterAssert(0);
        return nil;
    }
    if (WVJSBIsStringEmpty(self.type)){
        NSParameterAssert(0);
        return nil;
    }
    NSMutableDictionary *message=[NSMutableDictionary dictionary];
    message[@"from"]=self.from;
    message[@"to"]=self.to;
    message[@"id"]=self.mid;
    message[@"type"]=self.type;
    message[@"body"]=self.body;
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