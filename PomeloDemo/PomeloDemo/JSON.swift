//
//  JSON.swift
//  PomeloDemo
//
//  Created by little2s on 16/3/14.
//  Copyright © 2016年 Ninty. All rights reserved.
//

import Foundation

/// The object must have the following properties: All objects are NSString/String, NSNumber/Int/Float/Double/Bool, NSArray/Array, NSDictionary/Dictionary, or NSNull; All dictionary keys are NSStrings/String; NSNumbers are not NaN or infinity.
public typealias JSONObject = [String: AnyObject]

func parseJSON(data: NSData) -> JSONObject? {
    guard let result = try? NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) else {
        return nil
    }
    
    if let dictionary = result as? JSONObject {
        return dictionary
    } else if let array = result as? [JSONObject] {
        // a little tricky here ...
        return ["data": array]
    } else {
        return nil
    }
}

func dumpJSON(json: JSONObject) -> NSData? {
    guard let data = try? NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions()) else {
        return nil
    }

    return data
}