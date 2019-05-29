//
//  KRNRequestManager+MultipartData.swift
//
//  Created by Julian Drapaylo on 4/21/19.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import Foundation

extension KRNRequestManager {
    @discardableResult open func requestMultiPartData(method: HttpMethod,
                                                      shortURL: String,
                                                      urlParams: [String: String]? = nil,
                                                      headerParams: [String: String]?,
                                                      parseFormat: ParseResponseFormat = .none,
                                                      formDataname: String,
                                                      formDataFileName: String,
                                                      mimeType: String,
                                                      file: Data,
                                                      completion: @escaping ResponseCompletion) -> URLSessionTask? {
        
        guard let url = generateUrl(from: baseUrl + shortURL, urlParams: urlParams) else {
            completion(nil, NetworkError(originalErrorMessage: KRNReqErrorString.invalidUrl.rawValue))
            return nil
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
        
        return performDataTask(urlRequest: urlRequest, parseResponseFormat: parseFormat, completion: completion)
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
