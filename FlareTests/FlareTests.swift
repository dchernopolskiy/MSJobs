//
//  FlareTests.swift
//  FlareTests
//
//  Created by Dan Chernopolskii on 8/18/25.
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - HTMLCleaner Tests
struct HTMLCleanerTests {

    @Test func testBasicHTMLCleaning() {
        let html = "<p>This is a test</p>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("This is a test"))
        #expect(!result.contains("<p>"))
    }

    @Test func testHTMLWithBreaks() {
        let html = "Line 1<br>Line 2<br/>Line 3<br />Line 4"
        let result = HTMLCleaner.cleanHTML(html)
        let lines = result.components(separatedBy: .newlines).filter { !$0.isEmpty }
        #expect(lines.count == 4)
        #expect(lines[0] == "Line 1")
        #expect(lines[1] == "Line 2")
    }

    @Test func testHTMLWithParagraphs() {
        let html = "<p>Paragraph 1</p><p>Paragraph 2</p>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("Paragraph 1"))
        #expect(result.contains("Paragraph 2"))
        #expect(!result.contains("<p>"))
    }

    @Test func testHTMLWithLists() {
        let html = "<ul><li>Item 1</li><li>Item 2</li></ul>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("• Item 1"))
        #expect(result.contains("• Item 2"))
        #expect(!result.contains("<ul>"))
        #expect(!result.contains("<li>"))
    }

    @Test func testHTMLWithDivs() {
        let html = "<div>Content 1</div><div>Content 2</div>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("Content 1"))
        #expect(result.contains("Content 2"))
        #expect(!result.contains("<div>"))
    }

    @Test func testHTMLEntityDecoding() {
        let html = "&amp; &lt; &gt; &quot; &#39; &nbsp;"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("&"))
        #expect(result.contains("<"))
        #expect(result.contains(">"))
        #expect(result.contains("\""))
        #expect(result.contains("'"))
    }

    @Test func testComplexNestedHTML() {
        let html = """
        <div>
            <p>Job Description</p>
            <ul>
                <li>Requirement 1</li>
                <li>Requirement 2</li>
            </ul>
            <p>Additional info</p>
        </div>
        """
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("Job Description"))
        #expect(result.contains("• Requirement 1"))
        #expect(result.contains("• Requirement 2"))
        #expect(result.contains("Additional info"))
        #expect(!result.contains("<"))
        #expect(!result.contains(">"))
    }

    @Test func testEmptyHTMLString() {
        let html = ""
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.isEmpty)
    }

    @Test func testHTMLWithOnlyTags() {
        let html = "<div></div><p></p>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.isEmpty || result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test func testHTMLWithMultipleConsecutiveSpaces() {
        let html = "<p>Too    many     spaces</p>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("Too"))
        #expect(result.contains("many"))
        #expect(result.contains("spaces"))
    }

    @Test func testHTMLWithSpecialCharacters() {
        let html = "<p>C++ &amp; C# developer needed</p>"
        let result = HTMLCleaner.cleanHTML(html)
        #expect(result.contains("C++"))
        #expect(result.contains("&"))
        #expect(result.contains("C#"))
    }
}

// MARK: - QualificationExtractor Tests
struct QualificationExtractorTests {

    @Test func testExtractRequiredQualifications() {
        let text = """
        Job Description here.

        Required Qualifications
        • Bachelor's degree in Computer Science
        • 5+ years of experience

        Preferred Qualifications
        • Master's degree
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("Bachelor's degree"))
        #expect(required!.contains("5+ years"))
        #expect(!required!.contains("Preferred Qualifications"))
    }

    @Test func testExtractPreferredQualifications() {
        let text = """
        Job Description here.

        Required Qualifications
        • Bachelor's degree

        Preferred Qualifications
        • Master's degree
        • PhD preferred

        Equal opportunity employer statement
        """

        let preferred = QualificationExtractor.extractPreferred(from: text)
        #expect(preferred != nil)
        #expect(preferred!.contains("Master's degree"))
        #expect(preferred!.contains("PhD preferred"))
        #expect(!preferred!.contains("Equal opportunity employer"))
    }

    @Test func testExtractMinimumQualifications() {
        let text = """
        Overview

        Minimum Qualifications
        • BS/BA degree
        • Strong coding skills

        Additional info
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("BS/BA degree"))
        #expect(required!.contains("Strong coding skills"))
    }

    @Test func testExtractBasicQualifications() {
        let text = """
        Job info

        Basic Qualifications
        • 3+ years experience
        • Python knowledge
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("3+ years"))
        #expect(required!.contains("Python"))
    }

    @Test func testNoQualificationsFound() {
        let text = "This is just a job description with no qualifications section."

        let required = QualificationExtractor.extractRequired(from: text)
        let preferred = QualificationExtractor.extractPreferred(from: text)

        #expect(required == nil)
        #expect(preferred == nil)
    }

    @Test func testCaseInsensitiveMarkerDetection() {
        let text = """
        Job info

        REQUIRED QUALIFICATIONS
        • Experience needed
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("Experience needed"))
    }

    @Test func testQualificationsAtEndOfText() {
        let text = """
        Job description

        Required Qualifications
        • Final requirement
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("Final requirement"))
    }

    @Test func testMultipleQualificationMarkers() {
        let text = """
        Overview

        Required/Minimum Qualifications
        • Must have degree
        • Must have experience
        """

        let required = QualificationExtractor.extractRequired(from: text)
        #expect(required != nil)
        #expect(required!.contains("Must have degree"))
    }
}

// MARK: - JobSource Tests
struct JobSourceTests {

    @Test func testDetectMicrosoft() {
        #expect(JobSource.detectFromURL("https://careers.microsoft.com/us/en/job/12345") == .microsoft)
        #expect(JobSource.detectFromURL("HTTPS://CAREERS.MICROSOFT.COM/JOB/ABC") == .microsoft)
    }

    @Test func testDetectTikTok() {
        #expect(JobSource.detectFromURL("https://careers.tiktok.com/position/123") == .tiktok)
        #expect(JobSource.detectFromURL("https://lifeattiktok.com/job/456") == .tiktok)
    }

    @Test func testDetectSnap() {
        #expect(JobSource.detectFromURL("https://careers.snap.com/jobs/123") == .snap)
        #expect(JobSource.detectFromURL("https://snap.com/careers/positions/456") == .snap)
    }

    @Test func testDetectAMD() {
        #expect(JobSource.detectFromURL("https://careers.amd.com/careers-home/jobs/123") == .amd)
    }

    @Test func testDetectMeta() {
        #expect(JobSource.detectFromURL("https://www.metacareers.com/jobs/123456789") == .meta)
    }

    @Test func testDetectWorkday() {
        #expect(JobSource.detectFromURL("https://company.wd1.myworkdayjobs.com/en-US/Careers/job/123") == .workday)
        #expect(JobSource.detectFromURL("https://example.wd5.myworkdayjobs.com/jobs") == .workday)
    }

    @Test func testDetectGreenhouse() {
        #expect(JobSource.detectFromURL("https://boards.greenhouse.io/company/jobs/123456") == .greenhouse)
        #expect(JobSource.detectFromURL("https://company.greenhouse.io/jobs/789") == .greenhouse)
    }

    @Test func testDetectLever() {
        #expect(JobSource.detectFromURL("https://jobs.lever.co/company/abc-123") == .lever)
        #expect(JobSource.detectFromURL("https://company.jobs.lever.co/abc") == .lever)
    }

    @Test func testDetectAshby() {
        #expect(JobSource.detectFromURL("https://jobs.ashbyhq.com/company/job-id") == .ashby)
        #expect(JobSource.detectFromURL("https://company.ashbyhq.com/posting/123") == .ashby)
    }

    @Test func testDetectWorkable() {
        #expect(JobSource.detectFromURL("https://apply.workable.com/company/j/123ABC") == .workable)
    }

    @Test func testDetectJobvite() {
        #expect(JobSource.detectFromURL("https://company.jobvite.com/careers/job/123") == .jobvite)
    }

    @Test func testDetectBambooHR() {
        #expect(JobSource.detectFromURL("https://company.bamboohr.com/jobs/view.php?id=123") == .bamboohr)
    }

    @Test func testDetectSmartRecruiters() {
        #expect(JobSource.detectFromURL("https://jobs.smartrecruiters.com/Company/123456") == .smartrecruiters)
    }

    @Test func testDetectJazzHR() {
        #expect(JobSource.detectFromURL("https://company.jazz.co/apply/123") == .jazzhr)
        #expect(JobSource.detectFromURL("https://company.jazzhr.com/jobs/456") == .jazzhr)
    }

    @Test func testDetectRecuitee() {
        #expect(JobSource.detectFromURL("https://company.recruitee.com/o/job-title-123") == .recruitee)
    }

    @Test func testDetectBreezyHR() {
        #expect(JobSource.detectFromURL("https://company.breezy.hr/p/abc123") == .breezyhr)
    }

    @Test func testUnknownURL() {
        #expect(JobSource.detectFromURL("https://unknown-careers.com/job/123") == nil)
        #expect(JobSource.detectFromURL("https://example.com") == nil)
        #expect(JobSource.detectFromURL("") == nil)
    }

    @Test func testCaseInsensitiveDetection() {
        #expect(JobSource.detectFromURL("HTTPS://GREENHOUSE.IO/JOB") == .greenhouse)
        #expect(JobSource.detectFromURL("https://LEVER.co/job") == .lever)
    }
}

// MARK: - Job Model Tests
struct JobModelTests {

    @Test func testJobIsRecentWithRecentPostingDate() {
        let recentDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let job = Job(
            id: "test1",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: recentDate,
            url: "https://example.com",
            description: "Test job",
            workSiteFlexibility: "Hybrid",
            source: .microsoft,
            companyName: "Test Corp",
            department: "Engineering",
            category: "Software",
            firstSeenDate: Date()
        )

        #expect(job.isRecent == true)
    }

    @Test func testJobIsNotRecentWithOldPostingDate() {
        let oldDate = Date().addingTimeInterval(-86400 * 2) // 2 days ago
        let job = Job(
            id: "test2",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: oldDate,
            url: "https://example.com",
            description: "Test job",
            workSiteFlexibility: "Remote",
            source: .microsoft,
            companyName: "Test Corp",
            department: "Engineering",
            category: "Software",
            firstSeenDate: Date()
        )

        #expect(job.isRecent == false)
    }

    @Test func testJobIsRecentWithNoPostingDateButRecentFirstSeen() {
        let recentFirstSeen = Date().addingTimeInterval(-7200) // 2 hours ago
        let job = Job(
            id: "test3",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: nil,
            url: "https://example.com",
            description: "Test job",
            workSiteFlexibility: nil,
            source: .tiktok,
            companyName: "TikTok",
            department: nil,
            category: nil,
            firstSeenDate: recentFirstSeen
        )

        #expect(job.isRecent == true)
    }

    @Test func testJobIsNotRecentWithOldFirstSeenDate() {
        let oldFirstSeen = Date().addingTimeInterval(-86400 * 3) // 3 days ago
        let job = Job(
            id: "test4",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: nil,
            url: "https://example.com",
            description: "Test job",
            workSiteFlexibility: nil,
            source: .tiktok,
            companyName: "TikTok",
            department: nil,
            category: nil,
            firstSeenDate: oldFirstSeen
        )

        #expect(job.isRecent == false)
    }

    @Test func testJobIsNotRecentWithFutureDate() {
        let futureDate = Date().addingTimeInterval(86400) // 1 day in future
        let job = Job(
            id: "test5",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: futureDate,
            url: "https://example.com",
            description: "Test job",
            workSiteFlexibility: nil,
            source: .microsoft,
            companyName: "Test Corp",
            department: nil,
            category: nil,
            firstSeenDate: Date()
        )

        #expect(job.isRecent == false)
    }

    @Test func testJobOverviewExtraction() {
        let description = """
        <p>We are looking for a software engineer to join our team.</p>
        <p>You will work on exciting projects.</p>
        <p>Required Qualifications</p>
        <ul><li>BS in CS</li></ul>
        """

        let job = Job(
            id: "test6",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: Date(),
            url: "https://example.com",
            description: description,
            workSiteFlexibility: nil,
            source: .microsoft,
            companyName: "Test Corp",
            department: nil,
            category: nil,
            firstSeenDate: Date()
        )

        let overview = job.overview
        #expect(overview.contains("looking for a software engineer"))
        #expect(overview.contains("exciting projects"))
        #expect(!overview.contains("Required Qualifications"))
    }

    @Test func testJobOverviewWithNoQualifications() {
        let description = "<p>Simple job description with no qualifications section.</p>"

        let job = Job(
            id: "test7",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: Date(),
            url: "https://example.com",
            description: description,
            workSiteFlexibility: nil,
            source: .microsoft,
            companyName: "Test Corp",
            department: nil,
            category: nil,
            firstSeenDate: Date()
        )

        let overview = job.overview
        #expect(overview.contains("Simple job description"))
    }

    @Test func testJobOverviewWithEmptyDescription() {
        let job = Job(
            id: "test8",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: Date(),
            url: "https://example.com",
            description: "",
            workSiteFlexibility: nil,
            source: .microsoft,
            companyName: "Test Corp",
            department: nil,
            category: nil,
            firstSeenDate: Date()
        )

        let overview = job.overview
        #expect(overview == "No description available.")
    }

    @Test func testCleanDescription() {
        let htmlDescription = "<p>Job with <strong>HTML</strong> tags</p>"

        let job = Job(
            id: "test9",
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: Date(),
            url: "https://example.com",
            description: htmlDescription,
            workSiteFlexibility: nil,
            source: .microsoft,
            companyName: "Test Corp",
            department: nil,
            category: nil,
            firstSeenDate: Date()
        )

        let clean = job.cleanDescription
        #expect(!clean.contains("<p>"))
        #expect(!clean.contains("<strong>"))
        #expect(clean.contains("Job with"))
        #expect(clean.contains("HTML"))
    }

    @Test func testApplyButtonText() {
        let microsoftJob = Job(id: "1", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .microsoft, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(microsoftJob.applyButtonText == "Apply on Microsoft Careers")

        let tikTokJob = Job(id: "2", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .tiktok, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(tikTokJob.applyButtonText == "Apply on Life at TikTok")

        let snapJob = Job(id: "3", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .snap, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(snapJob.applyButtonText == "Apply on Snap Careers")

        let metaJob = Job(id: "4", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .meta, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(metaJob.applyButtonText == "Apply on Meta Careers")

        let amdJob = Job(id: "5", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .amd, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(amdJob.applyButtonText == "Apply on AMD Careers")

        let greenhouseJob = Job(id: "6", title: "Test", location: "Seattle", postingDate: nil, url: "", description: "", workSiteFlexibility: nil, source: .greenhouse, companyName: nil, department: nil, category: nil, firstSeenDate: Date())
        #expect(greenhouseJob.applyButtonText == "Apply on Company Website")
    }
}

// MARK: - JobBoardConfig Tests
struct JobBoardConfigTests {

    @Test func testJobBoardConfigInitWithValidURL() {
        let config = JobBoardConfig(name: "Test Board", url: "https://boards.greenhouse.io/company")
        #expect(config != nil)
        #expect(config?.source == .greenhouse)
        #expect(config?.name == "Test Board")
        #expect(config?.isEnabled == true)
    }

    @Test func testJobBoardConfigInitWithInvalidURL() {
        let config = JobBoardConfig(name: "Invalid Board", url: "https://unknown-site.com/jobs")
        #expect(config == nil)
    }

    @Test func testJobBoardConfigDisplayName() {
        let configWithName = JobBoardConfig(name: "My Custom Board", url: "https://jobs.lever.co/company")
        #expect(configWithName?.displayName == "My Custom Board")

        let configWithoutName = JobBoardConfig(name: "", url: "https://jobs.ashbyhq.com/company")
        #expect(configWithoutName?.displayName == "Ashby Board")
    }

    @Test func testJobBoardConfigIsSupported() {
        let supportedConfig = JobBoardConfig(name: "Supported", url: "https://boards.greenhouse.io/company")
        #expect(supportedConfig?.isSupported == true)

        let unsupportedConfig = JobBoardConfig(name: "Unsupported", url: "https://apply.workable.com/company")
        #expect(unsupportedConfig?.isSupported == false)
    }
}

// MARK: - ParsedLocation Tests
struct ParsedLocationTests {

    @Test func testParseLocationWithCityStateCountry() {
        let location = ParsedLocation(from: "Seattle, WA, United States")
        #expect(location.city == "Seattle")
        #expect(location.state == "WA")
        #expect(location.country == "United States")
        #expect(location.isRemote == false)
        #expect(location.isMultiple == false)
    }

    @Test func testParseLocationWithCityCountry() {
        let location = ParsedLocation(from: "London, United Kingdom")
        #expect(location.city == "London")
        #expect(location.state == "")
        #expect(location.country == "United Kingdom")
        #expect(location.isRemote == false)
    }

    @Test func testParseLocationWithCountryOnly() {
        let location = ParsedLocation(from: "Canada")
        #expect(location.city == "")
        #expect(location.state == "")
        #expect(location.country == "Canada")
    }

    @Test func testParseLocationWithRemote() {
        let location = ParsedLocation(from: "Remote, United States")
        #expect(location.isRemote == true)
        #expect(location.country == "United States")
    }

    @Test func testParseLocationWithMultipleLocations() {
        let location = ParsedLocation(from: "Multiple Locations, United States")
        #expect(location.isMultiple == true)
        #expect(location.country == "United States")
    }

    @Test func testParseLocationWithSemicolon() {
        let location = ParsedLocation(from: "New York; NY; United States")
        #expect(location.city == "New York")
        #expect(location.state == "NY")
        #expect(location.country == "United States")
    }

    @Test func testLocationDisplayString() {
        let location1 = ParsedLocation(from: "Seattle, WA, United States")
        #expect(location1.displayString == "Seattle, WA")

        let location2 = ParsedLocation(from: "Multiple Locations, Canada")
        #expect(location2.displayString == "Multiple Locations, Canada")

        let location3 = ParsedLocation(from: "Germany")
        #expect(location3.displayString == "Germany")
    }
}
