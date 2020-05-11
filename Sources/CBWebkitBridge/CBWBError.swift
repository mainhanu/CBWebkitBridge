//
//  CBWBError.swift
//  libtest
//
//  Created by mxc on 2019/2/15.
//  Copyright © 2019 mxc. All rights reserved.
//

public enum CBWBError: Error, CustomStringConvertible {
  case invalidParam
  case noNativeHandler(String)
  case noJsHandler(String)
  case common(message: String)
  
  public init(error: String) {
    var message = "";
    var data = "";
    
    let msgs = error.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: true);
    if msgs.count != 2 {
      message = error;
    } else {
      message = String(msgs[0]);
      data = String(msgs[1]);
    }
    
    switch message {
    case "invalidParam":
      self = .invalidParam;
    case "noNativeHandler":
      self = .noNativeHandler(data);
    case "noJsHandler":
      self = .noJsHandler(data)
    default:
      self = .common(message: message)
    }
  }
  
  public func toString() -> String {
    return self.description
  }
  
  public var description: String {
    switch self {
    case .invalidParam:
      return "invalidParam"
    case .noNativeHandler(let msg):
      return "noNativeHandler:\(msg)";
    case .noJsHandler(let msg):
      return "noJsHandler:\(msg)";
    case .common(let message):
      return message
    }
  }
}
