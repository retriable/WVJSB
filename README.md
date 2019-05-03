# WVJSB

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/retriable/WVJSB/master/LICENSE)
[![Build Status](https://img.shields.io/travis/retriable/WVJSB/master.svg?style=flat)](https://travis-ci.org/retriable/WVJSB)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/retriable/WVJSB)
[![Pod Version](https://img.shields.io/cocoapods/v/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)
[![Pod Platform](https://img.shields.io/cocoapods/p/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)

**Cross-iframe** WebView JavaScript Bridge for iOS(8.0+) and macOS(10.10+), support WKWebView,UIWebView,WebView(macOS only).

[Android Support](https://github.com/retriable/WVJSB-Android)

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

## Inner declare

* Event `connect` is caused when client connected to server or server connected to client.

* Event `disconnect` is caused when client disconnected from server or server disconnected from client.

* Error `cancelled` is caused when request operation cancelled.

* Error `timed out` is caused when request operation timed out.

* Error `connection lost` is caused when client or server destroyed.

## Native usage
1. Create server

    > Server is automatically associated with the web view. It is not released until the web view is destroyed. 

    > `namespace` is used to mark different service.
    ```obj-c
        WVJSBServer *server=[WVJSBServer serverWithWebView:webView namespace:@"server namespace"];
    ```

2. Inspect URL
   * UIWebView

     >  Inspecting URL is required to let server install.

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
    * WebView

       ```obj-c
       - (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener{
       if ([WVJSBServer canHandleWithWebView:webView URLString:request.URL.absoluteString]){
           [listener ignore];
       }else{
           [listener use];
       }
}
       ```
*  Handle unresponsive event
    
    ```obj-c
    [[server on:@"method"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
        done();
        return nil;
    }];
    ```
* Handle connection

    ```obj-c
    [[server on:@"connect"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
        done();
        return nil;
    }];
    ```

* handle disconnection

    ```obj-c
    [[server on:@"disconnect"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
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
            if (arc4random()%2){
                done()(@"response object",nil);
            }else{
                done()(nil,[NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCannotFindHost userInfo:@{NSLocalizedDescriptionKey:@"can not find host"}]);
            }
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

* Handle unresponsive event

    ```js
    client.on('method').onEvent(function(parameter,done){
        done();
        return null;
    })
    ```

* Handle server's connection

    ```js
    client.on('connect').onEvent(function(parameter,done){
        done();
        return null;
    })
    ```

* Handle server's disconnection

    ```js
    client.on('disconnect').onEvent(function(parameter,done){
        done();
        return null;
    })
    ```


* Handle responsive request

    ```js
    client.on('request').onEvent(function(parameter,done){
        done()('response object',null);
        return null;
    })
    ```

* Handle cancelable request
    
    ```js
    client.on('request').onEvent(function(parameter,done){
        const context = window.setTimeout(function(){
            if(Math.random()<0.5){
                done()(null,{code:-1003,description:'can not find host'});                       
            }else{
                done()('response object',null);
            }
        },2000);
        return context;
    }).onCancel(function(context){
        window.clearTimeout(context);
    });
    ```

* Request to native server

    ```js
    const operation = client.event('request',null).onAck(function(operation,parameter,error){
        //do something
    }).timeout(10000);
    ```

* Cancel request

    ```js
    operation.cancel();
    ```

## Run Example

1. Open Terminal,and execute following

    ```shell
    cd pathToProject/WVJSB/Resources/www
    python -m SimpleHTTPServer
    ```

2. Then open project and run

## LICENSE

MIT License

Copyright (c) 2019 retriable

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.