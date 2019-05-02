//
//  SwiftViewController.swift
//  WVJSB iOS Example
//
//  Created by retriable on 2019/4/9.
//  Copyright © 2019 retriable. All rights reserved.
//

import UIKit
import WVJSB

class SwiftViewController: UIViewController,UIWebViewDelegate {
    
    var operations:Array<WVJSBOperation> = Array<WVJSBOperation>()
    
    var connections:Array<WVJSBConnection> = Array<WVJSBConnection>()
    
    @IBOutlet weak var webView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.delegate=self
        let server=WVJSBServer(webView: webView!, ns: nil)
        server.on("immediate").onEvent { (connection, parameter, done) -> Any? in
            done()("immediate ack",nil);
            return nil;
        }
        server.on("delayed").onEvent { (connection, parameter, done) -> Any? in
            let timer = DispatchSource.makeTimerSource();
            timer.schedule(deadline: DispatchTime.now()+DispatchTimeInterval.seconds(2))
            timer.setEventHandler(handler: {
                done()("delayed ack",nil);
            })
            timer.resume()
            return timer
            }.onCancel { (context) in
                let timer = context as! DispatchSourceTimer
                timer.cancel()
        }
        reload(self)
        // Do any additional setup after loading the view.
    }
    

    @IBAction func reload(_ sender: Any) {
        let string = "http://localhost:8000/index.html";
//        let string = "http://192.168.2.2:8000/index.html";
        webView.loadRequest(URLRequest(url: URL(string:string)!))
    }
    
    @IBAction func immediate(_ sender: Any){
        objc_sync_enter(connections)
        for (connection) in connections{
            let operation = connection.event(type:"immediate", parameter: nil).onAck {[weak self] operation ,parameter, error in
                if  error != nil {
                    NSLog("did receive immediate error: \(error!)")
                }else{
                    NSLog("did receive immediate ack: \(parameter! as AnyObject)")
                }
                if var opts = self?.operations{
                    objc_sync_enter(opts)
                    if let idx=opts.firstIndex(where: { (o) -> Bool in
                        return o.isEqual(operation)
                    }){
                        opts.remove(at: idx);
                    }
                    objc_sync_exit(opts)
                }
            }.timeout(10)
            objc_sync_enter(operations)
            operations.append(operation)
            objc_sync_exit(operations)
        }
        objc_sync_exit(connections)
    }
    @IBAction func delayed(_ sender: Any){
        objc_sync_enter(connections)
        for (connection) in connections{
            let operation = connection.event(type:"delayed", parameter: nil).onAck {[weak self] operation, parameter, error in
                if  error != nil {
                    NSLog("did receive delayed error: \(error!)")
                }else{
                    NSLog("did receive delayed ack: \(parameter! as AnyObject)")
                }
                if var opts = self?.operations{
                    objc_sync_enter(opts)
                    if let idx=opts.firstIndex(where: { (o) -> Bool in
                        return o.isEqual(operation)
                    }){
                        opts.remove(at: idx);
                    }
                    objc_sync_exit(opts)
                }
                }.timeout(10)
            objc_sync_enter(operations)
            operations.append(operation)
            objc_sync_exit(operations)
        }
        objc_sync_exit(connections)
    }
    
    @IBAction func cancel(_ sender: Any) {
        objc_sync_enter(operations)
        for (operation) in operations{
            operation.cancel();
        }
        operations.removeAll();
        objc_sync_exit(operations)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        return !WVJSBServer.canHandle(webView: webView, URLString: request.url?.absoluteString);
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
