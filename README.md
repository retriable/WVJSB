# WVJSB

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/retriable/WVJSB/master/LICENSE)
[![Build Status](https://img.shields.io/travis/retriable/WVJSB/master.svg?style=flat)](https://travis-ci.org/retriable/WVJSB)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/retriable/WVJSB)
[![Pod Version](https://img.shields.io/cocoapods/v/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)
[![Pod Platform](https://img.shields.io/cocoapods/p/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)

**Cross-iframe** WebView JavaScript Bridge.

## Installation

* Native app
   * Cocoapods

        Add the following to your project's Podfile:
        ```ruby
        pod 'WVJSB'
        ```

   * Carthage

        Add the following to your project's Cartfile:
        ```ruby
        github "retriable/WVJSB"
        ```
   * Web

        Add [JavaScript](https://raw.githubusercontent.com/retriable/WVJSB/master/WVJSB/Resources/www/scripts/Client.js) to web project.

## Native usage
1. Create server
    > Server is automatically associated with the web view.

    ```obj-c
        WVJSBServer *server=[WVJSBServer serverWithWebView:webView namespace:@"server namespace"];
    ```

2. Inspect URL
   * UIWebView

        ```obj-c
        - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
            return [WVJSBServer canHandleWithWebView:webView URLString:request.URL.absoluteString];
        }
        ```

   * WKWebView

        ```obj-c
        - (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
        decisionHandler([WVJSBServer canHandleWithWebView:webView URLString:navigationAction.request.URL.absoluteString]?WKNavigationActionPolicyCancel:WKNavigationActionPolicyAllow);
        }
        ```

*  Handle unresponsive request

    ```obj-c
    [[server on:@"method"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
        done();
        return nil;
    }];
    ```

* Handle responsive request

    ```obj-c
    [[server on:@"request"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
        done()(@"response object",nil);
        return nil;
    }];
    ```

* Handle cancelable request

    ```obj-c
    [[[server on:@"request"] onEvent:^id (WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
        //Simulate asynchronous request
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*2), DBL_MAX, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            done()(@"response object",nil);
        });
        dispatch_resume(timer);
        //Return the timer as context 
        return timer;
    }] onCancel:^(id  context) {
        dispatch_source_t timer = context;
        //Cancel timer 
        dispatch_source_cancel(timer);
    }];
    ```

* Request to JavaScript client

    ```obj-c
    //get a target connection
    WVJSBConnection *connection =  server.connections.allValues.lastObject;
    WVJSBOperation *operation = [[[connection event:@"request" parameter:nil] onAck:^(WVJSBOperation *operation,id result, NSError *error) {
        //Do something with result
    }] timeout:10];
    ```

* Cancel request

    ```obj-c
    [operation cancel];
    ```

## JavaScript usage

* Create client

    ```js
    const client = WVJSBClient('server namespace',{"key":"value"});
    ```

* Handle unresponsive request

    ```js
    client.on('method').onEvent(function(parameter,done){
        done();
    })
    ```

* Handle responsive request

    ```js
    client.on('request').onEvent(function(parameter,done){
        done()('response object',null);
    })
    ```

* Handle cancelable request

    ```js
    client.on('request').onEvent(function(parameter,done){
        const context = window.setTimeout(function(){
            done()('response object',null);
        },2000);
        return context;
    }).onCancel(function(context){
        window.clearTimeout(context);
    });
    ```

* Request to native server

    ```js
    const operation = client.event('request',null).onAck(function(operation,parameter,error){

    }).timeout(10000);
    ```

* Cancel request

    ```js
    operation.cancel();
    ```

### Run Example

1. Open Terminal,and execute following

    ```shell
    cd pathToProject/WVJSB/Resources/www
    python -m SimpleHTTPServer
    ```

2. Then open project and run
