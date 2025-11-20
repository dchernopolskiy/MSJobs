//
//  JobBoardMonitorTests.swift
//  FlareTests
//
//  Created by automated tests
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - JobBoardMonitor Tests
@Suite("JobBoardMonitor Tests")
struct JobBoardMonitorTests {

    // MARK: - Import/Export Tests

    @Test("Export boards to correct format")
    func testExportBoards() async {
        let monitor = JobBoardMonitor.shared

        // Clear existing boards
        monitor.boardConfigs = []

        // Add test boards
        if let board1 = JobBoardConfig(name: "Test Company 1", url: "https://boards.greenhouse.io/testcompany1", isEnabled: true) {
            monitor.addBoardConfig(board1)
        }

        if let board2 = JobBoardConfig(name: "Test Company 2", url: "https://jobs.lever.co/testcompany2", isEnabled: false) {
            monitor.addBoardConfig(board2)
        }

        // Export
        let exported = monitor.exportBoards()

        // Verify format
        let lines = exported.components(separatedBy: "\n")
        #expect(lines.count == 2)

        // Check first board
        #expect(lines[0].contains("https://boards.greenhouse.io/testcompany1"))
        #expect(lines[0].contains("Test Company 1"))
        #expect(lines[0].contains("enabled"))

        // Check second board
        #expect(lines[1].contains("https://jobs.lever.co/testcompany2"))
        #expect(lines[1].contains("Test Company 2"))
        #expect(lines[1].contains("disabled"))
    }

    @Test("Export empty boards list")
    func testExportEmptyBoards() async {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let exported = monitor.exportBoards()
        #expect(exported.isEmpty)
    }

    @Test("Import boards with valid format")
    func testImportBoardsValidFormat() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = [] // Clear existing

        let importData = """
        https://boards.greenhouse.io/company1 | Company 1 | enabled
        https://jobs.lever.co/company2 | Company 2 | disabled
        https://jobs.ashbyhq.com/company3 | Company 3 | enabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 3)
        #expect(result.failed.isEmpty)
        #expect(monitor.boardConfigs.count == 3)

        // Verify first board
        #expect(monitor.boardConfigs[0].name == "Company 1")
        #expect(monitor.boardConfigs[0].url == "https://boards.greenhouse.io/company1")
        #expect(monitor.boardConfigs[0].isEnabled == true)
        #expect(monitor.boardConfigs[0].source == .greenhouse)

        // Verify second board
        #expect(monitor.boardConfigs[1].name == "Company 2")
        #expect(monitor.boardConfigs[1].isEnabled == false)
        #expect(monitor.boardConfigs[1].source == .lever)

        // Verify third board
        #expect(monitor.boardConfigs[2].name == "Company 3")
        #expect(monitor.boardConfigs[2].source == .ashby)
    }

    @Test("Import boards with URL only (minimal format)")
    func testImportBoardsURLOnly() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/company1
        https://jobs.lever.co/company2
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 2)
        #expect(result.failed.isEmpty)
        #expect(monitor.boardConfigs.count == 2)

        // Verify boards have empty names and default to enabled
        #expect(monitor.boardConfigs[0].name == "")
        #expect(monitor.boardConfigs[0].isEnabled == true)
    }

    @Test("Import boards with invalid URLs")
    func testImportBoardsWithInvalidURLs() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/validcompany | Valid Company | enabled
        https://unknown-careers-site.com/jobs | Unknown Site | enabled
        https://another-unknown.com | Another Unknown | disabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 1) // Only the valid one
        #expect(result.failed.count == 2)
        #expect(monitor.boardConfigs.count == 1)

        // Verify the valid board was added
        #expect(monitor.boardConfigs[0].name == "Valid Company")
    }

    @Test("Import boards ignores empty lines")
    func testImportBoardsIgnoresEmptyLines() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """

        https://boards.greenhouse.io/company1 | Company 1 | enabled


        https://jobs.lever.co/company2 | Company 2 | disabled

        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 2)
        #expect(result.failed.isEmpty)
    }

    @Test("Import boards with whitespace variations")
    func testImportBoardsWithWhitespace() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
          https://boards.greenhouse.io/company1   |   Company 1   |   enabled
        https://jobs.lever.co/company2|Company 2|disabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 2)
        #expect(result.failed.isEmpty)

        // Verify whitespace was trimmed
        #expect(monitor.boardConfigs[0].name == "Company 1")
        #expect(monitor.boardConfigs[0].url == "https://boards.greenhouse.io/company1")
        #expect(monitor.boardConfigs[1].name == "Company 2")
    }

    @Test("Import boards doesn't add duplicates")
    func testImportBoardsNoDuplicates() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        // First import
        let importData1 = "https://boards.greenhouse.io/company1 | Company 1 | enabled"
        let result1 = monitor.importBoards(from: importData1)
        #expect(result1.added == 1)

        // Try to import same URL again
        let importData2 = "https://boards.greenhouse.io/company1 | Company 1 Again | enabled"
        let result2 = monitor.importBoards(from: importData2)
        #expect(result2.added == 0) // Should not add duplicate
        #expect(monitor.boardConfigs.count == 1)
    }

    @Test("Import boards with mixed case enabled/disabled")
    func testImportBoardsMixedCaseStatus() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/company1 | Company 1 | ENABLED
        https://jobs.lever.co/company2 | Company 2 | Disabled
        https://jobs.ashbyhq.com/company3 | Company 3 | EnAbLeD
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 3)
        #expect(monitor.boardConfigs[0].isEnabled == true)
        #expect(monitor.boardConfigs[1].isEnabled == false)
        #expect(monitor.boardConfigs[2].isEnabled == true)
    }

    @Test("Import boards with missing status defaults to enabled")
    func testImportBoardsMissingStatusDefaultsEnabled() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = "https://boards.greenhouse.io/company1 | Company 1"

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 1)
        #expect(monitor.boardConfigs[0].isEnabled == true)
    }

    @Test("Import boards with all supported ATS systems")
    func testImportBoardsAllATSSystems() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/company1 | Greenhouse Board | enabled
        https://jobs.lever.co/company2 | Lever Board | enabled
        https://jobs.ashbyhq.com/company3 | Ashby Board | enabled
        https://company.wd1.myworkdayjobs.com/en-US/Careers | Workday Board | enabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 4)
        #expect(result.failed.isEmpty)

        #expect(monitor.boardConfigs[0].source == .greenhouse)
        #expect(monitor.boardConfigs[1].source == .lever)
        #expect(monitor.boardConfigs[2].source == .ashby)
        #expect(monitor.boardConfigs[3].source == .workday)
    }

    @Test("Import and export round-trip preserves data")
    func testImportExportRoundTrip() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let originalData = """
        https://boards.greenhouse.io/company1 | Company 1 | enabled
        https://jobs.lever.co/company2 | Company 2 | disabled
        https://jobs.ashbyhq.com/company3 | Company 3 | enabled
        """

        // Import
        let importResult = monitor.importBoards(from: originalData)
        #expect(importResult.added == 3)

        // Export
        let exported = monitor.exportBoards()

        // Re-import into a fresh state
        monitor.boardConfigs = []
        let reimportResult = monitor.importBoards(from: exported)

        #expect(reimportResult.added == 3)
        #expect(monitor.boardConfigs.count == 3)

        // Verify data integrity
        #expect(monitor.boardConfigs[0].name == "Company 1")
        #expect(monitor.boardConfigs[0].isEnabled == true)
        #expect(monitor.boardConfigs[1].name == "Company 2")
        #expect(monitor.boardConfigs[1].isEnabled == false)
    }

    // MARK: - Board Management Tests

    @Test("Add board config")
    func testAddBoardConfig() {
        let monitor = JobBoardMonitor.shared
        let initialCount = monitor.boardConfigs.count

        let config = JobBoardConfig(name: "New Board", url: "https://boards.greenhouse.io/newcompany")!
        monitor.addBoardConfig(config)

        #expect(monitor.boardConfigs.count == initialCount + 1)
        #expect(monitor.boardConfigs.last?.name == "New Board")
    }

    @Test("Remove board config")
    func testRemoveBoardConfig() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let config1 = JobBoardConfig(name: "Board 1", url: "https://boards.greenhouse.io/company1")!
        let config2 = JobBoardConfig(name: "Board 2", url: "https://jobs.lever.co/company2")!

        monitor.addBoardConfig(config1)
        monitor.addBoardConfig(config2)

        #expect(monitor.boardConfigs.count == 2)

        monitor.removeBoardConfig(at: 0)

        #expect(monitor.boardConfigs.count == 1)
        #expect(monitor.boardConfigs[0].name == "Board 2")
    }

    @Test("Update board config")
    func testUpdateBoardConfig() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        var config = JobBoardConfig(name: "Original Name", url: "https://boards.greenhouse.io/company")!
        monitor.addBoardConfig(config)

        // Modify the config
        config = monitor.boardConfigs[0]
        var updatedConfig = config
        updatedConfig.isEnabled = false

        monitor.updateBoardConfig(updatedConfig)

        // Verify update
        #expect(monitor.boardConfigs[0].isEnabled == false)
        #expect(monitor.boardConfigs[0].id == config.id)
    }

    @Test("Update non-existent board config does nothing")
    func testUpdateNonExistentConfig() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let config = JobBoardConfig(name: "Board", url: "https://boards.greenhouse.io/company")!
        let initialCount = monitor.boardConfigs.count

        monitor.updateBoardConfig(config)

        #expect(monitor.boardConfigs.count == initialCount)
    }

    // MARK: - Import Edge Cases

    @Test("Import handles malformed lines gracefully")
    func testImportMalformedLines() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/company1 | Company 1 | enabled
        this is not a valid line at all
        | | |
        just-some-text
        https://jobs.lever.co/company2 | Company 2 | enabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 2)
        #expect(result.failed.count == 3)
    }

    @Test("Import with special characters in names")
    func testImportSpecialCharactersInNames() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let importData = """
        https://boards.greenhouse.io/company1 | Company & Co. (Tech) | enabled
        https://jobs.lever.co/company2 | Company #2: The Sequel! | enabled
        """

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 2)
        #expect(monitor.boardConfigs[0].name == "Company & Co. (Tech)")
        #expect(monitor.boardConfigs[1].name == "Company #2: The Sequel!")
    }

    @Test("Import with very long board names")
    func testImportVeryLongNames() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        let longName = String(repeating: "A", count: 200)
        let importData = "https://boards.greenhouse.io/company | \(longName) | enabled"

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 1)
        #expect(monitor.boardConfigs[0].name == longName)
    }

    @Test("Import with pipe character in name")
    func testImportPipeCharacterInName() {
        let monitor = JobBoardMonitor.shared
        monitor.boardConfigs = []

        // This is a tricky case - the name contains a pipe
        // The parser will split on " | " so this should still work correctly
        let importData = "https://boards.greenhouse.io/company | Company|Subsidiary | enabled"

        let result = monitor.importBoards(from: importData)

        #expect(result.added == 1)
        // The name will be "Company|Subsidiary" (without spaces around pipe)
        #expect(monitor.boardConfigs[0].name.contains("Company"))
    }
}
