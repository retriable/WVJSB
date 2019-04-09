//
//  WVJSBClient.m
//  WVJSB
//
//  Created by retriable on 2019/04/09.
//  Copyright © 2018 retriable. All rights reserved.
//

#import "WVJSBConnection+Private.h"
#import "WVJSBHandler+Private.h"
#import "WVJSBMessage.h"
#import "WVJSBScriptMessageHandler.h"
#import "WVJSBServer.h"
#import "WVJSBServer+Private.h"

NSString * const WVJSBQueryFormat=@";                   \
(function(){                                            \
    try{                                                \
        return window['%@_wvjsb_proxy'].query();        \
    }catch(e){return []};                               \
})();                                                   \
";
NSString * const WVJSBSendFormat=@";                    \
(function(){                                            \
    try{                                                \
        return window['%@_wvjsb_proxy'].send('%@');     \
    }catch(e){return ''};                               \
})();                                                   \
";

@interface WVJSBServer ()

@property (nonatomic,copy  ) NSString *ns;
@property (nonatomic,copy  ) NSString *installJS;
@property (nonatomic,strong) NSDictionary<NSString*,WVJSBConnection*> *connections;
@property (nonatomic,strong) NSMutableDictionary<NSString*,WVJSBHandler*> *handlers;
@property (nonatomic,strong) NSMutableDictionary<NSString*,void(^)(void)> *cancelBlocks;
@property (nonatomic,copy  ) void(^evaluate)(NSString *js,void(^completionHandler)(id result));

@end

@implementation WVJSBServer

+ (BOOL)canHandleWithWebView:(id)webView request:(NSURLRequest*)request{
    static NSRegularExpression *canHandleRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        canHandleRegex=[NSRegularExpression regularExpressionWithPattern:@"^https://wvjsb/([^/]+)/([^/]+)$" options:0 error:nil];
    });
    NSString *URLString=request.URL.absoluteString;
    NSTextCheckingResult *result = [canHandleRegex firstMatchInString:URLString options:0 range:NSMakeRange(0, URLString.length)];
    if (!result) return NO;
    NSString *ns=[URLString substringWithRange:[result rangeAtIndex:1]];
    WVJSBServer *server=[WVJSBServer serverWithWebView:webView namespace:ns flag:NO];
    if (!server) return YES;
    NSString *action=[URLString substringWithRange:[result rangeAtIndex:2]];
    if ([action isEqualToString:@"install"]) [server install];
    else if([action isEqualToString:@"query"]) [server query];
    return YES;
}

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns{
    return [self serverWithWebView:webView namespace:ns flag:YES];
}

+ (instancetype)serverWithWebView:(id)webView namespace:(NSString* _Nullable)ns flag:(BOOL)flag{
    static dispatch_semaphore_t lock;
    static NSMapTable<id,NSMutableDictionary*> *serversByWebView;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock=dispatch_semaphore_create(1);
        serversByWebView=[NSMapTable weakToStrongObjectsMapTable];
    });
    if (!webView){
        NSParameterAssert(0);
        return nil;
    }
    if (ns.length==0){
        ns=@"wvjsb_namespace";
    }
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSMutableDictionary *serversByName=[serversByWebView objectForKey:webView];
    if (!serversByName){
        serversByName=[NSMutableDictionary dictionary];
        [serversByWebView setObject:serversByName forKey:webView];
    }
    WVJSBServer *server=serversByName[ns];
    if (server)  {
        dispatch_semaphore_signal(lock);
        return server;
    }
    if (!flag){
        dispatch_semaphore_signal(lock);
        return server;
    }
    server=[[WVJSBServer alloc]initWithWebView:webView ns:ns];
    serversByName[ns]=server;
    dispatch_semaphore_signal(lock);
    return server;
}

- (instancetype)initWithWebView:(id)webView ns:(NSString*)ns{
    self=[super init];
    if (!self) return nil;
    if (ns.length==0) {
        NSParameterAssert(0);
        return nil;
    }
    self.ns=ns;
    self.connections=[NSMutableDictionary dictionary];
    self.handlers=[NSMutableDictionary dictionary];
    self.cancelBlocks=[NSMutableDictionary dictionary];
    if (![self initializeEvaluationWithWebView:webView]) {
        NSParameterAssert(0);
        return nil;
    }
    return self;
}

- (WVJSBHandler*)on:(NSString*)type{
    WVJSBHandler *handler=self.handlers[type];
    if (handler) {
        return handler;
    }
    handler=[[WVJSBHandler alloc]init];
    self.handlers[type]=handler;
    return handler;
}

- (void)install{
    self.evaluate(self.installJS,nil);
}

- (void)query{
    __weak typeof(self) weakSelf=self;
    self.evaluate([NSString stringWithFormat:WVJSBQueryFormat,self.ns], ^(id result) {
        __strong typeof(weakSelf) self=weakSelf;
        if ([result length]==0) return;
        NSError *error;
        NSArray *messages=[NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error){
            NSParameterAssert(0);
            return;
        }
        [messages enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self handleMessage:obj];
        }];
    });
}

- (void)sendMessage:(WVJSBMessage*)message completion:(void(^)(BOOL success))completion{
    NSString *string=[message string];
    if (!string){
        NSParameterAssert(0);
        if(completion) completion(NO);
        return;
    }
    self.evaluate([NSString stringWithFormat:WVJSBSendFormat,self.ns,WVJSBCorrectedJSString(string)],^(id result){
        if(completion) completion([result length]>0);
    });
}

- (void)handleMessage:(id)message{
    WVJSBMessage *event=[[WVJSBMessage alloc]initWithString:message];
    if (!event){
        NSParameterAssert(0);
        return;
    }
    NSString *mid=event.mid;
    NSString *from=event.from;
    NSString *to=event.to;
    NSString *type=event.type;
    id parameter=event.body;
    NSError *error=event.error;
    if (!from){
        //window did unload
        WVJSBHandler *handler=self.handlers[@"disconnect"];
        if (handler){
            [self.connections enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, WVJSBConnection * _Nonnull obj, BOOL * _Nonnull stop) {
                handler.onEvent(obj,nil, ^{
                    return ^(id result,NSError *error){};
                });
            }];
        }
        [(NSMutableDictionary*)self.connections removeAllObjects];
        return;
    }
    if (![to isEqualToString:self.ns]) return;
    __weak typeof(self) weakSelf=self;
    if ([type isEqualToString:@"connect"]){
        __strong typeof(weakSelf) self=weakSelf;
        WVJSBConnection *connection=self.connections[from];
        if (connection) return;
        connection=({
            WVJSBConnection *v=[[WVJSBConnection alloc]initWithInfo:parameter];
            v.event=^(WVJSBConnection *connection, NSString *mid, NSString *type, id parameter) {
                __strong typeof(weakSelf) self=weakSelf;
                __weak typeof(connection) weakConnection=connection;
                [self sendMessage:({
                    WVJSBMessage *v=[[WVJSBMessage alloc]init];
                    v.mid=mid;
                    v.from=self.ns;
                    v.to=from;
                    v.type=type;
                    v.body=parameter;
                    v;
                }) completion:^(BOOL success) {
                    if (success) return;
                    [weakConnection ack:mid result:nil error:[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"can not find host", nil)}]];
                }];
            };
            v;
        });
        [(NSMutableDictionary*)self.connections setObject:connection forKey:from];
        [connection event:@"connect" parameter:nil];
        WVJSBHandler *handler=self.handlers[type];
        if (handler) {
            handler.onEvent(connection, nil, ^{
                return ^(id result,NSError *error){};
            });
        }
        return;
    }
    if ([type isEqualToString:@"disconnect"]){
        WVJSBConnection *connection=self.connections[from];
        if (!connection) return;
        [(NSMutableDictionary*)self.connections removeObjectForKey:from];
        WVJSBHandler *handler=self.handlers[type];
        if (handler){
            handler.onEvent(connection, nil, ^{
                return ^(id result,NSError *error){};
            });
        }
        return;
    }
    
    if ([type isEqualToString:@"ack"]){
        WVJSBConnection *connection=self.connections[from];
        if (!connection) return;
        [connection ack:mid result:parameter error:error];
        WVJSBHandler *handler=self.handlers[type];
        if (handler){
            handler.onEvent(self.connections[from], nil, ^{
                return ^(id result,NSError *error){};
            });
        }
        return;
    }
    
    if ([type isEqualToString:@"cancel"]){
        void(^block)(void)=self.cancelBlocks[mid];
        if (!block) return;
        block();
        WVJSBHandler *handler=self.handlers[type];
        if (handler){
            handler.onEvent(self.connections[from], nil, ^{
                return ^(id result,NSError *error){};
            });
        }
        return;
    }
    WVJSBHandler *handler=self.handlers[type];
    if (!handler) return;
    NSString *key=[NSString stringWithFormat:@"%@-%@",to,mid];
    id context;
    if (handler.onEvent){
        context=handler.onEvent(self.connections[from],event, ^{
            __strong typeof(weakSelf) self=weakSelf;
            self.cancelBlocks[key]=nil;
            return ^(id result, NSError *error) {
                __strong typeof(weakSelf) self=weakSelf;
                [self sendMessage:({
                    WVJSBMessage *v=[[WVJSBMessage alloc]init];
                    v.from=self.ns;
                    v.to=from;
                    v.mid=mid;
                    v.type=@"ack";
                    v.body=result;
                    v.error=error;
                    v;
                }) completion:nil];
            };
        });
    }
    if (handler.onCancel) self.cancelBlocks[key]=^(){
        handler.onCancel(context);
    };
}

- (BOOL)initializeEvaluationWithWebView:(id)webView{
    __weak typeof(webView) weakWebView=webView;
#if TARGET_OS_IOS
    if ([webView isKindOfClass:UIWebView.class]){
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView=weakWebView;
                id result=[(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                if(completionHandler) completionHandler(result);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView=weakWebView;
                    id result=[(UIWebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                });
            }
        };
        return YES;
    }
#else
    if ([webView isKindOfClass:WebView.class]){
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView=weakWebView;
                id result=[(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                if(completionHandler) completionHandler(result);
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView=weakWebView;
                    id result=[(WebView*)webView stringByEvaluatingJavaScriptFromString:js];
                    if(completionHandler) completionHandler(result);
                });
            }
        };
        return YES;
    }
#endif
    if ([webView isKindOfClass:WKWebView.class]){
//        [[(WKWebView*)webView configuration].userContentController addUserScript:[[WKUserScript alloc]initWithSource:[[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:WVJSBServer.class] pathForResource:@"Proxy" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"wvjsb_namespace" withString:self.ns] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES]];
        [[(WKWebView*)webView configuration].userContentController addScriptMessageHandler:[[WVJSBScriptMessageHandler alloc]init] name:self.ns];
        self.evaluate = ^(NSString *js, void (^completionHandler)(id result)) {
            if ([NSThread isMainThread]){
                __strong typeof(weakWebView) webView=weakWebView;
                [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                    if(completionHandler) completionHandler(result);
                }];
            }else{
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakWebView) webView=weakWebView;
                    [(WKWebView*)webView evaluateJavaScript:js completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                        if(completionHandler) completionHandler(result);
                    }];
                });
            }
        };
        return YES;
    }
    return NO;
}

- (NSString*)installJS{
    if (_installJS) return _installJS;
    _installJS=[[NSString stringWithContentsOfFile:[[NSBundle bundleForClass:WVJSBServer.class] pathForResource:@"Proxy" ofType:@"js"] encoding:NSUTF8StringEncoding error:nil] stringByReplacingOccurrencesOfString:@"wvjsb_namespace" withString:self.ns];
    return _installJS;
}
@end



