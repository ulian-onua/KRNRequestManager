//
//  KRNResponseParser.swift
//  KRNRequestManagerExample
//
//  Created by Julian Ivanov on 22/07/2018.
//  Copyright © 2018 Julian Drapaylo. All rights reserved.
//

import Foundation

public enum KRNParseResponseFormat  {
    case none // not parse
    case json // parse as json
    case string // parse as string
    case decoder // parse with json decoder
}

open class KRNResponseParser {
    open func parseAsJson(response : Data) -> Any? {
        do {
            let parsed = try JSONSerialization.jsonObject(with: response, options: .allowFragments)
            return parsed
        } catch _ as NSError {
            return nil //error parsing
        }
    }
    
    open func parseAsString(response : Data) -> String? {
        return String.init(data: response, encoding: .utf8)
    }
    
    open func parseDataResponse(response : Data, parseResponseFormat : KRNParseResponseFormat, completion: @escaping ResponseCompletion) {
        switch parseResponseFormat {
        case .json:
            guard let jsonObject = parseAsJson(response: response) else {
                completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.errorParsingAsJson.rawValue, rawData: response))
                return
            }
            completion(jsonObject, nil)
        case .string:
            guard let stringObject = parseAsString(response: response) else {
                completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.errorParsingAsString.rawValue, rawData: response))
                return
            }
            completion(stringObject, nil)
        default: // on none just return
            completion (response, nil)
        }
    }
}
