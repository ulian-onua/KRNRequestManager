//
//  EncodingType.swift
//  KRNRequestManagerExample
//
//  Created by kornet on 4/21/19.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import UIKit

public enum EncodingType {
    case url
    case json
    case urlJsonMultiEncoded // both url and json encoded params in one request
    case formUrl
}
