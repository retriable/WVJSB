//
//  WVJSBOperationImpl.m
//  WVJSB
//
//  Created by retriable on 2019/5/2.
//  Copyright © 2019 retriable. All rights reserved.
//

#import "WVJSBOperationImpl.h"

@interface WVJSBOperationImpl ()

@property (nonatomic,copy  ) void(^ack)(id result,NSError *error);
@property (nonatomic,assign) BOOL              ok;
@property (nonatomic,strong) dispatch_source_t timer;

@end

@implementation WVJSBOperationImpl

- (WVJSBOperationImpl*)onAck:(WVJSBResultBlock)ack{
    @synchronized (self) {
        if (self.ok) {
            return self;
        }
        __weak typeof(self) weakSelf=self;
        self.retainBlock(self);
        self.ack = ^(id result, NSError * error) {
            __strong typeof(weakSelf) self=weakSelf;
            self.releaseBlock(self);
            ack(self,result,error);
        };
        return self;
    }
}

- (WVJSBOperationImpl*)timeout:(NSTimeInterval)timeout{
    @synchronized (self) {
        if (timeout<=0) {
            return self;
        }
        if (self.ok){
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
            @synchronized (self) {
                if (self.ok) {
                    return;
                }
                self.ok=YES;
                if (self.timer){
                    dispatch_source_cancel(self.timer);
                    self.timer=nil;
                }
                if(self.ack) self.ack(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"timed out", nil)}]);
            }
        });
        dispatch_resume(self.timer);
        return self;
    }
}

- (void)cancel{
    @synchronized(self) {
        if (self.ok) {
            return;
        }
        self.ok=YES;
        self.cancelBlock(self);
        if (self.timer){
            dispatch_source_cancel(self.timer);
            self.timer=nil;
        }
        if(self.ack) self.ack(nil, [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"cancelled", nil)}]);
    }
}

- (void)ack:(id)result error:(NSError*)error{
    @synchronized (self) {
        if (self.ok){
            return;
        }
        self.ok=YES;
        if (self.timer){
            dispatch_source_cancel(self.timer);
            self.timer=nil;
        }
        if(self.ack) self.ack(result, error);
    }
}

@end
