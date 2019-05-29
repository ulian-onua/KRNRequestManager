//
//  KRNRequestManagerTests.swift
//  KRNRequestManagerTests
//
//  Created by kornet on 5/29/19.
//  Copyright © 2019 Julian Drapaylo. All rights reserved.
//

import XCTest

class KRNRequestManagerTests: XCTestCase {
    
    let baseURL = "https://jsonplaceholder.typicode.com/"
    var requestManager: KRNRequestManager!
    let timeout = 30.0
    
    // MARK: - Lifecycle
    
    override func setUp() {
        requestManager = KRNRequestManager(url: baseURL)
    }
    
    override func tearDown() {
        
    }
    
    // MARK: - Tests
    
    // TODO: - Separate to different classes. Prepare test for diferrent categories.
    
    func testGetRequest() {
        let expectation = XCTestExpectation(description: "Get request expectation")
        
        requestManager.requestURLQuery(method: .get,
                                       shortURL: "posts",
                                       urlParams: nil,
                                       headerParams: nil) { (response, error) in
                                        if response != nil {
                                            XCTAssert(true)
                                        } else {
                                            XCTFail()
                                        }
                                        expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
        
    }
    
    func testRequestCancellation() {
        let expectation = XCTestExpectation(description: "Test request cancellation expectation")
        
        let req = requestManager.request(encodingType: .json,
                                         method: .get,
                                         shortURL: "comments") { (response, error) in
                                            if let error = error, error.cancelledTaskError {
                                                XCTAssert(true)
                                            } else {
                                                XCTFail()
                                            }
                                            expectation.fulfill()
        }
        req!.cancel()
        wait(for: [expectation], timeout: 30.0)
    }
    
    func testSuccessStatusCode() {
        
        let expectation = XCTestExpectation(description: "Test success status code expectation")
        
        requestManager.requestURLQuery(method: .get,
                                       shortURL: "posts",
                                       urlParams: nil,
                                       headerParams: nil) { (response, error) in
                                        if let response = response,
                                            200 ... 299 ~= response.statusCode {
                                            XCTAssert(true)
                                        } else {
                                            XCTFail()
                                        }
                                        expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 30.0)
    }
    
}
