//
//  ChatAdapterAPI.swift
//  PomeloDemo
//
//  Created by little2s on 16/7/12.
//  Copyright © 2016年 little2s. All rights reserved.
//

import Foundation

private let chatAdapterAddress = "192.168.2.145:3001"

struct ChatAdapterAPI {
    
    enum ErrorCode: Int {
        case ParametersError = -9001
    }
    
    static let Domain = "io.github.little2s.PomeloDemo.error"
    
    static func errorWithCode(code: Int, failureReason: String) -> NSError {
        let userInfo = [NSLocalizedFailureReasonErrorKey: failureReason]
        return NSError(domain: Domain, code: code, userInfo: userInfo)
    }
    
    static let baseURL: NSURL = {
        return NSURL(string: "http://\(chatAdapterAddress)")!
    }()
    
}

// MARK: Account API
extension ChatAdapterAPI {
    
    struct UserInfo {
        let userId: String
    }
    
    struct Server {
        let host: String
        let port: Int
    }
    
    typealias LoginInfo = (token: String, userInfo: UserInfo, server: Server)
    
    static func loginResourceWithAccount(
        account: String,
        password: String,
        type: String) -> HTTPResource<LoginInfo>
    {
        let path = "account/login"
        
        let params: JSONObject = [
            "account": account,
            "passwd": password,
            "type": type
        ]
        
        let parse: JSONObject -> Result<LoginInfo> = { rawJSON in
            
            let rst = parseHeaderForJSON(rawJSON)
            if rst.isFailure {
                return .Failure(rst.error!)
            }
            
            let json = rst.value!
            
            guard let
                data = json["data"] as? JSONObject,
                token = data["access_token"] as? String,
                userInfo = data["userinfo"] as? JSONObject,
                userId = userInfo["uid"] as? String,
                server = data["server"] as? JSONObject,
                host = server["host"] as? String,
                port = server["port"] as? NSNumber else {
                    return .Failure(HTTPError.ParseDataFailed)
            }
            
            let u = UserInfo(userId: userId)
            
            let s = Server(host: host, port: port.integerValue)
            
            return .Success((token, u, s))
        }
        
        let resource = jsonResource(baseURL, path: path, method: .GET, parameters: params, parse: parse)
        
        return resource
    }
    
}

// MARK: Convenience
extension ChatAdapterAPI {

    static func parseHeaderForJSON(json: JSONObject) -> Result<JSONObject> {
        
        loggingChatAdapterAPIJSON(json)
        
        guard let code = json["code"] as? NSNumber else {
            return .Failure(HTTPError.ParseDataFailed)
        }
        
        // API error
        guard code.integerValue == 0 else {
            return .Failure(errorWithCode(code.integerValue, failureReason: ""))
        }

        return .Success(json)
    }
    
    static func voidParse(json: JSONObject) -> Result<Void> {
        let result = parseHeaderForJSON(json)
        switch result {
        case .Success(_):
            return .Success()
        case .Failure(let e):
            return .Failure(e)
        }
    }
    
}

// MARK: Request chat adapter resource
func requestChatAdapterResource<T>(
    resource: HTTPResource<T>,
    modifyRequest: (NSMutableURLRequest -> Void)? = nil,
    completionHandler: (Result<T> -> Void)? = nil) -> NSURLSessionTask
{
    let client = HTTPClient.sharedClient
    
    let task = client.requestResource(resource,
                                      
        modifyRequest: { (request) -> Void in
        
            modifyRequest?(request)
            loggingChatAdapterAPIRequest(request)
        
        },
        
        completionHandler: { result -> Void in
            
            loggingChatAdapterAPIResult(result, resource: resource)
            
            dispatch_async(dispatch_get_main_queue()) {
                completionHandler?(result)
            }
            
        }
    )
    
    return task
}

// MARK: Chat adapter API logging
private func loggingChatAdapterAPIRequest(request: NSURLRequest) {
    print("ChatAdapter request ======>")
    print("Request: \(request.HTTPMethod ?? "") \(request.URL ?? "")")
    print("cURL: \n\(request.cURLCommandLine)")
}

private func loggingChatAdapterAPIJSON(json: JSONObject) {
    print("ChatAdapter response <------")
    print("JSON: \n\(json)")
}

private func loggingChatAdapterAPIResult<T>(result: Result<T>, resource: HTTPResource<T>) {
    switch result {
    case .Success(let value):
        print("ChatAdapter response <======")
        print("Value: \(value)")
        print("Resource: \(resource)")
    case .Failure(let error):
        print("ChatAdapter response <======")
        print("Error: \(error)")
        print("Resource: \(resource)")
    }
}