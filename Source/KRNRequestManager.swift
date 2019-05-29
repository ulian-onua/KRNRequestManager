//
//  KRNRequestManager.swift
//
//  Created by Julian Drapaylo
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
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
    case errorParsingAsString = "Error response format. Not string."
}

public typealias ResponseCompletion = (Response?, NetworkError?) -> Void

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
    
    @discardableResult open func requestJSON(method: HttpMethod,
                                             shortURL: String,
                                             params: JSONConvertible?,
                                             headerParams: [String: String]?,
                                             parseFormat: ParseResponseFormat = .none,
                                             completion: @escaping ResponseCompletion) -> URLSessionTask? {
       
        guard let url = URL(string: baseUrl + shortURL) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return nil
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
                return nil
            }
        }
        
        return performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
     @discardableResult open func requestURLQuery(method: HttpMethod,
                                                  shortURL: String,
                                                  urlParams: [String: String]?,
                                                  headerParams: [String: String]?,
                                                  parseFormat: ParseResponseFormat = .none,
                                                  completion: @escaping ResponseCompletion) -> URLSessionTask? {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return nil
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
        
        return performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    @discardableResult open func requestMultiEncoded(method: HttpMethod,
                                                     shortURL: String,
                                                     urlParams: [String: String]?,
                                                     params: JSONConvertible?,
                                                     headerParams: [String: String]?,
                                                     parseFormat: ParseResponseFormat = .none,
                                                     completion: @escaping ResponseCompletion) -> URLSessionTask? {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return nil
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
                return nil
            }
        }

        return performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    @discardableResult open func requestFormURLEncoded(method: HttpMethod,
                                                      shortURL: String,
                                                      urlParams: [String: String]?,
                                                      formUrlEncodedParams: [String: String]?,
                                                      headerParams: [String: String]?,
                                                      parseFormat: ParseResponseFormat = .none,
                                                      completion: @escaping ResponseCompletion) -> URLSessionTask? {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return nil
        }
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        
        if let formUrlEncodedParams = formUrlEncodedParams {
            let bodyString = formUrlEncodedParams.queryParameters
            urlRequest.httpBody = bodyString.data(using: .utf8, allowLossyConversion: true)
        }

        return performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    @discardableResult open func request(encodingType: EncodingType,
                                         method: HttpMethod,
                                         shortURL: String,
                                         headerParams: [String: String]? = nil,
                                         urlParams: [String: String]? = nil,
                                         jsonParams: JSONConvertible? = nil,
                                         formUrlEncodedParams: [String: String]? = nil,
                                         parseFormat: ParseResponseFormat = .none,
                                         completion: @escaping ResponseCompletion) -> URLSessionTask? {
        
        switch encodingType {
        case .url:
            return requestURLQuery(method: method,
                                   shortURL: shortURL,
                                   urlParams: urlParams,
                                   headerParams: headerParams,
                                   parseFormat: parseFormat,
                                   completion: completion)
        case .json:
            return requestJSON(method: method,
                               shortURL: shortURL,
                               params: jsonParams,
                               headerParams: headerParams,
                               parseFormat: parseFormat,
                               completion: completion)
        case .urlJsonMultiEncoded:
            return requestMultiEncoded(method: method,
                                       shortURL: shortURL,
                                       urlParams: urlParams,
                                       params: jsonParams,
                                       headerParams: headerParams,
                                       parseFormat: parseFormat,
                                       completion: completion)
        case .formUrl:
            return requestFormURLEncoded(method: method,
                                         shortURL: shortURL,
                                         urlParams: urlParams,
                                         formUrlEncodedParams: formUrlEncodedParams,
                                         headerParams: headerParams,
                                         parseFormat: parseFormat,
                                         completion: completion)
        }
        
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
    
    @discardableResult func performDataTask(urlRequest: URLRequest,
                                            parseResponseFormat: ParseResponseFormat,
                                            completion: @escaping ResponseCompletion) -> URLSessionTask {
        
        let task =
            urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let `self` = self else {return}
            if let error = error {
                if (error as NSError).domain == NSURLErrorDomain &&
                    (error as NSError).code == NSURLErrorCancelled {
                    completion(nil, NetworkError.cancelledTask())
                    return
                }
                
                completion(nil, NetworkError(originalErrorMessage: error.localizedDescription))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(nil,
                           NetworkError(originalErrorMessage: KRNReqErrorString.errorResponseFormat.rawValue,
                                        rawData: data))
                return
            }
            let statusCode = response.statusCode
            if statusCode >= 200 && statusCode < 300 {
                if let data = data {
                    self.responseParser.parseDataResponse(response: data,
                                                          statusCode: statusCode,
                                                          parseResponseFormat: parseResponseFormat,
                                                          completion: completion)
                } else {
                    completion (nil, nil)
                }
            }
            else {
                completion(nil, NetworkError(statusCode: statusCode, rawData: data))
            }
            
            }
        task.resume()
        return task
    }
}
