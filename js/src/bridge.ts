interface Message {
  handlerName?: string;
  data: any;
  callbackId?: string;
  responseId?: string
}

export class CBWebKitBridge {
  private messageHandlers: Record<string, Function> = {}
  private responseCallbacks: Record<string, Function> = {}
  isDebug = true;
  private uniqueId = 0;

  register(name: string, handle: Function) {
    this.messageHandlers[name] = handle;
  }
  call(name: string, data: any, callback: Function) {
    let message: Message = {
      handlerName: name,
      data,
    };
    if (callback) {
      let callbackId = `js_cb_${this.uniqueId++}_${+Date.now()}`;
      this.responseCallbacks[callbackId] = callback;
      message.callbackId = callbackId;
    }
    this.postMessage(message);
  }
  // native 调用
  dispatch(msgStr: string) {
    let msg;
    try {
      msg = JSON.parse(decodeURIComponent(atob(msgStr)));
    } catch (e: any) {
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
    }

    // 如果有 callbackId，表示是客户端调用 js 端，执行 js 端 handler，并将数据异步返回
    let { handlerName, data, callbackId } = msg;
    let handler = this.messageHandlers[handlerName];
    if (!handler) {
      this.log("no handler named", handlerName);
      return;
    }
    handler(data, (error: Error, result: any) => {
      if (callbackId) {
        this.postMessage({
          responseId: callbackId,
          data: {
            error: error || "",
            data: result,
          },
        });
      }
    });
  }

  // 这里的 handler 名称 __cbwbjsmessagehandler__ 必须与 native 端注册的名称保持一致
  private postMessage(message: Message) {
    (window as any).webkit.messageHandlers.__cbwbjsmessagehandler__.postMessage(
      JSON.stringify(message)
    );
  }

  private log(...params: any[]) {
    if (!this.isDebug) return;
    console.log(...params);
  }
}
