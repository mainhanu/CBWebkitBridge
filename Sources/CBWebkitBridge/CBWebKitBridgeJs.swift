//
//  CBWebKitBridgeJs.swift
//  testArticle
//
//  Created by maxingchi on 2020/5/11.
//  Copyright © 2020 maxingchi. All rights reserved.
//

import Foundation

@available(iOS 15.0, *)
extension CBWebkitBridge {
public static let jsScript = """
"use strict";
class CBWebKitBridge {
    constructor() {
        this.isDebug = true;
        this.uniqueId = 0;
        this.responseHandlers = {};
        this.messageHandlers = {};
    }
    // register an custom handler
    register(name, handler) {
        this.messageHandlers[name] = handler;
    }
    // call an native method
    call(name, data) {
        let callbackId = `js_cb_${this.uniqueId++}_${+Date.now()}`;
        let message = {
            handlerName: name,
            data,
            callbackId
        };
        const task = new Promise((resolve, reject) => {
            this.responseHandlers[callbackId] = { resolve, reject };
        });
        this.postMessage(message);
        return task;
    }
    // 这里的 handler 名称 __cbwbjsmessagehandler__ 必须与 native 端注册的名称保持一致
    postMessage(message) {
        window.webkit.messageHandlers.__cbwbjsmessagehandler__.postMessage(JSON.stringify(message));
    }
    // native 通过 evaluateJs 调用，用于【返回 native 执行结果】或者调用 【web 端方法】
    dispatch(msgStr) {
        let msg;
        try {
            msg = JSON.parse(decodeURIComponent(atob(msgStr)));
        }
        catch (e) {
            this.log(`[invalid json msg from native]${e.message}`);
            return;
        }
        // 如果有 responseId，表示是 js 端触发的异步任务，native 端执行完成后触发结果 callback
        if (msg.responseId) {
            let cb = this.responseHandlers[msg.responseId];
            if (!cb) {
                this.log("no callback from js with id", msg.responseId);
                return;
            }
            this.responseHandlers[msg.responseId] = undefined;
            let { resolve, reject } = cb;
            const { error = "", data = {} } = msg.data;
            if (!error) {
                resolve(data);
            }
            else {
                reject(Error(error));
            }
            return;
        }
        ;
        // 如果有 callbackId，表示是客户端调用 js 端，执行 js 端 handler，并将数据异步返回
        let { handlerName, data, callbackId } = msg;
        let handler = this.messageHandlers[handlerName];
        if (!handler) {
            this.log('no handler named', handlerName);
            return;
        }
        ;
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
            ;
        });
    }
    log(...params) {
        if (!this.isDebug)
            return;
        console.log(...params);
    }
}
;
window.cbWebKitBridge = new CBWebKitBridge();
""";
}
