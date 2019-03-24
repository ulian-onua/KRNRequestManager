//
//  KRNRequestManager.swift
//
//  Created by Julian Drapaylo
//  Copyright © 2018 Julian Drapaylo. All rights reserved.
//

import Foundation

public enum HttpMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum KRNReqErrorString: String {
    case invalidUrl = "Invalid URL"
    case errorJsonEncoding = "Error json encoding"
    case errorResponseFormat = "Response is not HTTP response"
    case errorParsingAsJson = "Error response format. Not JSON."
    case errorParsingAsString = "Error response format. Not String."
}

public typealias ResponseCompletion = (Any?, NetworkError?) -> Void

open class KRNRequestManager {
    public let urlSession: URLSession
    public let responseParser = KRNResponseParser()
    private (set) var baseUrl: String
    
    public var isDebug: Bool {
        set {
            (isDebugRequests, isDebugResponses) = (true, true)
        }
        get {
            return isDebugRequests && isDebugResponses
        }
    }
    
    public var isDebugRequests = false
    
    public var isDebugResponses = false // will be supported in next versions
    
    // MARK: - Initializers
    
    public init(url: String, configuration: URLSessionConfiguration) {
        urlSession = URLSession(configuration: configuration)
        self.baseUrl = url
    }
    
    public convenience init(url: String) {
        self.init(url: url, configuration: .default)
    }
    
    private func setBaseUrl(_ url: String) {
        self.baseUrl = url
    }
    
    // MARK: - Requests
    
    open func requestJSON(method: HttpMethod,
                          shortURL: String,
                          params: JSONConvertible?,
                          headerParams: [String: String]?,
                          parseFormat: KRNParseResponseFormat = .none,
                          completion: @escaping ResponseCompletion) {
       
        guard let url = URL(string: baseUrl + shortURL) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        if isDebugRequests {
            print("Request JSON -> \(baseUrl + shortURL)")
        }
        
        var jsonHeaderParams: [String: String] = headerParams ?? [String: String]()
        jsonHeaderParams["Content-Type"] = "application/json"
        
        if isDebugRequests {
            print("Headers->\n\(jsonHeaderParams as NSDictionary)")
        }
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: jsonHeaderParams)
        
        // set params
        if let params = params {
            do {
                let data = try params.toJSONData()
                
                if isDebugRequests {
                    print("JSON params ->")
                    print(params.debugOutput())
                }
                
                urlRequest.httpBody = data
            } catch _ as NSError {
                completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.errorJsonEncoding.rawValue))
                return
            }
        }
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    open func requestURLQuery(method: HttpMethod,
                              shortURL: String,
                              urlParams: [String: String]?,
                              headerParams: [String: String]?,
                              parseFormat: KRNParseResponseFormat = .none,
                              completion: @escaping ResponseCompletion) {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        if isDebugRequests {
            print("Request URL Query -> \(baseUrl + shortURL)")
            if let headerParams = headerParams {
                print("Headers->\n\(headerParams as NSDictionary)")
            }
            if let urlParams = urlParams {
                print("URL Query params->\n\(urlParams as NSDictionary)")
            }
        }
        
        let urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    open func requestMultiEncoded(method: HttpMethod,
                                  shortURL: String,
                                  urlParams: [String: String]?,
                                  params: JSONConvertible?,
                                  headerParams: [String: String]?,
                                  parseFormat: KRNParseResponseFormat = .none,
                                  completion: @escaping ResponseCompletion) -> Void {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var jsonHeaderParams: [String: String] = headerParams ?? [String: String]()
        jsonHeaderParams["Content-Type"] = "application/json"
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: jsonHeaderParams)
        
        // set params
        if let params = params {
            do {
                let data = try params.toJSONData()
                urlRequest.httpBody = data
            } catch _ as NSError {
                completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.errorJsonEncoding.rawValue))
                return
            }
        }

        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    open func requestFormURLEncoded(method: HttpMethod,
                                    shortURL: String,
                                    urlParams: [String: String]?,
                                    formUrlEncodedParams: [String: String],
                                    headerParams: [String: String]?,
                                    parseFormat: KRNParseResponseFormat = .none,
                                    completion:  @escaping ResponseCompletion) {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        
        let bodyString = formUrlEncodedParams.queryParameters
        urlRequest.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)

        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    // MARK: - Helpers
    
    open func generateUrlRequest(from url: URL,
                                 method: HttpMethod,
                                 headerParams: [String: String]?) -> URLRequest {
        
        var urlRequest = URLRequest(url: url) // 1. set url
        urlRequest.httpMethod = method.rawValue // 2. set method
        
        //3. set header params
        if let headerParams = headerParams {
            for (key, value) in headerParams {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        return urlRequest
    }
    
    open func generateUrl(from urlBody: String,
                          urlParams: [String: String]?) -> URL? {
        
        guard var components = URLComponents(string: urlBody) else {
            return nil
        }
        
        if let urlParams = urlParams {
            let queryItems = urlParams.map({ (arg) -> URLQueryItem in
                let (key, value) = arg
                return URLQueryItem(name: key, value: value)
            })
            components.queryItems = queryItems
        }
        return components.url
    }
    
    // MARK: - Private
    
    private func performDataTask(urlRequest: URLRequest,
                                 parseResponseFormat: KRNParseResponseFormat,
                                 completion: @escaping ResponseCompletion) {
        
        urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let `self` = self else {return}
            if let error = error {
                completion(nil, NetworkError(originalErrorMessage: error.localizedDescription))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(nil,
                           NetworkError(originalErrorMessage: KRNReqErrorString.errorResponseFormat.rawValue,
                                        rawData: data))
                return
            }
            
            if response.statusCode >= 200 && response.statusCode < 300 {
                if let data = data {
                    self.responseParser.parseDataResponse(response: data,
                                                          parseResponseFormat: parseResponseFormat,
                                                          completion: completion)
                } else {
                    completion (nil, nil)
                }
            }
            else {
                completion(data, NetworkError(statusCode: response.statusCode, rawData: data))
            }
            
            }.resume()
    }
}

// MARK: - Multipart data

extension KRNRequestManager {
    open func requestMultiPartData(method: HttpMethod,
                                   shortURL: String,
                                   urlParams: [String: String]? = nil,
                                   headerParams: [String: String]?,
                                   parseFormat: KRNParseResponseFormat = .none,
                                   formDataname: String,
                                   formDataFileName: String,
                                   mimeType: String,
                                   file: Data,
                                   completion: @escaping ResponseCompletion) {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        let boundary = generateBoundaryString()
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = createBody(with: nil,
                                         filePathKey: formDataname,
                                         fileName: formDataFileName,
                                         mimeType: mimeType,
                                         file: file,
                                         boundary: boundary)
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    private func createBody(with parameters: [String: String]?,
                            filePathKey: String,
                            fileName: String,
                            mimeType: String,
                            file: Data,
                            boundary: String) -> Data {
        var body = Data()
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"\(filePathKey)\"; filename=\"\(fileName)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(file)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        return body
    }
    
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary: URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
}
