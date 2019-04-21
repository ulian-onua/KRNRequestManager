//
//  NetworkError.swift
//  decidediet
//
//  Created by Julian Drapaylo on 1/14/18.
//  Copyright © 2019 Julian Drapaylo . All rights reserved.
//

import Foundation

public class NetworkError: Error {
    
    // MARK: - Stored properties
    
    public let statusCode: Int?
    public let originalErrorMessage: String
    public let rawData: Data?
    
 
    // MARK: - Initializers
    
    public init(statusCode: Int? = nil, originalErrorMessage: String, rawData: Data? = nil) {
        self.statusCode = statusCode
        self.originalErrorMessage = originalErrorMessage
        self.rawData = rawData
    }
    
    public init(statusCode: Int, rawData: Data?) {
        self.statusCode = statusCode
        self.originalErrorMessage = ""
        self.rawData = rawData
    }
    
    // MARK: - Localized description support
    
    public var localizedDescription: String {
        return NSLocalizedString(valuableErrorData, bundle: .main, comment: "")
    }

    // MARK: - Different data type computed properties
    
    public var jsonDictErrorData: [String: Any]? {
        guard let rawData = self.rawData else { return nil }
        do {
            let dict = try JSONSerialization.jsonObject(with: rawData,
                                                        options: .allowFragments) as? [String: Any]
            return dict
        } catch _ as NSError {
            return nil
        }
    }
    
    public var stringErrorData: String? {
        guard let rawData = self.rawData else { return nil }
        return String(data: rawData, encoding: .utf8)
    }
    
    public var valuableErrorData: String {
        if originalErrorMessage.count > 0 {
            return originalErrorMessage
        } else {
            return stringErrorData ?? "Unknown error"
        }
    }
}
