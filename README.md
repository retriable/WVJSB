# WebViewJavaScriptBridge

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/retriable/WebViewJavaScriptBridge/master/LICENSE)
[![Build Status](https://img.shields.io/travis/retriable/WebViewJavaScriptBridge/master.svg?style=flat)](https://travis-ci.org/retriable/WebViewJavaScriptBridge)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/retriable/WebViewJavaScriptBridge)
[![Pod Version](https://img.shields.io/cocoapods/v/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)
[![Pod Platform](https://img.shields.io/cocoapods/p/WVJSB.svg?style=flat)](http://cocoapods.org/pods/WVJSB)

**Cross-iframe** WebView JavaScript Bridge.
## Installation

### Native
#### Cocoapods

Add the following to your project's Podfile:
```ruby
pod 'WVJSB'
```

#### Carthage

Add the following to your project's Cartfile:
```ruby
github "retriable/WebViewJavaScriptBridge"
```
### Web
Add [JavaScript](https://raw.githubusercontent.com/retriable/WebViewJavaScriptBridge/master/WVJSB/Resources/www/scripts/Client.js) to web project.

## Native usage
#### Create server
> Server is automatically associated with the web view.
```ObjC
    WVJSBServer *server=[WVJSBServer serverWithWebView:webView namespace:@"server namespace"];
```
#### Handle unresponsive request
```ObjC
[[server on:@"method"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
    done();
    return nil;
}];
```
#### Handle responsive request
```ObjC
[[server on:@"request"] onEvent:^id(WVJSBConnection * connection, id parameter, WVJSBAckBlock (^done)(void)) {
    done()(@"response object",nil);
    return nil;
}];
```
#### Handle cancelable request
```ObjC
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

#### Request to JavaScript client
```ObjC
WVJSBConnection *connection =  server.connections.allValues.lastObject;
WVJSBOperation *operation = [[[connection event:@"request" parameter:nil] onAck:^(WVJSBOperation *operation,id result, NSError *error) {
    //Do something with result
}] timeout:30];
```
#### Cancel request
```ObjC
[operation cancel];
```

### JavaScript usage
#### 
#### Create client

```JavaScript
const client = WVJSBClient('server namespace',{"key":"value"});
```
#### Handle unresponsive request
```JavaScript
client.on('method').onEvent(function(parameter,done){
    done();
})
```
#### Handle responsive request
```JavaScript
client.on('request').onEvent(function(parameter,done){
    done()('response object',null);
})
```
#### Handle cancelable request
```JavaScript
client.on('request').onEvent(function(parameter,done){
    const context = window.setTimeout(function(){
        done()('response object',null);
    },2000);
    return context;
}).onCancel(function(context){
    window.clearTimeout(context);
});
```
#### Request to native server
```JavaScript
const operation = client.event('request',null).onAck(function(operation,parameter,error){

}).timeout(30000);
```
#### Cancel request
```JavaScript
operation.cancel();
```

### Run Example

Open Terminal,and execute following
```shell
cd pathToProject/WVJSB/Resources/www
python -m SimpleHTTPServer
```

Then open project and run
