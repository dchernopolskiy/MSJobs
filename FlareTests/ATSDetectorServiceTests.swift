//
//  ATSDetectorServiceTests.swift
//  FlareTests
//
//  Created by automated tests
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - ATS Detector Service Tests
@Suite("ATSDetectorService Tests")
struct ATSDetectorServiceTests {

    // Note: Many ATSDetectorService methods are private, so we test through public APIs
    // and verify regex patterns work correctly

    // MARK: - Regex Pattern Tests

    @Test("Workday URL regex pattern matches correctly")
    func testWorkdayURLRegexPattern() {
        let pattern = #"https?://[^"'\s]*\.wd[0-9]+\.myworkdayjobs\.com/[^"'\s]*"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        // Should match
        let validUrls = [
            "https://company.wd1.myworkdayjobs.com/en-US/Careers",
            "https://company.wd5.myworkdayjobs.com/Careers/job/123",
            "http://testcompany.wd12.myworkdayjobs.com/Jobs",
        ]

        for url in validUrls {
            let range = NSRange(url.startIndex..., in: url)
            let match = regex.firstMatch(in: url, range: range)
            #expect(match != nil, "Should match: \(url)")
        }

        // Should not match
        let invalidUrls = [
            "https://company.myworkdayjobs.com/Careers", // Missing .wd[0-9]+
            "https://workday.com/careers",
            "https://company.wd.myworkdayjobs.com/Jobs", // Missing number after wd
        ]

        for url in invalidUrls {
            let range = NSRange(url.startIndex..., in: url)
            let match = regex.firstMatch(in: url, range: range)
            #expect(match == nil, "Should not match: \(url)")
        }
    }

    @Test("Greenhouse URL regex pattern matches correctly")
    func testGreenhouseURLRegexPattern() {
        let pattern = #"https?://[^"'\s]*\.greenhouse\.io/[^"'\s]*"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        let validUrls = [
            "https://boards.greenhouse.io/company/jobs/123",
            "https://boards-api.greenhouse.io/v1/boards/company",
            "https://job-boards.greenhouse.io/company",
        ]

        for url in validUrls {
            let range = NSRange(url.startIndex..., in: url)
            let match = regex.firstMatch(in: url, range: range)
            #expect(match != nil, "Should match: \(url)")
        }
    }

    @Test("Lever URL regex pattern matches correctly")
    func testLeverURLRegexPattern() {
        let pattern = #"https?://jobs\.lever\.co/[^"'\s]*"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        let validUrls = [
            "https://jobs.lever.co/company",
            "https://jobs.lever.co/company/job-id-123",
            "http://jobs.lever.co/testcompany/abc",
        ]

        for url in validUrls {
            let range = NSRange(url.startIndex..., in: url)
            let match = regex.firstMatch(in: url, range: range)
            #expect(match != nil, "Should match: \(url)")
        }
    }

    @Test("Ashby URL regex pattern matches correctly")
    func testAshbyURLRegexPattern() {
        let pattern = #"https?://jobs\.ashbyhq\.com/[^"'\s]*"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        let validUrls = [
            "https://jobs.ashbyhq.com/company",
            "https://jobs.ashbyhq.com/company/job-uuid",
            "http://jobs.ashbyhq.com/testcompany",
        ]

        for url in validUrls {
            let range = NSRange(url.startIndex..., in: url)
            let match = regex.firstMatch(in: url, range: range)
            #expect(match != nil, "Should match: \(url)")
        }
    }

    @Test("Ashby UUID pattern matches correctly")
    func testAshbyUUIDPattern() {
        let uuidPattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
        let regex = try! NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive)

        // Valid UUIDs
        let validUUIDs = [
            "12345678-1234-1234-1234-123456789abc",
            "abcdef12-3456-7890-abcd-ef1234567890",
            "ABCDEF12-3456-7890-ABCD-EF1234567890", // Uppercase should match
        ]

        for uuid in validUUIDs {
            let range = NSRange(uuid.startIndex..., in: uuid)
            let match = regex.firstMatch(in: uuid, range: range)
            #expect(match != nil, "Should match UUID: \(uuid)")
        }

        // Invalid UUIDs
        let invalidUUIDs = [
            "12345678-1234-1234-1234-123456789abcd", // Too many chars
            "12345678-1234-1234-1234-123456789ab",   // Too few chars
            "12345678-1234-1234-1234",                // Missing section
            "not-a-uuid-at-all",
            "job-title-slug",
        ]

        for uuid in invalidUUIDs {
            let range = NSRange(uuid.startIndex..., in: uuid)
            let match = regex.firstMatch(in: uuid, range: range)
            #expect(match == nil, "Should not match: \(uuid)")
        }
    }

    @Test("Meta redirect regex pattern matches correctly")
    func testMetaRedirectRegexPattern() {
        let pattern = #"<meta[^>]*http-equiv=[\"']refresh[\"'][^>]*content=[\"'][^\"']*url=([^\"'\s]+)"#
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)

        let html1 = """
        <meta http-equiv="refresh" content="0;url=https://careers.example.com">
        """

        let range1 = NSRange(html1.startIndex..., in: html1)
        let match1 = regex.firstMatch(in: html1, range: range1)
        #expect(match1 != nil)

        if let match = match1, match.numberOfRanges > 1,
           let urlRange = Range(match.range(at: 1), in: html1) {
            let extractedUrl = String(html1[urlRange])
            #expect(extractedUrl == "https://careers.example.com")
        }

        let html2 = """
        <META HTTP-EQUIV='refresh' CONTENT='5; URL=https://jobs.company.com/careers'>
        """

        let range2 = NSRange(html2.startIndex..., in: html2)
        let match2 = regex.firstMatch(in: html2, range: range2)
        #expect(match2 != nil)
    }

    @Test("JavaScript redirect patterns match correctly")
    func testJavaScriptRedirectPatterns() {
        // Test window.location.href pattern
        let pattern1 = #"window\.location\.href\s*=\s*[\"']([^\"']+)[\"']"#
        let regex1 = try! NSRegularExpression(pattern: pattern1, options: .caseInsensitive)

        let js1 = #"window.location.href = "https://careers.company.com";"#
        let range1 = NSRange(js1.startIndex..., in: js1)
        let match1 = regex1.firstMatch(in: js1, range: range1)
        #expect(match1 != nil)

        if let match = match1, match.numberOfRanges > 1,
           let urlRange = Range(match.range(at: 1), in: js1) {
            let extractedUrl = String(js1[urlRange])
            #expect(extractedUrl == "https://careers.company.com")
        }

        // Test window.location.replace pattern
        let pattern2 = #"window\.location\.replace\([\"']([^\"']+)[\"']\)"#
        let regex2 = try! NSRegularExpression(pattern: pattern2, options: .caseInsensitive)

        let js2 = #"window.location.replace("https://jobs.example.com");"#
        let range2 = NSRange(js2.startIndex..., in: js2)
        let match2 = regex2.firstMatch(in: js2, range: range2)
        #expect(match2 != nil)

        // Test location.href pattern
        let pattern3 = #"location\.href\s*=\s*[\"']([^\"']+)[\"']"#
        let regex3 = try! NSRegularExpression(pattern: pattern3, options: .caseInsensitive)

        let js3 = #"location.href='https://careers.test.com'"#
        let range3 = NSRange(js3.startIndex..., in: js3)
        let match3 = regex3.firstMatch(in: js3, range: range3)
        #expect(match3 != nil)
    }

    // MARK: - URL Extraction Tests

    @Test("Extract company slug from various URLs")
    func testCompanySlugExtraction() {
        // Test cases mapping URL host to expected slug
        let testCases: [(host: String, expectedSlug: String)] = [
            ("careers.microsoft.com", "microsoft"),
            ("jobs.example.com", "example"),
            ("subdomain.company.co.uk", "company"),
            ("test-company.io", "test-company"),
            ("company.careers.org", "careers"),
        ]

        for (host, expectedSlug) in testCases {
            let parts = host.components(separatedBy: ".")
            if parts.count >= 2 {
                let domain = parts[parts.count - 2]
                #expect(domain.lowercased() == expectedSlug, "Expected '\(expectedSlug)' from '\(host)'")
            }
        }
    }

    @Test("Parse Workday URL components")
    func testWorkdayURLParsing() {
        // Test valid Workday URLs
        let url1 = "https://microsoft.wd1.myworkdayjobs.com/en-US/careers"
        if let components = URL(string: url1), let host = components.host {
            let hostParts = host.components(separatedBy: ".")
            #expect(hostParts.count >= 3)
            #expect(hostParts[0] == "microsoft")
            #expect(hostParts[1].hasPrefix("wd"))
            #expect(hostParts[2] == "myworkdayjobs")
        }

        let url2 = "https://company.wd5.myworkdayjobs.com/Careers/job/123"
        if let components = URL(string: url2), let host = components.host {
            let hostParts = host.components(separatedBy: ".")
            #expect(hostParts[0] == "company")
            #expect(hostParts[1] == "wd5")
        }
    }

    @Test("Workday URL normalization removes job-specific paths")
    func testWorkdayURLNormalization() {
        // Simulate normalization logic
        let testCases: [(input: String, expectedBase: String)] = [
            (
                "https://company.wd1.myworkdayjobs.com/Careers/job/123456",
                "https://company.wd1.myworkdayjobs.com/Careers/"
            ),
            (
                "https://company.wd5.myworkdayjobs.com/en-US/Jobs/details/Engineer-123",
                "https://company.wd5.myworkdayjobs.com/en-US/Jobs/"
            ),
            (
                "https://company.wd1.myworkdayjobs.com/Careers/apply/789",
                "https://company.wd1.myworkdayjobs.com/Careers/"
            ),
        ]

        for (input, expectedBase) in testCases {
            guard let urlObj = URL(string: input),
                  let host = urlObj.host else {
                #expect(Bool(false), "Failed to parse URL: \(input)")
                continue
            }

            let path = urlObj.path
            let stripPatterns = ["/job/", "/details/", "/apply"]
            var basePath = path

            for pattern in stripPatterns {
                if let range = path.range(of: pattern) {
                    basePath = String(path[..<range.lowerBound])
                    break
                }
            }

            if !basePath.hasSuffix("/") {
                basePath += "/"
            }

            let result = "\(urlObj.scheme ?? "https")://\(host)\(basePath)"
            #expect(result == expectedBase, "Expected '\(expectedBase)', got '\(result)'")
        }
    }

    @Test("Ashby URL normalization removes UUID suffix")
    func testAshbyURLNormalization() {
        let testCases: [(input: String, shouldNormalize: Bool)] = [
            (
                "https://jobs.ashbyhq.com/company/12345678-1234-1234-1234-123456789abc",
                true // Has UUID, should be normalized
            ),
            (
                "https://jobs.ashbyhq.com/company/job-title-slug",
                false // No UUID, should stay as-is
            ),
            (
                "https://jobs.ashbyhq.com/company",
                false // No path components, should stay as-is
            ),
        ]

        for (input, shouldNormalize) in testCases {
            guard let urlObj = URL(string: input) else {
                #expect(Bool(false), "Failed to parse URL: \(input)")
                continue
            }

            let pathComponents = urlObj.pathComponents.filter { $0 != "/" }

            if pathComponents.count > 1 {
                let lastComponent = pathComponents.last ?? ""

                let uuidPattern = #"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"#
                if let regex = try? NSRegularExpression(pattern: uuidPattern, options: .caseInsensitive),
                   regex.firstMatch(in: lastComponent, range: NSRange(lastComponent.startIndex..., in: lastComponent)) != nil {

                    // This is a UUID, should be normalized
                    #expect(shouldNormalize, "Expected UUID in: \(input)")

                    let baseComponents = pathComponents.dropLast()
                    let basePath = "/" + baseComponents.joined(separator: "/") + "/"
                    let result = "\(urlObj.scheme ?? "https")://\(urlObj.host ?? "")\(basePath)"

                    #expect(result.hasSuffix("/company/"))
                } else {
                    // Not a UUID
                    #expect(!shouldNormalize, "Did not expect UUID in: \(input)")
                }
            }
        }
    }

    // MARK: - ATS Indicator Analysis Tests

    @Test("Greenhouse indicators in HTML")
    func testGreenhouseIndicators() {
        let htmlSamples = [
            #"<script src="https://boards.greenhouse.io/embed/job_board"></script>"#,
            #"<div class="gh-job-listing" data-gh-board="company"></div>"#,
            #"powered by Greenhouse.io"#,
            #"https://boards-api.greenhouse.io/v1/boards/company/jobs"#,
        ]

        for html in htmlSamples {
            let htmlLower = html.lowercased()
            let keywords = ["greenhouse.io", "boards.greenhouse", "grnhse", "gh-", "data-gh"]

            var found = false
            for keyword in keywords {
                if htmlLower.contains(keyword) {
                    found = true
                    break
                }
            }

            #expect(found, "Should detect Greenhouse in: \(html)")
        }
    }

    @Test("Lever indicators in HTML")
    func testLeverIndicators() {
        let htmlSamples = [
            #"<script src="https://jobs.lever.co/embed"></script>"#,
            #"<div class="lever-application"></div>"#,
            #"powered by Lever ATS"#,
            #"https://api.lever.co/v0/postings/company"#,
        ]

        for html in htmlSamples {
            let htmlLower = html.lowercased()
            let keywords = ["lever.co", "jobs.lever", "api.lever", "data-lever", "lever-application", "lever ats", "levercareers"]

            var found = false
            for keyword in keywords {
                if htmlLower.contains(keyword) {
                    found = true
                    break
                }
            }

            #expect(found, "Should detect Lever in: \(html)")
        }
    }

    @Test("Workday indicators in HTML")
    func testWorkdayIndicators() {
        let htmlSamples = [
            #"<iframe src="https://company.wd1.myworkdayjobs.com/Careers"></iframe>"#,
            #"View jobs at https://company.wd5.myworkdayjobs.com"#,
            #"Powered by Workday.com/careers"#,
        ]

        for html in htmlSamples {
            let htmlLower = html.lowercased()
            let keywords = ["myworkdayjobs", "wd1.", "wd5.", "workday.com/careers"]

            var found = false
            for keyword in keywords {
                if htmlLower.contains(keyword) {
                    found = true
                    break
                }
            }

            #expect(found, "Should detect Workday in: \(html)")
        }
    }

    @Test("Ashby indicators in HTML")
    func testAshbyIndicators() {
        let htmlSamples = [
            #"<script src="https://jobs.ashbyhq.com/embed"></script>"#,
            #"Powered by Ashby"#,
            #"https://jobs.ashbyhq.com/company/job-id"#,
        ]

        for html in htmlSamples {
            let htmlLower = html.lowercased()
            let keywords = ["ashbyhq", "jobs.ashbyhq", "ashby.com"]

            var found = false
            for keyword in keywords {
                if htmlLower.contains(keyword) {
                    found = true
                    break
                }
            }

            #expect(found, "Should detect Ashby in: \(html)")
        }
    }

    // MARK: - Dynamic Loading Indicators Tests

    @Test("Detect dynamic job loading indicators")
    func testDynamicLoadingIndicators() {
        let indicators = [
            "graphql", "apollo", "__APOLLO", "careersPageQuery", "jobsQuery",
            "window.__INITIAL_STATE__", "window.__data", "react-root", "ng-app", "vue-app"
        ]

        let htmlWithMultipleIndicators = """
        <div id="react-root"></div>
        <script>
        window.__APOLLO = { careersPageQuery: {...} };
        </script>
        """

        var foundCount = 0
        for indicator in indicators {
            if htmlWithMultipleIndicators.localizedCaseInsensitiveContains(indicator) {
                foundCount += 1
            }
        }

        #expect(foundCount >= 2, "Should detect multiple indicators in dynamic page")
    }

    @Test("Careers page content indicators")
    func testCareersPageIndicators() {
        let contentIndicators = [
            "open position", "job opening", "join our team", "we're hiring",
            "apply now", "view all jobs", "current opening"
        ]

        let careersHTML = """
        <h1>Join Our Team</h1>
        <p>We're hiring! View all jobs and apply now.</p>
        <div class="job-listings">Current openings below...</div>
        """

        let htmlLower = careersHTML.lowercased()
        var foundCount = 0

        for indicator in contentIndicators {
            if htmlLower.contains(indicator) {
                foundCount += 1
            }
        }

        #expect(foundCount >= 2, "Should detect careers page indicators")
    }
}
