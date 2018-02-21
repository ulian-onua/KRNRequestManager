//
//  NetworkError.swift
//  decidediet
//
//  Created by ulian_onua on 1/14/18.
//  Copyright © 2018 julian. All rights reserved.
//

import Foundation
//
//  NetworkError.swift
//
//  Created by ulian_onua on 11/16/17.
//  Copyright © 2017 julian. All rights reserved.
//

import Foundation

struct NetworkError {
    var statusCode : Int?
    var originalErrorMessage = ""
    var rawData : Data?
    
    init(statusCode : Int? = nil, originalErrorMessage : String, rawData : Data? = nil) {
        self.statusCode = statusCode
        self.originalErrorMessage = originalErrorMessage
        self.rawData = rawData
    }
    
    init (statusCode : Int, rawData : Data?) {
        self.statusCode = statusCode
        self.rawData = rawData
    }

    var jsonDictErrorData : [String : Any]? {
        guard let rawData = self.rawData else {return nil}
        do {
            let dict = try JSONSerialization.jsonObject(with: rawData, options: .allowFragments) as? [String:Any]
            return dict
        } catch _ as NSError {
            return nil
        }
    }
    
    var stringErrorData : String? {
        guard let rawData = self.rawData else {return nil}
        return String(data: rawData, encoding: .utf8)
    }
    
    var valuableErrorData : String {
        if originalErrorMessage.count > 0 {
            return originalErrorMessage
        } else {
            return stringErrorData ?? "Unknown error"
        }
    }
}
