//
//  Data+Extensions.swift
//
//  Created by Julian Drapaylo on 4/21/19.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
