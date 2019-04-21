//
//  KRNResponseParser.swift
//  KRNRequestManagerExample
//
//  Created by Julian Drapaylo on 22/07/2018.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import Foundation

public enum KRNParseResponseFormat  {
    case none // not parse
    case json // parse as json
    case string // parse as string
}

open class KRNResponseParser {
    open func parseAsJson(response: Data) -> Any? {
        do {
            let parsed = try JSONSerialization.jsonObject(with: response,
                                                          options: .allowFragments)
            return parsed
        } catch _ as NSError {
            return nil //error parsing
        }
    }
    
    open func parseAsString(response : Data) -> String? {
        return String(data: response, encoding: .utf8)
    }
    
    open func parseDataResponse(response: Data,
                                parseResponseFormat: KRNParseResponseFormat,
                                completion: @escaping ResponseCompletion) {
        
        switch parseResponseFormat {
        case .json:
            guard let jsonObject = parseAsJson(response: response) else {
                completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.errorParsingAsJson.rawValue,
                                             rawData: response))
                return
            }
            completion(jsonObject, nil)
        case .string:
            guard let stringObject = parseAsString(response: response) else {
                completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.errorParsingAsString.rawValue,
                                             rawData: response))
                return
            }
            completion(stringObject, nil)
        default: // on none just return
            completion (response, nil)
        }
    }
    
    
    // parse with Swift 4/5 JSON decoder (with debug functionality)
    open func parseWithJSONDecoder<T: Decodable>(response: Any,
                                                 decodableType: T.Type,
                                                 isDebug: Bool = false) -> (T?, NetworkError?) {
        
        guard let response = response as? Data else {
            return (nil, NetworkError(originalErrorMessage: "Invalid network response"))
        }
        let decoder = JSONDecoder()
        
        do {
            if isDebug {
                let dict = try JSONSerialization.jsonObject(with: response, options: .allowFragments)
                if let diction = dict as? [String: Any] {
                    print(diction as NSDictionary)
                } else if let array = dict as? [[String: Any]] {
                    print(array as NSArray)
                }
            }

            let result = try decoder.decode(decodableType, from: response)
            return (result, nil)
        } catch let error as NSError {
            if isDebug {
                print(error.localizedDescription)
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let mismType, let context):
                        print("Type mismatch error = \(mismType). Context = \(context)")
                    default:
                        print("\(decodingError)")
                    }
                }
            }
            return (nil, NetworkError(originalErrorMessage: "Error decoding network response"))
        }
    }

}
