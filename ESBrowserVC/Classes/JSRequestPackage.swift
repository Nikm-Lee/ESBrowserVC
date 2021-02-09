//
//  JSRequestPackage.swift
//  JSWebBrowser
//
//  Created by esmnc1 on 2020/01/21.
//  Copyright © 2020 jsdong. All rights reserved.
//

import UIKit

public struct JSRequestPackage {

    public var loadURLString: String?
    public var method: String = "GET"
    public var parameter: String?
    public var allHTTPHeaderFields: [String:String]?
    
    public init() {
        
    }
    public init(loadURLString: String? = nil, method: String = "GET", parameter: String? = nil, allHTTPHeaderFields: [String:String]? = nil) {
        self.loadURLString = loadURLString
        self.method = method
        self.parameter = parameter
        self.allHTTPHeaderFields = allHTTPHeaderFields
    }
    
    
    
    public var loadURL: URL? {
        guard let str = loadURLString else {return nil}
        return URL(string: str)
    }
    
    public var loadRequest: URLRequest? {
        guard let url = loadURL else {return nil}
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = httpBody
        request.allHTTPHeaderFields = allHTTPHeaderFields
        
        return request
    }
    
    public var httpBody: Data? {
        guard let param = parameter else {return nil}
        
        return param.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?
            .replacingOccurrences(of: "+", with: "%2B")
            .data(using: .utf8)
    }
    
    
    
}
