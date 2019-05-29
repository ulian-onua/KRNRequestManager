//
//  Response.swift
//  KRNRequestManagerExample
//
//  Created by kornet on 5/29/19.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import Foundation

public struct Response {
    public let statusCode: Int
    public let body: Any?  // can be json, string or other in accordance to parseFormat value
    public let parseFormat: ParseResponseFormat
}
