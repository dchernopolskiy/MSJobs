//
//  JobsManagerTests.swift
//  FlareTests
//
//  Created by automated tests
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - JobsManager Tests
@Suite("JobsManager Tests")
struct JobsManagerTests {

    // MARK: - Title Keyword Parsing Tests

    @Test("Parse single title keyword")
    func testParseSingleTitleKeyword() {
        let filter = "Engineer"
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 1)
        #expect(keywords[0] == "Engineer")
    }

    @Test("Parse multiple title keywords")
    func testParseMultipleTitleKeywords() {
        let filter = "Engineer,Manager,Designer"
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 3)
        #expect(keywords[0] == "Engineer")
        #expect(keywords[1] == "Manager")
        #expect(keywords[2] == "Designer")
    }

    @Test("Parse keywords with whitespace")
    func testParseKeywordsWithWhitespace() {
        let filter = " Engineer , Manager ,  Designer "
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 3)
        #expect(keywords[0] == "Engineer")
        #expect(keywords[1] == "Manager")
        #expect(keywords[2] == "Designer")
    }

    @Test("Parse empty keyword filter")
    func testParseEmptyKeywordFilter() {
        let filter = ""
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.isEmpty)
    }

    @Test("Parse keywords with only commas")
    func testParseKeywordsOnlyCommas() {
        let filter = ",,,"
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.isEmpty)
    }

    @Test("Parse keywords with extra whitespace")
    func testParseKeywordsExtraWhitespace() {
        let filter = "  Software Engineer  ,  Product Manager  ,  UX Designer  "
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 3)
        #expect(keywords[0] == "Software Engineer")
        #expect(keywords[1] == "Product Manager")
        #expect(keywords[2] == "UX Designer")
    }

    @Test("Parse keywords filters out empty entries")
    func testParseKeywordsFiltersEmpty() {
        let filter = "Engineer,,Manager,,,"
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 2)
        #expect(keywords[0] == "Engineer")
        #expect(keywords[1] == "Manager")
    }

    @Test("Parse keywords with special characters")
    func testParseKeywordsWithSpecialCharacters() {
        let filter = "C++ Engineer, C# Developer, .NET Architect"
        let keywords = filter
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        #expect(keywords.count == 3)
        #expect(keywords[0] == "C++ Engineer")
        #expect(keywords[1] == "C# Developer")
        #expect(keywords[2] == ".NET Architect")
    }

    // MARK: - Job Filtering Tests

    @Test("Filter jobs by 24-hour window using posting date")
    func testFilterJobsBy24HourWindow() {
        let now = Date()

        let jobs = [
            Job(
                id: "1",
                title: "Recent Job",
                location: "Seattle",
                postingDate: now.addingTimeInterval(-3600), // 1 hour ago
                url: "https://example.com",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now
            ),
            Job(
                id: "2",
                title: "Old Job",
                location: "Seattle",
                postingDate: now.addingTimeInterval(-86400 * 2), // 2 days ago
                url: "https://example.com",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now.addingTimeInterval(-86400 * 2)
            ),
        ]

        let recentJobs = jobs.filter { job in
            if let postingDate = job.postingDate {
                return Date().timeIntervalSince(postingDate) <= 86400
            } else {
                return Date().timeIntervalSince(job.firstSeenDate) <= 86400
            }
        }

        #expect(recentJobs.count == 1)
        #expect(recentJobs[0].id == "1")
    }

    @Test("Filter jobs by first seen date when no posting date")
    func testFilterJobsByFirstSeenDate() {
        let now = Date()

        let jobs = [
            Job(
                id: "1",
                title: "Recent Job",
                location: "Seattle",
                postingDate: nil,
                url: "https://example.com",
                description: "Test",
                workSiteFlexibility: nil,
                source: .tiktok,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now.addingTimeInterval(-3600) // 1 hour ago
            ),
            Job(
                id: "2",
                title: "Old Job",
                location: "Seattle",
                postingDate: nil,
                url: "https://example.com",
                description: "Test",
                workSiteFlexibility: nil,
                source: .tiktok,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now.addingTimeInterval(-86400 * 2) // 2 days ago
            ),
        ]

        let recentJobs = jobs.filter { job in
            if let postingDate = job.postingDate {
                return Date().timeIntervalSince(postingDate) <= 86400
            } else {
                return Date().timeIntervalSince(job.firstSeenDate) <= 86400
            }
        }

        #expect(recentJobs.count == 1)
        #expect(recentJobs[0].id == "1")
    }

    // MARK: - Job Sorting Tests

    @Test("Sort jobs by posting date descending")
    func testSortJobsByPostingDate() {
        let baseDate = Date()

        let jobs = [
            Job(
                id: "1",
                title: "Job 1",
                location: "Seattle",
                postingDate: baseDate.addingTimeInterval(-7200), // 2 hours ago
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: baseDate
            ),
            Job(
                id: "2",
                title: "Job 2",
                location: "Seattle",
                postingDate: baseDate.addingTimeInterval(-3600), // 1 hour ago (newer)
                url: "https://example.com/2",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: baseDate
            ),
            Job(
                id: "3",
                title: "Job 3",
                location: "Seattle",
                postingDate: baseDate.addingTimeInterval(-10800), // 3 hours ago
                url: "https://example.com/3",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: baseDate
            ),
        ]

        let sortedJobs = jobs.sorted { job1, job2 in
            let date1 = job1.postingDate ?? job1.firstSeenDate
            let date2 = job2.postingDate ?? job2.firstSeenDate
            return date1 > date2
        }

        #expect(sortedJobs[0].id == "2") // Most recent
        #expect(sortedJobs[1].id == "1")
        #expect(sortedJobs[2].id == "3") // Oldest
    }

    @Test("Sort jobs by first seen date when no posting date")
    func testSortJobsByFirstSeenDate() {
        let baseDate = Date()

        let jobs = [
            Job(
                id: "1",
                title: "Job 1",
                location: "Seattle",
                postingDate: nil,
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .tiktok,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: baseDate.addingTimeInterval(-7200) // 2 hours ago
            ),
            Job(
                id: "2",
                title: "Job 2",
                location: "Seattle",
                postingDate: nil,
                url: "https://example.com/2",
                description: "Test",
                workSiteFlexibility: nil,
                source: .tiktok,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: baseDate.addingTimeInterval(-3600) // 1 hour ago (newer)
            ),
        ]

        let sortedJobs = jobs.sorted { job1, job2 in
            let date1 = job1.postingDate ?? job1.firstSeenDate
            let date2 = job2.postingDate ?? job2.firstSeenDate
            return date1 > date2
        }

        #expect(sortedJobs[0].id == "2") // Most recent
        #expect(sortedJobs[1].id == "1") // Older
    }

    // MARK: - Job Deduplication Tests

    @Test("Deduplicate jobs by ID")
    func testDeduplicateJobs() {
        let now = Date()

        let jobs = [
            Job(
                id: "job-1",
                title: "Engineer",
                location: "Seattle",
                postingDate: now,
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now
            ),
            Job(
                id: "job-2",
                title: "Manager",
                location: "Seattle",
                postingDate: now,
                url: "https://example.com/2",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now
            ),
            Job(
                id: "job-1", // Duplicate
                title: "Engineer (Duplicate)",
                location: "San Francisco",
                postingDate: now,
                url: "https://example.com/1-dup",
                description: "Test Duplicate",
                workSiteFlexibility: nil,
                source: .tiktok,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now
            ),
        ]

        var uniqueJobs: [Job] = []
        var seenIds = Set<String>()

        for job in jobs {
            if !seenIds.contains(job.id) {
                uniqueJobs.append(job)
                seenIds.insert(job.id)
            }
        }

        #expect(uniqueJobs.count == 2)
        #expect(seenIds.count == 2)
        #expect(seenIds.contains("job-1"))
        #expect(seenIds.contains("job-2"))

        // First occurrence should be kept
        #expect(uniqueJobs[0].title == "Engineer")
        #expect(uniqueJobs[1].title == "Manager")
    }

    // MARK: - FetchStatistics Tests

    @Test("Fetch statistics summary with multiple sources")
    func testFetchStatisticsSummaryMultipleSources() {
        var stats = FetchStatistics()
        stats.microsoftJobs = 10
        stats.tiktokJobs = 5
        stats.snapJobs = 3

        let summary = stats.summary

        #expect(summary.contains("Microsoft: 10"))
        #expect(summary.contains("TikTok: 5"))
        #expect(summary.contains("Snap: 3"))
    }

    @Test("Fetch statistics summary with single source")
    func testFetchStatisticsSummarySingleSource() {
        var stats = FetchStatistics()
        stats.microsoftJobs = 15

        let summary = stats.summary

        #expect(summary.contains("Microsoft: 15"))
        #expect(!summary.contains("TikTok"))
        #expect(!summary.contains("Snap"))
    }

    @Test("Fetch statistics summary with zero jobs")
    func testFetchStatisticsSummaryZeroJobs() {
        let stats = FetchStatistics()

        let summary = stats.summary

        // Summary should be empty or minimal when no jobs
        #expect(summary.count < 10)
    }

    @Test("Fetch statistics summary includes all sources")
    func testFetchStatisticsSummaryAllSources() {
        var stats = FetchStatistics()
        stats.microsoftJobs = 10
        stats.tiktokJobs = 5
        stats.snapJobs = 3
        stats.metaJobs = 7
        stats.amdJobs = 2
        stats.customBoardJobs = 4

        let summary = stats.summary

        #expect(summary.contains("Microsoft"))
        #expect(summary.contains("TikTok"))
        #expect(summary.contains("Snap"))
        #expect(summary.contains("Meta"))
        #expect(summary.contains("AMD"))
    }

    // MARK: - New Job Detection Tests

    @Test("Filter new jobs from stored IDs")
    func testFilterNewJobs() {
        let storedIds: Set<String> = ["job-1", "job-2", "job-3"]

        let jobs = [
            Job(
                id: "job-1",
                title: "Already Seen",
                location: "Seattle",
                postingDate: Date(),
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: Date()
            ),
            Job(
                id: "job-4",
                title: "New Job",
                location: "Seattle",
                postingDate: Date(),
                url: "https://example.com/4",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: Date()
            ),
            Job(
                id: "job-5",
                title: "Another New Job",
                location: "Seattle",
                postingDate: Date(),
                url: "https://example.com/5",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: Date()
            ),
        ]

        let newJobs = jobs.filter { job in
            !storedIds.contains(job.id)
        }

        #expect(newJobs.count == 2)
        #expect(newJobs[0].id == "job-4")
        #expect(newJobs[1].id == "job-5")
    }

    @Test("Filter new jobs returns empty when all seen")
    func testFilterNewJobsAllSeen() {
        let storedIds: Set<String> = ["job-1", "job-2", "job-3"]

        let jobs = [
            Job(
                id: "job-1",
                title: "Job 1",
                location: "Seattle",
                postingDate: Date(),
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: Date()
            ),
            Job(
                id: "job-2",
                title: "Job 2",
                location: "Seattle",
                postingDate: Date(),
                url: "https://example.com/2",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: Date()
            ),
        ]

        let newJobs = jobs.filter { job in
            !storedIds.contains(job.id)
        }

        #expect(newJobs.isEmpty)
    }

    @Test("Filter recent new jobs (within 2 hours)")
    func testFilterRecentNewJobs() {
        let now = Date()

        let newJobs = [
            Job(
                id: "1",
                title: "Very Recent",
                location: "Seattle",
                postingDate: now.addingTimeInterval(-1800), // 30 min ago
                url: "https://example.com/1",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now
            ),
            Job(
                id: "2",
                title: "Old New Job",
                location: "Seattle",
                postingDate: now.addingTimeInterval(-10800), // 3 hours ago
                url: "https://example.com/2",
                description: "Test",
                workSiteFlexibility: nil,
                source: .microsoft,
                companyName: nil,
                department: nil,
                category: nil,
                firstSeenDate: now.addingTimeInterval(-10800)
            ),
        ]

        let recentNewJobs = newJobs.filter { job in
            if let postingDate = job.postingDate {
                return Date().timeIntervalSince(postingDate) <= 7200 // 2 hours
            } else {
                return Date().timeIntervalSince(job.firstSeenDate) <= 7200
            }
        }

        #expect(recentNewJobs.count == 1)
        #expect(recentNewJobs[0].id == "1")
    }
}
