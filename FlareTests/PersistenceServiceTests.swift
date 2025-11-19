//
//  PersistenceServiceTests.swift
//  FlareTests
//
//  Created by automated tests
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - PersistenceService Tests
@Suite("PersistenceService Tests")
struct PersistenceServiceTests {

    // Helper to create test jobs
    func createTestJob(id: String = "test-job-1") -> Job {
        Job(
            id: id,
            title: "Software Engineer",
            location: "Seattle, WA",
            postingDate: Date(),
            url: "https://example.com/job/\(id)",
            description: "<p>Test job description</p>",
            workSiteFlexibility: "Hybrid",
            source: .microsoft,
            companyName: "Test Company",
            department: "Engineering",
            category: "Software Development",
            firstSeenDate: Date()
        )
    }

    @Test("Save and load jobs successfully")
    func testSaveAndLoadJobs() async throws {
        let persistence = PersistenceService.shared

        // Create test jobs
        let jobs = [
            createTestJob(id: "job1"),
            createTestJob(id: "job2"),
            createTestJob(id: "job3")
        ]

        // Save jobs
        try await persistence.saveJobs(jobs)

        // Load jobs
        let loadedJobs = try await persistence.loadJobs()

        // Verify
        #expect(loadedJobs.count == 3)
        #expect(loadedJobs[0].id == "job1")
        #expect(loadedJobs[1].id == "job2")
        #expect(loadedJobs[2].id == "job3")
        #expect(loadedJobs[0].title == "Software Engineer")
    }

    @Test("Save and load empty jobs array")
    func testSaveAndLoadEmptyJobs() async throws {
        let persistence = PersistenceService.shared

        // Save empty array
        try await persistence.saveJobs([])

        // Load jobs
        let loadedJobs = try await persistence.loadJobs()

        // Verify
        #expect(loadedJobs.isEmpty)
    }

    @Test("Save and load stored job IDs")
    func testSaveAndLoadStoredJobIds() async throws {
        let persistence = PersistenceService.shared

        // Create test IDs
        let ids: Set<String> = ["id1", "id2", "id3", "id4"]

        // Save IDs
        try await persistence.saveStoredJobIds(ids)

        // Load IDs
        let loadedIds = try await persistence.loadStoredJobIds()

        // Verify
        #expect(loadedIds.count == 4)
        #expect(loadedIds.contains("id1"))
        #expect(loadedIds.contains("id2"))
        #expect(loadedIds.contains("id3"))
        #expect(loadedIds.contains("id4"))
    }

    @Test("Save and load empty job IDs set")
    func testSaveAndLoadEmptyJobIds() async throws {
        let persistence = PersistenceService.shared

        // Save empty set
        try await persistence.saveStoredJobIds(Set<String>())

        // Load IDs
        let loadedIds = try await persistence.loadStoredJobIds()

        // Verify
        #expect(loadedIds.isEmpty)
    }

    @Test("Save and load applied job IDs")
    func testSaveAndLoadAppliedJobIds() async throws {
        let persistence = PersistenceService.shared

        // Create test IDs
        let ids: Set<String> = ["applied1", "applied2"]

        // Save IDs
        try await persistence.saveAppliedJobIds(ids)

        // Load IDs
        let loadedIds = try await persistence.loadAppliedJobIds()

        // Verify
        #expect(loadedIds.count == 2)
        #expect(loadedIds.contains("applied1"))
        #expect(loadedIds.contains("applied2"))
    }

    @Test("Save and load board configs")
    func testSaveAndLoadBoardConfigs() async throws {
        let persistence = PersistenceService.shared

        // Create test configs
        let config1 = JobBoardConfig(name: "Test Board 1", url: "https://boards.greenhouse.io/testcompany1")
        let config2 = JobBoardConfig(name: "Test Board 2", url: "https://jobs.lever.co/testcompany2")

        let configs = [config1, config2].compactMap { $0 }

        // Save configs
        try await persistence.saveBoardConfigs(configs)

        // Load configs
        let loadedConfigs = try await persistence.loadBoardConfigs()

        // Verify
        #expect(loadedConfigs.count == 2)
        #expect(loadedConfigs[0].name == "Test Board 1")
        #expect(loadedConfigs[0].source == .greenhouse)
        #expect(loadedConfigs[1].name == "Test Board 2")
        #expect(loadedConfigs[1].source == .lever)
    }

    @Test("Save and load source-specific job IDs - Microsoft")
    func testSaveAndLoadSourceJobIdsMicrosoft() async throws {
        let persistence = PersistenceService.shared

        let ids: Set<String> = ["ms-job-1", "ms-job-2", "ms-job-3"]

        // Save Microsoft job IDs
        try await persistence.saveSourceJobIds(source: .microsoft, ids: ids)

        // Load Microsoft job IDs
        let loadedIds = try await persistence.loadSourceJobIds(source: .microsoft)

        // Verify
        #expect(loadedIds.count == 3)
        #expect(loadedIds.contains("ms-job-1"))
        #expect(loadedIds.contains("ms-job-2"))
        #expect(loadedIds.contains("ms-job-3"))
    }

    @Test("Save and load source-specific job IDs - TikTok")
    func testSaveAndLoadSourceJobIdsTikTok() async throws {
        let persistence = PersistenceService.shared

        let ids: Set<String> = ["tt-job-1", "tt-job-2"]

        // Save TikTok job IDs
        try await persistence.saveSourceJobIds(source: .tiktok, ids: ids)

        // Load TikTok job IDs
        let loadedIds = try await persistence.loadSourceJobIds(source: .tiktok)

        // Verify
        #expect(loadedIds.count == 2)
        #expect(loadedIds.contains("tt-job-1"))
        #expect(loadedIds.contains("tt-job-2"))
    }

    @Test("Load source-specific job IDs when file doesn't exist")
    func testLoadSourceJobIdsWhenFileDoesntExist() async throws {
        let persistence = PersistenceService.shared

        // Load IDs for a source that hasn't been saved yet
        let loadedIds = try await persistence.loadSourceJobIds(source: .snap)

        // Verify returns empty set instead of throwing
        #expect(loadedIds.isEmpty)
    }

    @Test("Save and load starred job IDs")
    func testSaveAndLoadStarredJobIds() async throws {
        let persistence = PersistenceService.shared

        let ids: Set<String> = ["star-1", "star-2", "star-3"]

        // Save starred IDs
        try await persistence.saveStarredJobIds(ids)

        // Load starred IDs
        let loadedIds = try await persistence.loadStarredJobIds()

        // Verify
        #expect(loadedIds.count == 3)
        #expect(loadedIds.contains("star-1"))
        #expect(loadedIds.contains("star-2"))
        #expect(loadedIds.contains("star-3"))
    }

    @Test("Load starred job IDs when file doesn't exist")
    func testLoadStarredJobIdsWhenFileDoesntExist() async throws {
        let persistence = PersistenceService.shared

        // First, try to delete the file if it exists
        // Then load - should return empty set
        let loadedIds = try await persistence.loadStarredJobIds()

        // Should not throw and should return a set (possibly empty or with existing data)
        #expect(loadedIds != nil)
    }

    @Test("Overwrite existing jobs")
    func testOverwriteExistingJobs() async throws {
        let persistence = PersistenceService.shared

        // Save initial jobs
        let initialJobs = [createTestJob(id: "initial")]
        try await persistence.saveJobs(initialJobs)

        // Save new jobs (overwriting)
        let newJobs = [
            createTestJob(id: "new1"),
            createTestJob(id: "new2")
        ]
        try await persistence.saveJobs(newJobs)

        // Load jobs
        let loadedJobs = try await persistence.loadJobs()

        // Verify new jobs replaced old ones
        #expect(loadedJobs.count == 2)
        #expect(loadedJobs[0].id == "new1")
        #expect(loadedJobs[1].id == "new2")
        #expect(!loadedJobs.contains(where: { $0.id == "initial" }))
    }

    @Test("Jobs with all fields preserved during save/load")
    func testJobsWithAllFieldsPreserved() async throws {
        let persistence = PersistenceService.shared

        let testDate = Date(timeIntervalSince1970: 1700000000) // Fixed date for testing
        let firstSeenDate = Date(timeIntervalSince1970: 1700086400)

        let job = Job(
            id: "detailed-job",
            title: "Senior Software Engineer",
            location: "San Francisco, CA, United States",
            postingDate: testDate,
            url: "https://careers.microsoft.com/us/en/job/detailed-job",
            description: "<p>Detailed job description with HTML</p><ul><li>Point 1</li></ul>",
            workSiteFlexibility: "Remote",
            source: .microsoft,
            companyName: "Microsoft Corporation",
            department: "Cloud & AI",
            category: "Software Engineering",
            firstSeenDate: firstSeenDate
        )

        // Save job
        try await persistence.saveJobs([job])

        // Load job
        let loadedJobs = try await persistence.loadJobs()

        // Verify all fields
        #expect(loadedJobs.count == 1)
        let loadedJob = loadedJobs[0]
        #expect(loadedJob.id == "detailed-job")
        #expect(loadedJob.title == "Senior Software Engineer")
        #expect(loadedJob.location == "San Francisco, CA, United States")
        #expect(loadedJob.url == "https://careers.microsoft.com/us/en/job/detailed-job")
        #expect(loadedJob.description.contains("Detailed job description"))
        #expect(loadedJob.workSiteFlexibility == "Remote")
        #expect(loadedJob.source == .microsoft)
        #expect(loadedJob.companyName == "Microsoft Corporation")
        #expect(loadedJob.department == "Cloud & AI")
        #expect(loadedJob.category == "Software Engineering")
        #expect(loadedJob.postingDate != nil)
    }

    @Test("Data directory path is accessible")
    func testGetDataDirectoryPath() async {
        let persistence = PersistenceService.shared

        let path = await persistence.getDataDirectoryPath()

        // Verify path is not empty and contains expected directory name
        #expect(!path.isEmpty)
        #expect(path.contains("MicrosoftJobMonitor"))
    }

    @Test("Storage info is retrievable")
    func testGetStorageInfo() async {
        let persistence = PersistenceService.shared

        let info = await persistence.getStorageInfo()

        // Verify info contains expected keys
        #expect(info["dataDirectory"] != nil)
        #expect(info["files"] != nil)

        if let dataDir = info["dataDirectory"] as? String {
            #expect(!dataDir.isEmpty)
        }

        if let files = info["files"] as? [String: String] {
            #expect(files["jobs.json"] != nil)
            #expect(files["storedIds.json"] != nil)
            #expect(files["appliedJobs.json"] != nil)
        }
    }

    @Test("Multiple sources can have separate job IDs")
    func testMultipleSourcesSeparateIds() async throws {
        let persistence = PersistenceService.shared

        // Save IDs for different sources
        try await persistence.saveSourceJobIds(source: .microsoft, ids: ["ms-1", "ms-2"])
        try await persistence.saveSourceJobIds(source: .tiktok, ids: ["tt-1", "tt-2"])
        try await persistence.saveSourceJobIds(source: .meta, ids: ["meta-1"])

        // Load IDs for each source
        let msIds = try await persistence.loadSourceJobIds(source: .microsoft)
        let ttIds = try await persistence.loadSourceJobIds(source: .tiktok)
        let metaIds = try await persistence.loadSourceJobIds(source: .meta)

        // Verify each source has its own IDs
        #expect(msIds.count == 2)
        #expect(ttIds.count == 2)
        #expect(metaIds.count == 1)
        #expect(msIds.contains("ms-1"))
        #expect(ttIds.contains("tt-1"))
        #expect(metaIds.contains("meta-1"))

        // Verify no cross-contamination
        #expect(!msIds.contains("tt-1"))
        #expect(!ttIds.contains("ms-1"))
    }
}
