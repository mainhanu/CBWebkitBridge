import XCTest
import SwiftyJSON
import JavaScriptCore
@testable import CBWebkitBridge

final class CBWebkitBridgeTests: XCTestCase {
  func testJSON() {
    let exception = XCTestExpectation(description: "get data from gitlab")
    
    let task = URLSession.shared.dataTask(with: URL(string: "http://gitlab.alibaba-inc.com/api/v3/projects/484983/repository/commits/19e24681c1789770f978f7e59ceca4138c232905/diff?private_token=62hpYzDfySRmLm7AWSDR")!) { (data, _, _) in
      let json = try! JSON(data: data!)
      let msg = CBWBMessage(type: .response, handlerName: "hello", data: json, callbackId: nil, responseId: "json");
      
      let ctx = JSContext()!;
//      let str = """
//            JSON.parse(\(msg.description))
//      """
      let str = """
      a = `\(msg.description)`
      """
      let jsValue = ctx.evaluateScript(str)
      print(jsValue)
      
      exception.fulfill()
    }
    task.resume();
    wait(for: [exception], timeout: 10)
  }
  
  static var allTests = [
    ("testExample", testJSON),
  ]
}
