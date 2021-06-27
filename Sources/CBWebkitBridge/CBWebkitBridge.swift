//
//  CBWebkitBridge.swift
//  libtest
//
//  Created by mxc on 2019/2/15.
//  Copyright © 2019 mxc. All rights reserved.
//

import WebKit
import SwiftyJSON

@available(iOS 15.0, *)
public class CBWebkitBridge: NSObject, WKScriptMessageHandler {
  let webview: WKWebView!
  var messageHandlers: [String: CBWBHandler] = [:]
  var responseContinuations: [String: UnsafeContinuation<JSON, Error>] = [:];
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
  
  public func call(name: String, data: JSON) async throws -> JSON {
    self.uniqueId += 1;
    let callbackId = "native_cb_\(self.uniqueId)_\(Int(Date().timeIntervalSince1970 * 1000))";
    
    let msg = CBWBMessage(type: .handler, handlerName: name, data: data, callbackId: callbackId, responseId: nil);
    self.dispatchToJs(msg: msg);
    
    return try await withUnsafeThrowingContinuation { cont in
      self.responseContinuations[callbackId] = cont;
    }
  }
  
  public func dispatchToJs(msg: CBWBMessage) {
    let js = "cbWebKitBridge.dispatch(`\(msg.description)`)";
    
    DispatchQueue.main.async {
      self.webview.evaluateJavaScript(js, completionHandler: nil);
    }
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
      guard let responseId = msg.responseId, let continuation = responseContinuations[responseId] else {
        log("no response continuation with responseId \(msg.responseId ?? "")")
        return;
      }
      
      responseContinuations[responseId] = nil;
      
      // error 转换
      guard let error = msg.data["error"].string else {
        continuation.resume(throwing: CBWBError(error: "invalid response data"))
        return;
      };
      
      if error != "" {
        let err = CBWBError(error: error);
        continuation.resume(throwing: err);
      } else {
        let result = msg.data["data"];
        continuation.resume(returning: result);
      }
      
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
