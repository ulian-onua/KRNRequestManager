import Foundation

enum HttpMethod : String {
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

enum KRNReqErrorString : String {
    case invalidUrl = "Invalid URL"
    case errorJsonEncoding = "Error json encoding"
    case errorResponseFormat = "Response is not HTTP response"
    case errorParsingAsJson = "Error response format. Not JSON."
    case errorParsingAsString = "Error response format. Not String."
}

enum KRNParseResponseFormat  {
    case none // not parse
    case json // parse as json
    case string // parse as string
    case decoder //parse with json decoder
}

protocol RequestManagerDelegate : class {
    func requestStarted(requestManager : KRNRequestManager, url : String)
    func requestFinished(requestManager : KRNRequestManager, url : String)
}

typealias ResponseCompletion = (Any?, NetworkError?) -> Void

class KRNRequestManager {
    let urlSession : URLSession
    fileprivate (set) var baseUrl : String
    
    //MARK: Init
    init(url : String) {
        urlSession = URLSession.init(configuration: URLSessionConfiguration.default)
        self.baseUrl = url
    }
    
    fileprivate func setBaseUrl(_ url : String) {
        self.baseUrl = url
    }
    
    //MARK: Requests
    func requestJSON(method : HttpMethod, shortURL : String, params : [String : Any]?, headerParams : [String : String]?, parseFormat : KRNParseResponseFormat = .none, completion : @escaping ResponseCompletion) -> Void  {
        
        guard let url = URL(string: baseUrl + shortURL) else {
            completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var jsonHeaderParams : [String : String] = headerParams ??  [String : String]()
        jsonHeaderParams["Content-Type"] = "application/json"
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: jsonHeaderParams)
        
        // set params
        if let params = params {
            print("Request JSON params = \(params as NSDictionary)")
            do {
                let data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
                urlRequest.httpBody = data
            } catch _ as NSError {
                completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.errorJsonEncoding.rawValue))
            }
        }
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    func requestMultiEncoded(method : HttpMethod, shortURL : String, urlParams : [String : String]?, params : [String : Any]?, headerParams : [String : String]?, parseFormat : KRNParseResponseFormat = .none, completion : @escaping ResponseCompletion) -> Void {
        guard let url = generateUrl(from:  baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var jsonHeaderParams : [String : String] = headerParams ??  [String : String]()
        jsonHeaderParams["Content-Type"] = "application/json"
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: jsonHeaderParams)
        
        // set params
        if let params = params {
            do {
                let data = try JSONSerialization.data(withJSONObject: params, options: .init(rawValue: 0))
                urlRequest.httpBody = data
            } catch _ as NSError {
                completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.errorJsonEncoding.rawValue))
            }
        }
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
        
    }
    
    func requestURLQuery(method : HttpMethod, shortURL : String, urlParams : [String : String]?, headerParams : [String : String]?, parseFormat : KRNParseResponseFormat = .none, completion :  @escaping ResponseCompletion) {
        
        guard let url = generateUrl(from:  baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        let urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        print(urlRequest)
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    //MARK: Private methods
    fileprivate func generateUrlRequest(from url : URL, method : HttpMethod, headerParams : [String : String]?) -> URLRequest {
        var urlRequest = URLRequest(url: url) // 1. set url
        urlRequest.httpMethod = method.rawValue // 2. set method
        
        //3. set header params
        if let headerParams = headerParams {
            for (key, value) in headerParams {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }
        print(urlRequest.description)
        return urlRequest
    }
    
    fileprivate func performDataTask(urlRequest : URLRequest, parseResponseFormat : KRNParseResponseFormat, completion: @escaping ResponseCompletion) {
        // perform task
        urlSession.dataTask(with: urlRequest) { [weak self] (data, response, error) in
            guard let `self` = self else {return}
            if let error = error {
                completion(nil, NetworkError.init(originalErrorMessage: error.localizedDescription))
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.errorResponseFormat.rawValue, rawData: data))
                return
            }
            
            if response.statusCode >= 200 && response.statusCode < 300 {
                if let data = data {
                    self.parseDataResponse(response: data, parseResponseFormat: parseResponseFormat, completion: completion)
                } else {
                    completion (nil, nil)
                }
            } else {
                completion (data, NetworkError.init(statusCode: response.statusCode, rawData: data))
            }
            
            }.resume()
    }
    
    fileprivate func parseDataResponse(response : Data, parseResponseFormat : KRNParseResponseFormat, completion: @escaping ResponseCompletion) {
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
    
    fileprivate func generateUrl(from urlBody : String, urlParams : [String : String]?) -> URL? {
        guard var components = URLComponents.init(string: urlBody) else {
            return nil
        }
        
        if let urlParams = urlParams {
            let queryItems  =  urlParams.map({ (arg) -> URLQueryItem in
                let (key, value) = arg
                return URLQueryItem.init(name: key, value: value)
            })
            components.queryItems = queryItems
        }
        return components.url
    }
}

//MARK: Raw response parsing
extension KRNRequestManager  {
    func parseAsJson(response : Data) -> Any? {
        do {
            let parsed = try JSONSerialization.jsonObject(with: response, options: .allowFragments)
            return parsed
        } catch _ as NSError {
            return nil //error parsing
        }
    }
    
    func parseAsString(response : Data) -> String? {
        return String.init(data: response, encoding: .utf8)
    }
}

//MARK: Multipart data
extension KRNRequestManager {
    func requestMultiPartData(method : HttpMethod, shortURL : String, urlParams : [String : String]? = nil, headerParams : [String : String]?, parseFormat : KRNParseResponseFormat = .json, formDataname : String, formDataFileName : String, mimeType : String, file : Data, completion :  @escaping ResponseCompletion) {
        guard let url = generateUrl(from:  baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError.init(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return
        }
        
        var urlRequest = generateUrlRequest(from: url, method: method, headerParams: headerParams)
        let boundary = generateBoundaryString()
        
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = createBody(with: nil, filePathKey: formDataname, fileName: formDataFileName, mimeType: mimeType, file: file, boundary: boundary)
        
        performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
    }
    
    private func createBody(with parameters: [String: String]?,
                            filePathKey: String,
                            fileName : String,
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

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
