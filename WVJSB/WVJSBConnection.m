//
//  WVJSBConnection.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBServer+Private.h"
#import "WVJSBOperation+Private.h"
#import "WVJSBConnection.h"

@interface WVJSBConnection ()

@property (nonatomic,assign)NSUInteger nextSeq;
@property (nonatomic,strong)id info;
@property (nonatomic,strong)NSMutableDictionary<NSString*,WVJSBOperation*> *operations;
@property (nonatomic,strong)dispatch_semaphore_t semaphore;
@property (nonatomic,copy)void(^event)(WVJSBConnection* connection,NSString *mid,NSString *type,id parameter);

@end

@implementation WVJSBConnection

- (instancetype)initWithInfo:(id)info{
    self=[super init];
    if (!self) return nil;
    self.info=info;
    self.semaphore=dispatch_semaphore_create(1);
    return self;
}

- (void)dealloc{
    NSError *error=[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNetworkConnectionLost userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"connection lost", nil)}];
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    [self.operations enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, WVJSBOperation * _Nonnull operation, BOOL * _Nonnull stop) {
        [operation ack:nil error:error];
    }];
    dispatch_semaphore_signal(self.semaphore);
}

- (void)ack:(NSString*)mid result:(id _Nullable)result error:(NSError* _Nullable)error{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    WVJSBOperation *operation=self.operations[mid];
    dispatch_semaphore_signal(self.semaphore);
    if (!operation) return;
    [operation ack:result error:error];
}

- (WVJSBOperation*)event:(NSString *)type parameter:(id)parameter{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    NSString *mid=@(self.nextSeq++).description;
    dispatch_semaphore_signal(self.semaphore);
    __weak typeof(self) weakSelf=self;
    WVJSBOperation *operation=[[WVJSBOperation alloc]init];
    operation.retainBlock = ^(WVJSBOperation *operation) {
        __strong typeof(weakSelf) self=weakSelf;
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        self.operations[mid]=operation;
        dispatch_semaphore_signal(self.semaphore);
    };
    operation.releaseBlock = ^(WVJSBOperation *operation) {
        __strong typeof(weakSelf) self=weakSelf;
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        self.operations[mid]=nil;
        dispatch_semaphore_signal(self.semaphore);
    };
    operation.cancelBlock = ^(WVJSBOperation *operation){
        __strong typeof(weakSelf) self=weakSelf;
        self.event(self, mid, @"cancel", nil);
    };
    self.event(self, mid, type, parameter);
    return operation;
}

- (NSMutableDictionary<NSString*,WVJSBOperation*>*)operations{
    if (_operations) return _operations;
    _operations=[NSMutableDictionary dictionary];
    return _operations;
}

@end
