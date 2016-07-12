//
//  HTTPClient.swift
//  PomeloDemo
//
//  Created by little2s on 16/3/14.
//  Copyright © 2016年 Ninty. All rights reserved.
//

import Foundation

// MARK: HTTPMethod
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
}

extension HTTPMethod: CustomStringConvertible {
    var description: String {
        return self.rawValue
    }
}

// MARK: HTTPResource
struct HTTPResource<T> {
    let baseURL: NSURL
    let path: String
    let method: HTTPMethod
    let requestBody: NSData?
    let headers: [String: String]
    let parse: NSData -> Result<T>
}

extension HTTPResource: CustomStringConvertible {
    var description: String {
        var decodeRequestBody: String? = nil
        if let requestBody = requestBody {
            decodeRequestBody = String(data: requestBody, encoding: NSUTF8StringEncoding)
        }
        
        let unwrappedBequestBody = decodeRequestBody ?? ""
        
        return "HTTPResource<Method: \(method), path: \(path), headers: \(headers), requestBody: \(unwrappedBequestBody)>"
    }
}

// MARK: HTTPError

enum HTTPError: ErrorType {
    case NoResponse
    case NoData
    case ParseDataFailed
}

extension HTTPError {
    var description: String {
        switch self {
        case .NoResponse:
            return "No response"
        case .NoData:
            return "No data"
        case .ParseDataFailed:
            return "Parse data failed"
        }
    }
}

// MARK: HTTPClient
protocol HTTPClientProtocol {
    func requestResource<T>(resource: HTTPResource<T>, modifyRequest: (NSMutableURLRequest -> Void)?, completionHandler: (Result<T> -> Void)?) -> NSURLSessionTask
}

class HTTPClient: HTTPClientProtocol {
    
    class SessionDelegate: NSObject, NSURLSessionDelegate {
        
        func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            
            completionHandler(.UseCredential, NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
        }
    }
    
    static let sharedClient: HTTPClient = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        return HTTPClient(configuration: configuration)
    }()
    
    let session: NSURLSession
    let delegate: SessionDelegate
    
    init(configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration(),
        delegate: SessionDelegate = SessionDelegate())
    {
        self.delegate = delegate
        self.session = NSURLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }
    
    // MARK: HTTPClientProtocol
    func requestResource<T>(
        resource: HTTPResource<T>,
        modifyRequest: (NSMutableURLRequest -> Void)? = nil,
        completionHandler: (Result<T> -> Void)? = nil) -> NSURLSessionTask
    {
        let URL = resource.baseURL.URLByAppendingPathComponent(resource.path)
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = resource.method.rawValue
        
        // URL encode
        func needEncodesParametersForMethod(method: HTTPMethod) -> Bool {
            switch method {
            case .GET:
                return true
            default:
                return false
            }
        }
        
        func query(parameters: [String: AnyObject]) -> String {
            var components: [(String, String)] = []
            for key in Array(parameters.keys).sort(<) {
                let value: AnyObject! = parameters[key]
                components += queryComponents(key, value: value)
            }
            
            return (components.map{"\($0)=\($1)"} as [String]).joinWithSeparator("&")
        }
        
        func handleParameters() {
            if needEncodesParametersForMethod(resource.method) {
                guard let URL = request.URL else {
                    fatalError("Invalid URL of request: \(request)")
                }
                
                if let requestBody = resource.requestBody {
                    if let URLComponents = NSURLComponents(URL: URL, resolvingAgainstBaseURL: false) {
                        URLComponents.percentEncodedQuery = (URLComponents.percentEncodedQuery != nil ? URLComponents.percentEncodedQuery! + "&" : "") + query(parseJSON(requestBody)!)
                        request.URL = URLComponents.URL
                    }
                }
                
            } else {
                request.HTTPBody = resource.requestBody
            }
        }
        
        handleParameters()
        
        // set headers
        for (key, value) in resource.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // hook request by caller
        modifyRequest?(request)
        
        // create data task
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let error = error {
                completionHandler?(.Failure(error))
                return
            }
            
            guard let _ = response as? NSHTTPURLResponse else {
                completionHandler?(.Failure(HTTPError.NoResponse))
                return
            }
            
            guard let data = data else {
                completionHandler?(.Failure(HTTPError.NoData))
                return
            }
            
            let result = resource.parse(data)
            completionHandler?(result)
        }
        
        task.resume()
        
        return task
    }
}

// MARK: JSON resource helper
func jsonResource<T>(baseURL: NSURL, path: String, method: HTTPMethod, parameters: JSONObject, parse: JSONObject -> Result<T>) -> HTTPResource<T> {
    
    let jsonParse: NSData -> Result<T> = { data in
        if let json = parseJSON(data) {
            return parse(json)
        }
        return .Failure(HTTPError.ParseDataFailed)
    }
    
    let jsonBody = dumpJSON(parameters)
    let headers = [
        "Content-Type": "application/json",
    ]
    
    return HTTPResource(baseURL: baseURL, path: path, method: method, requestBody: jsonBody, headers: headers, parse: jsonParse)
}

// MARK: Private helpers
private func queryComponents(key: String, value: AnyObject) -> [(String, String)] {
    func escape(string: String) -> String {
        let legalURLCharactersToBeEscaped: String = ":/?&=;+!@#$()',*"
        return (string as NSString).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet(charactersInString: legalURLCharactersToBeEscaped))!
    }
    
    var components: [(String, String)] = []
    if let dictionary = value as? [String: AnyObject] {
        for (nestedKey, value) in dictionary {
            components += queryComponents("\(key)[\(nestedKey)]", value: value)
        }
    } else if let array = value as? [AnyObject] {
        for value in array {
            components += queryComponents("\(key)[]", value: value)
        }
    } else {
        components.appendContentsOf([(escape(key), escape("\(value)"))])
    }
    
    return components
}
