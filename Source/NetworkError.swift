//
//  NetworkError.swift
//  decidediet
//
//  Created by ulian_onua on 1/14/18.
//  Copyright © 2018 julian. All rights reserved.
//

import Foundation

public struct NetworkError {
    public let statusCode : Int?
    public var originalErrorMessage = ""
    public let rawData : Data?
    
    public init(statusCode : Int? = nil, originalErrorMessage : String, rawData : Data? = nil) {
        self.statusCode = statusCode
        self.originalErrorMessage = originalErrorMessage
        self.rawData = rawData
    }
    
    public init(statusCode : Int, rawData : Data?) {
        self.statusCode = statusCode
        self.rawData = rawData
    }

    public var jsonDictErrorData : [String : Any]? {
        guard let rawData = self.rawData else {return nil}
        do {
            let dict = try JSONSerialization.jsonObject(with: rawData, options: .allowFragments) as? [String:Any]
            return dict
        } catch _ as NSError {
            return nil
        }
    }
    
    public var stringErrorData : String? {
        guard let rawData = self.rawData else {return nil}
        return String(data: rawData, encoding: .utf8)
    }
    
    public var valuableErrorData : String {
        if originalErrorMessage.count > 0 {
            return originalErrorMessage
        } else {
            return stringErrorData ?? "Unknown error"
        }
    }
}
