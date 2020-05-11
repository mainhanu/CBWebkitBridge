//
//  CBWBMessage.swift
//  libtest
//
//  Created by mxc on 2019/2/15.
//  Copyright © 2019 mxc. All rights reserved.
//

import SwiftyJSON

typealias CBWBResponseCallback = (_ error: CBWBError?, _ result: JSON?) -> Void
typealias CBWBHandler = (_ data: JSON?, _ callback: @escaping CBWBResponseCallback) -> Void

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
        
        return result.rawString([.castNilToNSNull: true])!
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
}
