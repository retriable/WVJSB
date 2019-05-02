//
//  WVJSBConnectionImpl.m
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import <libkern/OSAtomic.h>

#import "WVJSBConnectionImpl.h"
#import "WVJSBOperationImpl.h"

@interface WVJSBConnectionImpl ()

@property (nonatomic,assign)int64_t nextSeq;
@property (nonatomic,strong)NSMutableDictionary<NSString*,WVJSBOperationImpl*> *operations;

@end

@implementation WVJSBConnectionImpl

- (instancetype)initWithInfo:(id)info{
    self=[super init];
    if (!self) return nil;
    self.info=info;
    self.operations=[NSMutableDictionary dictionary];
    return self;
}

- (void)dealloc{
    NSError *error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"connection lost", nil)}];
    @synchronized (self.operations) {
        [self.operations enumerateKeysAndObjectsUsingBlock:^(NSString *key, WVJSBOperationImpl *operation, BOOL *stop) {
            [operation ack:nil error:error];
        }];
    }
}

- (void)ack:(NSString*)mid result:(id)result error:(NSError*)error{
    @synchronized (self) {
        WVJSBOperationImpl *operation=self.operations[mid];
        if (!operation) return;
        [operation ack:result error:error];
    }
}

- (WVJSBOperationImpl*)event:(NSString *)type parameter:(id)parameter{
    NSString *mid=@(OSAtomicAdd64(1, &_nextSeq)).description;
    __weak typeof(self) weakSelf=self;
    WVJSBOperationImpl *operation=[[WVJSBOperationImpl alloc]init];
    operation.retainBlock = ^(WVJSBOperationImpl *operation) {
        __strong typeof(weakSelf) self=weakSelf;
        @synchronized (self.operations) {
            self.operations[mid]=operation;
        }
    };
    operation.releaseBlock = ^(WVJSBOperationImpl *operation) {
        __strong typeof(weakSelf) self=weakSelf;
        @synchronized (self.operations) {
            self.operations[mid]=nil;
        }
    };
    operation.cancelBlock = ^(WVJSBOperationImpl *operation){
        __strong typeof(weakSelf) self=weakSelf;
        self.event(mid, @"cancel", nil);
    };
    self.event(mid, type, parameter);
    return operation;
}

@end
