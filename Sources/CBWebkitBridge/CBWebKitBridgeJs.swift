//
//  CBWebKitBridgeJs.swift
//  testArticle
//
//  Created by maxingchi on 2020/5/11.
//  Copyright © 2020 maxingchi. All rights reserved.
//

import Foundation

extension CBWebkitBridge {
public static let jsScript = """
"use strict";

(function() {
  class CBWebKitBridge {
    constructor() {
      this.messageHandlers = {};
      this.responseCallbacks = {};
      this.uniqueId = 0;
      this.isDebug = true;
    }
    register(name, handle) {
      this.messageHandlers[name] = handle;
    }
    call(name, data, callback) {
      let message = {
        handlerName: name,
        data
      };
      if (callback) {
        let callbackId = `js_cb_${this.uniqueId++}_${+Date.now()}`;
        this.responseCallbacks[callbackId] = callback;
        message.callbackId = callbackId;
      };
      this.postMessage(message);
    }
    // 这里的 handler 名称 __cbwbjsmessagehandler__ 必须与 native 端注册的名称保持一致
    postMessage(message) {
      window.webkit.messageHandlers.__cbwbjsmessagehandler__.postMessage(JSON.stringify(message));
    }
    dispatch(msgStr) {
      let msg
      try {
        msg = JSON.parse(decodeURIComponent(atob(msgStr)));
      } catch(e) {
        this.log(`[invalid json msg from native]${e.message}`);
        return;
      }
        
      // 如果有 responseId，表示是 js 端触发的异步任务，native 端执行完成后触发结果 callback
      if (msg.responseId) {
        let cb = this.responseCallbacks[msg.responseId];
        if (!cb) {
          this.log("no callback from js with id", msg.responseId);
          return;
        }
        const { error = "", data = {} } = msg.data;
        if (!error) {
          cb(null, data);
        } else {
          cb(Error(error), data);
        }
        return;
      };
        
      // 如果有 callbackId，表示是客户端调用 js 端，执行 js 端 handler，并将数据异步返回
      let { handlerName, data, callbackId } = msg;
      let handler = this.messageHandlers[handlerName];
      if (!handler) {
        this.log('no handler named', handlerName);
        return;
      };
      handler(data, (error, result) => {
        if (callbackId) {
          this.postMessage({
            responseId: callbackId,
            data: {
              error: error || "",
              data: result
            }
          });
        };
      });
    }
    log(...params) {
      if (!this.isDebug) return;
      console.log(...params);
    }
  };

  window.cbWebKitBridge = new CBWebKitBridge();
})();
""";
}
