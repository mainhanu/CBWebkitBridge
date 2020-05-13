//
//  CBWebkitBridge.swift
//  libtest
//
//  Created by mxc on 2019/2/15.
//  Copyright © 2019 mxc. All rights reserved.
//

import WebKit
import SwiftyJSON

public class CBWebkitBridge: NSObject, WKScriptMessageHandler {
    let webview: WKWebView!
    var messageHandlers: [String: CBWBHandler] = [:]
    var responseCallbacks: [String: CBWBResponseCallback] = [:];
    var uniqueId = 0;
    var scrpitmessagename = "__cbwbjsmessagehandler__";
    var isDebug = true;
    
    public init(webview: WKWebView) {
        self.webview = webview;
        super.init();
        self.config(userContentController: self.webview.configuration.userContentController);
    }
    
    public func config(userContentController: WKUserContentController) {
        let bridgejs = CBWebkitBridge.jsScript;
        let userscript = WKUserScript(source: bridgejs, injectionTime: .atDocumentStart, forMainFrameOnly: true);
        
        userContentController.addUserScript(userscript);
        userContentController.add(self, name: scrpitmessagename);
    }
    
    public func register(name: String, handler: @escaping CBWBHandler) {
        self.messageHandlers[name] = handler;
    }
    
    public func call(name: String, data: JSON, callback: CBWBResponseCallback?) {
        var callbackId: String? = nil;
        if let callback = callback {
            self.uniqueId += 1;
            callbackId = "native_cb_\(self.uniqueId)_\(Int(Date().timeIntervalSince1970 * 1000))";
            self.responseCallbacks[callbackId!] = callback;
        }
        let msg = CBWBMessage(type: .handler, handlerName: name, data: data, callbackId: callbackId, responseId: nil);
        self.dispatchToJs(msg: msg);
    }
    
    public func dispatchToJs(msg: CBWBMessage) {
        var jsonStr = msg.description;

        // 防止 json 传输过程问题
        jsonStr = jsonStr.replacingOccurrences(of: "\\", with: "\\\\")
        jsonStr = jsonStr.replacingOccurrences(of: "\"", with: "\\\"")
        jsonStr = jsonStr.replacingOccurrences(of: "\'", with: "\\\'")
        jsonStr = jsonStr.replacingOccurrences(of: "\n", with: "\\n")
        jsonStr = jsonStr.replacingOccurrences(of: "\r", with: "\\r")
        jsonStr = jsonStr.replacingOccurrences(of: #"\f"#, with: #"\\f"#)
        jsonStr = jsonStr.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
        jsonStr = jsonStr.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")

        let js = "cbWebKitBridge.dispatch('\(jsonStr)')";
        webview.evaluateJavaScript(js, completionHandler: nil);
    }
    
    public func log(_ message: Any...) {
        if !isDebug {
            return;
        };
        print("[CBWebkitBridge]", message);
    }
    
    // MARK: - WKScriptMessageHandler
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name != scrpitmessagename {
            log("receive invalid WKScriptMessage, name: \(message.name)")
            return;
        };
        
        guard let msg = CBWBMessage(body: message.body) else {
            log("post message body can not convert to CBWBMessage");
            return;
        }
        
        if msg.type == .response {
            guard let responseId = msg.responseId, let handler = responseCallbacks[responseId] else {
                log("no response callback with responseId \(msg.responseId ?? "")")
                return;
            }
            
            // error 转换
            guard let error = msg.data["error"].string else {
                log("invalid response data")
                return;
            };
            var err: CBWBError? = nil;
            if error != "" {
                err = CBWBError(error: error);
            };
            let result = msg.data["data"]
            handler(err, result);
            
            return;
        }
        
        // check handler name
        guard let handlerName = msg.handlerName, let handler = self.messageHandlers[handlerName] else {
            log("no native handle named \(msg.handlerName ?? "")")
            return;
        };
        
        handler(msg.data) { (error, data) in
            guard let callbackId = msg.callbackId else {
                return;
            };
            
            var result = JSON();
            result["error"].string = error?.toString()
            result["data"] = data ?? "";
            
            self.dispatchToJs(msg: CBWBMessage(type: .response, handlerName: nil, data: result, callbackId: nil, responseId: callbackId));
        }
    }
}
