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
    
    
    public init() {
        
    }
    public init(loadURLString: String? = nil, method: String = "GET", parameter: String? = nil) {
        self.loadURLString = loadURLString
        self.method = method
        self.parameter = parameter
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
        
        return request
    }
    
    public var httpBody: Data? {
        guard let param = parameter?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {return nil}
        
        return param.data(using: .utf8)
    }
    
    
    
}
