//
//  WVJSBOperation.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBOperation.h"

@interface WVJSBOperation ()

@property (nonatomic,copy)void(^onAckBlock)(id result, NSError * error);
@property (nonatomic,copy)void(^retainBlock)(WVJSBOperation *operation);
@property (nonatomic,copy)void(^releaseBlock)(WVJSBOperation *operation);
@property (nonatomic,copy)void(^cancelBlock)(WVJSBOperation *oepration);

@property (nonatomic,assign)BOOL ok;
@property (nonatomic,strong)dispatch_semaphore_t semaphore;
@property (nonatomic,strong)dispatch_source_t    timer;

@end

@implementation WVJSBOperation

- (instancetype)init{
    self=[super init];
    if (!self) return nil;
    self.semaphore=dispatch_semaphore_create(1);
    return self;
}

- (WVJSBOperation*)onAck:(void(^)(WVJSBOperation *operation,id _Nullable result,NSError * _Nullable error))ack{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (self.ok) {
        dispatch_semaphore_signal(self.semaphore);
        return self;
    }
    dispatch_semaphore_signal(self.semaphore);
    self.retainBlock(self);
    __weak typeof(self) weakSelf=self;
    self.onAckBlock = ^(id result, NSError *error) {
        __strong typeof(weakSelf) self=weakSelf;
        self.releaseBlock(self);
        ack(self,result,error);
    };
    return self;
}

- (WVJSBOperation*)timeout:(NSTimeInterval)timeout{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (timeout<=0) {
        dispatch_semaphore_signal(self.semaphore);
        return self;
    }
    if (self.ok){
        dispatch_semaphore_signal(self.semaphore);
        return self;
    }
    if (self.timer){
        dispatch_source_cancel(self.timer);
        self.timer=nil;
    }
    __weak typeof(self) weakSelf=self;
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, timeout*NSEC_PER_SEC), DBL_MAX * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.timer, ^{
        __strong typeof(weakSelf) self=weakSelf;
        dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        if (self.ok) {
            dispatch_semaphore_signal(self.semaphore);
            return;
        }
        self.ok=YES;
        if (self.timer){
            dispatch_source_cancel(self.timer);
            self.timer=nil;
        }
        dispatch_semaphore_signal(self.semaphore);
        self.onAckBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"timed out", nil)}]);
    });
    dispatch_resume(self.timer);
    dispatch_semaphore_signal(self.semaphore);
    return self;
}

- (void)cancel{
    self.cancelBlock(self);
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (self.ok) {
        dispatch_semaphore_signal(self.semaphore);
        return;
    }
    self.ok=YES;
    if (self.timer){
        dispatch_source_cancel(self.timer);
        self.timer=nil;
    }
    dispatch_semaphore_signal(self.semaphore);
    self.onAckBlock(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"cancelled", nil)}]);
}

- (void)ack:(id)result error:(NSError*)error{
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    if (self.ok){
        dispatch_semaphore_signal(self.semaphore);
        return;
    }
    self.ok=YES;
    if (self.timer){
        dispatch_source_cancel(self.timer);
        self.timer=nil;
    }
    dispatch_semaphore_signal(self.semaphore);
    if (self.onAckBlock) self.onAckBlock(result, error);
}

@end
