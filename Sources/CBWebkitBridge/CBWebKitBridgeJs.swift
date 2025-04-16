
import Foundation

extension CBWebkitBridge {
public static let jsScript = """
(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else {
		var a = factory();
		for(var i in a) (typeof exports === 'object' ? exports : root)[i] = a[i];
	}
})(self, function() {
return /******/ (function() { // webpackBootstrap
/******/ 	"use strict";
/******/ 	// The require scope
/******/ 	var __webpack_require__ = {};
/******/ 	
/************************************************************************/
/******/ 	/* webpack/runtime/make namespace object */
/******/ 	!function() {
/******/ 		// define __esModule on exports
/******/ 		__webpack_require__.r = function(exports) {
/******/ 			if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 				Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 			}
/******/ 			Object.defineProperty(exports, '__esModule', { value: true });
/******/ 		};
/******/ 	}();
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// ESM COMPAT FLAG
__webpack_require__.r(__webpack_exports__);

;// CONCATENATED MODULE: ./src/bridge.ts
class CBWebKitBridge {
  messageHandlers = {};
  responseCallbacks = {};
  responseResolvers = {};
  isDebug = true;
  uniqueId = 0;
  constructor(messageHandlerName) {
    this.messageHandlerName = messageHandlerName;
  }
  register(name, handle) {
    this.messageHandlers[name] = handle;
    return () => {
      delete this.messageHandlers[name];
    };
  }
  call(name, data, callback) {
    let message = {
      handlerName: name,
      data
    };
    if (callback) {
      let callbackId = this.generateResponseId('callback');
      this.responseCallbacks[callbackId] = callback;
      message.callbackId = callbackId;
    }
    this.postMessage(message);
  }
  callAsync(name, data, timeout = 1000 * 30) {
    let callbackId = this.generateResponseId('promise');
    let message = {
      handlerName: name,
      data,
      callbackId
    };
    let r = {
      resolve: () => {},
      reject: () => {}
    };
    const p = Promise.race([new Promise((resolve, reject) => {
      r.resolve = resolve;
      r.reject = reject;
    }), new Promise((_, reject) => setTimeout(() => reject(Error('timeout')), timeout))]);
    this.responseResolvers[callbackId] = r;
    this.postMessage(message);
    return p;
  }
  // native 调用
  dispatch(msgStr) {
    let msg;
    try {
      msg = JSON.parse(decodeURIComponent(atob(msgStr)));
    } catch (e) {
      this.log(`[invalid json msg from native]${e.message}`);
      return;
    }

    // 如果有 responseId，表示是 js 端触发的异步任务，native 端执行完成后触发结果 callback
    if (msg.responseId) {
      const type = this.getResponseType(msg.responseId);
      const {
        error = "",
        data = {}
      } = msg.data;
      if (type === 'callback') {
        let cb = this.responseCallbacks[msg.responseId];
        if (!cb) {
          this.log("no callback from js with id", msg.responseId);
          return;
        }
        if (!error) {
          cb(null, data);
        } else {
          cb(Error(error), data);
        }
      } else if (type === 'promise') {
        let prs = this.responseResolvers[msg.responseId];
        if (!prs) {
          this.log("no resolver from js with id", msg.responseId);
          return;
        }
        if (!error) {
          prs.resolve(data);
        } else {
          prs.reject(Error(error));
        }
      }
      return;
    }

    // 如果有 callbackId，表示是客户端调用 js 端，执行 js 端 handler，并将数据异步返回
    let {
      handlerName,
      data,
      callbackId
    } = msg;
    let handler = this.messageHandlers[handlerName];
    if (!handler) {
      this.log("no handler named", handlerName);
      return;
    }
    handler(data, (error, result) => {
      if (callbackId) {
        this.postMessage({
          responseId: callbackId,
          data: {
            error: error || "",
            data: result
          }
        });
      }
    });
  }
  generateResponseId(type) {
    return `js_${type}_${this.uniqueId++}_${+Date.now()}`;
  }
  getResponseType(id) {
    const prefixes = ['callback', 'promise'];
    for (let prefix of prefixes) {
      if (id.startsWith(`js_${prefix}`)) {
        return prefix;
      }
    }
    return undefined;
  }
  postMessage(message) {
    window.webkit.messageHandlers[this.messageHandlerName].postMessage(JSON.stringify(message));
  }
  log(...params) {
    if (!this.isDebug) return;
    console.log(...params);
  }
}
;// CONCATENATED MODULE: ./src/index.ts

window["__PLACEHOLDER__GLOBALNAME__"] = new CBWebKitBridge("__PLACEHOLDER__HANLDERNAME__");
/******/ 	return __webpack_exports__;
/******/ })()
;
}); 
"""
}

