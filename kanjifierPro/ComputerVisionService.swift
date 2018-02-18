//
//  ComputerVisionService.swift
//  kanjifierPro
//
//  Created by Kent Vainio on 2/17/18.
//  Copyright © 2018 Kent Vainio. All rights reserved.
//

import Foundation

class ComputerVisionService {
    var visionUrl = "https://westcentralus.api.cognitive.microsoft.com/vision/v1.0/tag"
    var visionKey1 = "2c0b1e0c169f4420b9fab4a352947197"
    var visionKey2 = "0968753c7fc24cd8bae4df1c34a03f52"
    var contentType = "application/octet-stream"
    
    var defaultSession = URLSession(configuration: .default)
    var dataTask: URLSessionDataTask?
    
    func predict(image: Data, completion: @escaping ([[String: Any]]?, Error?) -> Void) {
        
        // Create URL Request
        var urlRequest = URLRequest(url: URL(string: visionUrl)!)
        urlRequest.addValue(visionKey1, forHTTPHeaderField: "Ocp-Apim-Subscription-Key")
        urlRequest.addValue(contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "POST"
        
        // Cancel existing dataTask if active
        dataTask?.cancel()
        
        // Create new dataTask to upload image
        dataTask = defaultSession.uploadTask(with: urlRequest, from: image) { data, response, error in
            defer { self.dataTask = nil }
            
            if let error = error {
                completion(nil, error)
            } else if let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200 {
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let result = json!["tags"] as? [[String: Any]]
                    completion(result, nil)
                }
            }
        }
        
        // Start the new dataTask
        dataTask?.resume()
    }
}
