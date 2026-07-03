//
//  CBWBMessage.swift
//  libtest
//
//  Created by mxc on 2019/2/15.
//  Copyright © 2019 mxc. All rights reserved.
//

import SwiftyJSON
import Foundation

public typealias CBWBResponseCallback = (_ error: CBWBError?, _ result: JSON?) -> Void
public typealias CBWBHandler = (_ data: JSON?, _ callback: @escaping CBWBResponseCallback) -> Void

public enum CBWBMessageType {
  case response
  case handler
}

public struct CBWBMessage: CustomStringConvertible {
  var type: CBWBMessageType
  var handlerName: String?;
  var data: JSON;
  var callbackId: String?;
  var responseId: String?;
  
  public var description: String {
    var result = JSON();
    result["handlerName"].string = handlerName;
    result["callbackId"].string = callbackId;
    result["responseId"].string = responseId;
    result["data"] = data;

    // 用 JSONSerialization 路径（options: [] 紧凑输出，无嵌套深度限制）；
    // 不能用 rawString([.castNilToNSNull: true])——那条手写路径 maxObjectDepth 默认 10，
    // 深层嵌套（如带 media 缩略图的 websearch 结果）会返回 nil，强解包导致 crash。
    guard let raw = result.rawString(options: []),
          let encoded = encodeJSON(raw).encodeURIComponent()?.base64() else {
      return "";
    }

    return encoded;
  }
  
  public init(type: CBWBMessageType, handlerName: String?, data: JSON, callbackId: String?, responseId: String?) {
    self.type = type;
    self.handlerName = handlerName;
    self.data = data;
    self.callbackId = callbackId;
    self.responseId = responseId;
  }
  
  // init from message body
  public init?(body: Any) {
    guard let bodtStr = body as? String else {
      return nil;
    }
    let result = JSON(parseJSON: bodtStr);
    
    let data = result["data"];
    let callbackId = result["callbackId"].string;
    
    var responseId: String? = nil;
    var type: CBWBMessageType
    var handlerName: String? = nil;
    
    if let mresponseId = result["responseId"].string {
      type = .response;
      responseId = mresponseId;
    } else if let mhandlerName = result["handlerName"].string {
      type = .handler;
      handlerName = mhandlerName;
    } else {
      // invalid message
      return nil;
    }
    
    self.init(type: type, handlerName: handlerName, data: data, callbackId: callbackId, responseId: responseId)
  }
  
  public func toString() -> [String: Any?] {
    let val: [String: Any?] = [
      "handlerName": self.handlerName,
      "data": self.data,
      "callbackId": self.callbackId,
      "responseId": self.responseId
    ];
    return val;
  }
  
  public func encodeJSON(_ json: String) -> String {
    // 防止 json 传输过程问题
    var jsonStr = json;
    
//    jsonStr = jsonStr.replacingOccurrences(of: "\\", with: "\\\\")
//    jsonStr = jsonStr.replacingOccurrences(of: "\"", with: "\\\"")
//    jsonStr = jsonStr.replacingOccurrences(of: "\'", with: "\\\'")
    jsonStr = jsonStr.replacingOccurrences(of: "\n", with: "\\n")
    jsonStr = jsonStr.replacingOccurrences(of: "\r", with: "\\r")
    jsonStr = jsonStr.replacingOccurrences(of: "\t", with: "\\t")
    jsonStr = jsonStr.replacingOccurrences(of: "\u{8}", with: "\\b")
//    jsonStr = jsonStr.replacingOccurrences(of: #"\f"#, with: #"\\f"#)
//    jsonStr = jsonStr.replacingOccurrences(of: "\u{2028}", with: "\\u{2028}")
//    jsonStr = jsonStr.replacingOccurrences(of: "\u{2029}", with: "\\u{2029}")
    
    return jsonStr;
  }
}

extension String {
    
  func encodeURIComponent() -> String? {
    let characterSet = NSMutableCharacterSet.urlQueryAllowed

    return self.addingPercentEncoding(withAllowedCharacters: characterSet)
  }
  
  func base64() -> String? {
    let utf8str = self.data(using: .utf8)

    if let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0)) {
      return base64Encoded;
    }
    return nil;
  }

}
