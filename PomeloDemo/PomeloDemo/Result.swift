//
//  Result.swift
//  PomeloDemo
//
//  Created by little2s on 16/3/14.
//  Copyright © 2016年 Ninty. All rights reserved.
//

import Foundation

enum Result<T> {
    case Success(T)
    case Failure(ErrorType)
    
    var isSuccess: Bool {
        switch self {
        case .Success:
            return true
        case .Failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var value: T? {
        switch self {
        case .Success(let value):
            return value
        case .Failure:
            return nil
        }
    }
    
    var error: ErrorType? {
        switch self {
        case .Success:
            return nil
        case .Failure(let error):
            return error
        }
    }
}

extension Result: CustomStringConvertible {
    var description: String {
        switch self {
        case .Success:
            return "SUCCESS"
        case .Failure:
            return "FAILURE"
        }
    }
}