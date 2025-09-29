//
//  JobBoardConfig.swift
//  MSJobMonitor
//
//  Created by Dan Chernopolskii on 9/28/25.
//


import Foundation

struct JobBoardConfig: Identifiable, Codable {
    var id = UUID()
    var name: String
    var url: String
    var source: JobSource
    var isEnabled: Bool = true
    var lastFetched: Date?
    
    var displayName: String {
        if name.isEmpty {
            return "\(source.rawValue) Board"
        }
        return name
    }
    
    var isSupported: Bool {
        return source.isSupported
    }
    
    init?(name: String, url: String, isEnabled: Bool = true) {
        guard let detectedSource = JobSource.detectFromURL(url) else {
            return nil 
        }
        
        self.name = name
        self.url = url
        self.source = detectedSource
        self.isEnabled = isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        source = try container.decode(JobSource.self, forKey: .source)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        lastFetched = try container.decodeIfPresent(Date.self, forKey: .lastFetched)
    }
}
