//
//  ObjCViewController.m
//  WVJSB iOS Example
//
//  Created by retriable on 2019/4/9.
//  Copyright © 2019 retriable. All rights reserved.
//

@import WVJSB;

#import "ObjCViewController.h"

@interface ObjCViewController ()<WKNavigationDelegate>

@property (nonatomic,strong)WKWebView *webView;

@property (nonatomic,strong)NSMutableArray <id<WVJSBConnection>> *connections;
@property (nonatomic,strong)NSMutableArray <id<WVJSBOperation>> *operations;

@end

@implementation ObjCViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.connections=[NSMutableArray array];
    self.operations=[NSMutableArray array];
    [self.view addSubview:self.webView];
    self.webView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.topLayoutGuide attribute:NSLayoutAttributeTop multiplier:1 constant:88]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.bottomLayoutGuide attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    WVJSBServer *server=[WVJSBServer serverWithWebView:self.webView namespace:nil];
    [[server on:@"connect"] onEvent:^id (id<WVJSBConnection> connection, id parameter, WVJSBAckBlock (^done)(void)) {
        NSLog(@"%@ did connect",connection.info);
        @synchronized (self.connections) {
            [self.connections addObject:connection];
        }
        done();
        return nil;
    }];
    [[server on:@"disconnect"] onEvent:^id (id<WVJSBConnection> connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        NSLog(@"%@ did disconnect",connection.info);
        @synchronized (self.connections) {
            [self.connections removeObject:connection];
        }
        done();
        return nil;
    }];
    [[server on:@"immediate"] onEvent:^id (id<WVJSBConnection> connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        done()(@"immediate ack",nil);
        return nil;
    }];
    [[[server on:@"delayed"] onEvent:^id (id<WVJSBConnection> connection, id parameter, WVJSBAckBlock (^ done)(void)) {
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*2), DBL_MAX, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            done()(@"delayed ack",nil);
        });
        dispatch_resume(timer);
        return timer;
    }] onCancel:^(id   context) {
        dispatch_source_cancel(context);
    }];
    [self reload:self];
    // Do any additional setup after loading the view.
}
- (IBAction)reload:(id)sender {
    NSString *URLString =@"http://localhost:8000/index.html";
    //    NSString *URLString =@"http://192.168.2.2:8000/index.html";
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]]];
}

- (IBAction)immediate:(id)sender {
    @synchronized (self.connections) {
        __weak typeof(self) weakSelf=self;
        [self.connections enumerateObjectsUsingBlock:^(id<WVJSBConnection> obj, NSUInteger idx, BOOL * stop) {
            id <WVJSBOperation> operation = [[[obj event:@"immediate" parameter:nil] onAck:^(id<WVJSBOperation> operation ,id  _Nullable result, NSError * _Nullable error) {
                if (error){
                    NSLog(@"did receive immediate error: %@",error);
                }else{
                    NSLog(@"did receive immediate ack: %@",result);
                }
                __strong typeof(weakSelf) self=weakSelf;
                @synchronized (self.operations) {
                    [self.operations removeObject:operation];
                }
            }] timeout:10];
            @synchronized (self.operations) {
                [self.operations addObject:operation];
            }
        }];
    }
}

- (IBAction)delayed:(id)sender {
    __weak typeof(self) weakSelf=self;
    @synchronized (self.connections) {
        [self.connections enumerateObjectsUsingBlock:^(id<WVJSBConnection>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            id<WVJSBOperation> operation = [[[obj event:@"delayed" parameter:nil] onAck:^(id<WVJSBOperation> operation,id result, NSError *error) {
                if (error){
                    NSLog(@"did receive delayed error: %@",error);
                }else{
                    NSLog(@"did receive delayed ack: %@",result);
                }
                __strong typeof(weakSelf) self=weakSelf;
                @synchronized (self.operations) {
                    [self.operations removeObject:operation];
                }
            }]timeout:10];
            @synchronized (self.operations) {
                [self.operations addObject:operation];
            }
        }];
    }
}

- (IBAction)cancel:(id)sender {
    @synchronized (self.operations) {
        [self.operations enumerateObjectsUsingBlock:^(id<WVJSBOperation>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj cancel];
        }];
        [self.operations removeAllObjects];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    decisionHandler([WVJSBServer canHandleWithWebView:webView URLString:navigationAction.request.URL.absoluteString]?WKNavigationActionPolicyCancel:WKNavigationActionPolicyAllow);
}

- (WKWebView*)webView{
    if (_webView) return _webView;
    _webView=[[WKWebView alloc]initWithFrame:CGRectZero configuration:[[WKWebViewConfiguration alloc]init]];
    _webView.navigationDelegate=self;
    return _webView;
}



/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
