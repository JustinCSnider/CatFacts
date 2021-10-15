//
//  NetworkController.swift
//  Portal Manager
//
//  Created by Justin Snider on 1/7/21.
//  Copyright © 2021 portals. All rights reserved.
//
import Foundation

typealias NetworkError = NetworkController.NetworkError

struct NetworkController {
    
    // MARK: - Enums
    
    enum NetworkError: Error {
        case invalidURL
        case dataUnavailable
    }
    
    // MARK: - Static Functions
    
    static func performNetworkRequest(for url: URL, httpMethod: String, contentType: String? = nil, completion: ((Data?, Error?) -> Void)? = nil) {
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        
        if let contentType = contentType {
            request.addValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        
         let dataTask = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let completion = completion {
                
                completion(data, error)
            }
        }
        dataTask.resume()
    }
}
