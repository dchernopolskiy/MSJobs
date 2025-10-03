//
//  AMDFetcher.swift
//  MSJobMonitor
//
//  Created by Dan Chernopolskii on 10/3/25.
//

import Foundation

actor AMDFetcher: JobFetcherProtocol {
    private let baseURL = "https://careers.amd.com/api/jobs"
    
    func fetchJobs(titleKeywords: [String], location: String, maxPages: Int) async throws -> [Job] {
        
        var allJobs: [Job] = []
        let pageSize = 20
        
        let locationQuery = parseLocationForAMD(location)
        
        for page in 1...maxPages {
            let pageJobs = try await fetchJobsPage(
                page: page,
                keywords: titleKeywords.joined(separator: " "),
                location: locationQuery
            )
            
            if pageJobs.isEmpty {
                break
            }
            
            allJobs.append(contentsOf: pageJobs)
            
            
            if pageJobs.count < pageSize {
                break
            }
            
            try await Task.sleep(nanoseconds: 500_000_000)
        }
        
        return allJobs
    }
    
    func fetchJobs(from url: URL, titleFilter: String = "", locationFilter: String = "") async throws -> [Job] {
        let titleKeywords = parseFilterString(titleFilter)
        return try await fetchJobs(
            titleKeywords: titleKeywords,
            location: locationFilter,
            maxPages: 5
        )
    }
    
    // MARK: - Private Methods
    
    private func fetchJobsPage(page: Int, keywords: String, location: String?) async throws -> [Job] {
        var components = URLComponents(string: baseURL)!
        
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sortBy", value: "posted_date"),
            URLQueryItem(name: "descending", value: "true"),
            URLQueryItem(name: "internal", value: "false")
        ]
        
        if !keywords.isEmpty {
            queryItems.append(URLQueryItem(name: "keywords", value: keywords))
        }
        
        if let location = location, !location.isEmpty {
            queryItems.append(URLQueryItem(name: "location", value: location))
            queryItems.append(URLQueryItem(name: "woe", value: "7"))
            queryItems.append(URLQueryItem(name: "stretchUnit", value: "MILES"))
            queryItems.append(URLQueryItem(name: "stretch", value: "50"))
            
            if let regionCode = extractRegionCode(from: location) {
                queryItems.append(URLQueryItem(name: "regionCode", value: regionCode))
            }
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw FetchError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        
        if page == 1 {
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
            }
            throw FetchError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let amdResponse = try decoder.decode(AMDResponse.self, from: data)
        
        let jobs = amdResponse.jobs.compactMap { convertAMDJob($0) }
        
        return jobs
    }
    
    private func convertAMDJob(_ amdJob: AMDJobWrapper) -> Job? {
        let jobData = amdJob.data
        let location = buildLocationString(from: jobData)
        let postingDate = parseAMDDate(jobData.posted_date)
        let jobURL = "https://careers.amd.com/careers-home/jobs/\(jobData.req_id)?lang=en-us"
        
        var fullDescription = jobData.description
        if let responsibilities = jobData.responsibilities, !responsibilities.isEmpty {
            fullDescription += "\n\n" + responsibilities
        }
        
        return Job(
            id: "amd-\(jobData.req_id)",
            title: jobData.title,
            location: location,
            postingDate: postingDate,
            url: jobURL,
            description: fullDescription,
            workSiteFlexibility: extractWorkFlexibility(from: fullDescription),
            source: .amd,
            companyName: "AMD",
            department: jobData.category?.first,
            category: nil,
            firstSeenDate: Date()
        )
    }
    
    private func buildLocationString(from jobData: AMDJobData) -> String {
        var parts: [String] = []
        
        if let city = jobData.city, !city.isEmpty {
            parts.append(city)
        }
        
        if let state = jobData.state, !state.isEmpty {
            parts.append(state)
        }
        
        if parts.isEmpty {
            if let locationName = jobData.location_name, !locationName.isEmpty {
                let locationParts = locationName.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                if locationParts.count >= 3 {
                    return "\(locationParts[2]), \(locationParts[1])"
                } else if locationParts.count == 2 {
                    return locationParts.joined(separator: ", ")
                }
                return locationName
            }
            return "Location not specified"
        }
        
        return parts.joined(separator: ", ")
    }
    
    private func parseAMDDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
    
    private func extractWorkFlexibility(from description: String) -> String? {
        let keywords = ["remote", "hybrid", "flexible", "onsite", "on-site"]
        let lower = description.lowercased()
        
        for keyword in keywords {
            if lower.contains(keyword) {
                return keyword.capitalized
            }
        }
        
        return nil
    }
    
    private func parseLocationForAMD(_ locationString: String) -> String? {
        guard !locationString.isEmpty else { return nil }
        
        let locations = locationString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return locations.first
    }
    
    private func extractRegionCode(from location: String) -> String? {
        let locationLower = location.lowercased()
        
        if locationLower.contains("usa") || locationLower.contains("united states") ||
           locationLower.contains("seattle") || locationLower.contains("bellevue") ||
           locationLower.contains("california") || locationLower.contains("texas") {
            return "US"
        } else if locationLower.contains("canada") || locationLower.contains("toronto") {
            return "CA"
        } else if locationLower.contains("uk") || locationLower.contains("united kingdom") ||
                  locationLower.contains("london") {
            return "GB"
        }
        
        return nil
    }
    
    private func parseFilterString(_ filterString: String) -> [String] {
        guard !filterString.isEmpty else { return [] }

        return filterString
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - AMD API Models

struct AMDResponse: Codable {
    let jobs: [AMDJobWrapper]
}

struct AMDJobWrapper: Codable {
    let data: AMDJobData
}

struct AMDJobData: Codable {
    let slug: String
    let language: String
    let req_id: String
    let title: String
    let description: String
    let location_name: String?
    let street_address: String?
    let city: String?
    let state: String?
    let country: String?
    let country_code: String?
    let postal_code: String?
    let location_type: String?
    let latitude: Double?
    let longitude: Double?
    let category: [String]?
    let employment_type: String?
    let qualifications: String?
    let responsibilities: String?
    let posted_date: String?
    let apply_url: String?
}
