//
//  JSONConvertible.swift
//  KRNRequestManagerExample
//
//  Created by Julian Drapaylo on 23/03/2019.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import Foundation

public protocol JSONConvertible {
    func toJSONData() throws -> Data
    func debugOutput()
}

// MARK: - Common extensions that conform to JSONConvertible

extension Dictionary: JSONConvertible {
    public func toJSONData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self,
                                          options: .init(rawValue: 0))
    }
    
    public func debugOutput() {
        print(self as NSDictionary)
    }
}

extension Array: JSONConvertible {
    public func toJSONData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self,
                                          options: .init(rawValue: 0))
    }
    
    public func debugOutput() {
        print(self as NSArray)
    }
}

public extension Encodable where Self: JSONConvertible {
    func toJSONData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    func debugOutput() {
        do {
            let data = try self.toJSONData()
            switch try JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) {
                case let dict as [String: Any]:
                    dict.debugOutput()
                case let array as Array<Any>:
                    array.debugOutput()
                default:
                    print("Unknown encodable")
            }
        } catch let error {
            print("Error debug output for \(self). Error: \(error)")
        }
    }
}
