//
//  LocationServiceTests.swift
//  FlareTests
//
//  Created by automated tests
//

import Testing
import Foundation
@testable import MSJobMonitor

// MARK: - LocationService Tests
@Suite("LocationService Tests")
struct LocationServiceTests {

    // MARK: - extractTargetCountries Tests

    @Test("Extract United States from various US inputs")
    func testExtractUSFromVariousInputs() {
        #expect(LocationService.extractTargetCountries(from: "USA").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "US").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "united states").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Seattle").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "San Francisco").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "California").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Washington").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "New York").contains("United States"))
    }

    @Test("Extract Canada from various Canadian inputs")
    func testExtractCanadaFromVariousInputs() {
        #expect(LocationService.extractTargetCountries(from: "Canada").contains("Canada"))
        #expect(LocationService.extractTargetCountries(from: "Toronto").contains("Canada"))
        #expect(LocationService.extractTargetCountries(from: "Vancouver").contains("Canada"))
        #expect(LocationService.extractTargetCountries(from: "Montreal").contains("Canada"))
        #expect(LocationService.extractTargetCountries(from: "Ottawa").contains("Canada"))
    }

    @Test("Extract United Kingdom from various UK inputs")
    func testExtractUKFromVariousInputs() {
        #expect(LocationService.extractTargetCountries(from: "UK").contains("United Kingdom"))
        #expect(LocationService.extractTargetCountries(from: "United Kingdom").contains("United Kingdom"))
        #expect(LocationService.extractTargetCountries(from: "London").contains("United Kingdom"))
        #expect(LocationService.extractTargetCountries(from: "England").contains("United Kingdom"))
        #expect(LocationService.extractTargetCountries(from: "Scotland").contains("United Kingdom"))
        #expect(LocationService.extractTargetCountries(from: "Manchester").contains("United Kingdom"))
    }

    @Test("Extract European countries")
    func testExtractEuropeanCountries() {
        #expect(LocationService.extractTargetCountries(from: "Germany").contains("Germany"))
        #expect(LocationService.extractTargetCountries(from: "Berlin").contains("Germany"))
        #expect(LocationService.extractTargetCountries(from: "France").contains("France"))
        #expect(LocationService.extractTargetCountries(from: "Paris").contains("France"))
        #expect(LocationService.extractTargetCountries(from: "Netherlands").contains("Netherlands"))
        #expect(LocationService.extractTargetCountries(from: "Amsterdam").contains("Netherlands"))
        #expect(LocationService.extractTargetCountries(from: "Sweden").contains("Sweden"))
        #expect(LocationService.extractTargetCountries(from: "Stockholm").contains("Sweden"))
    }

    @Test("Extract Asian countries")
    func testExtractAsianCountries() {
        #expect(LocationService.extractTargetCountries(from: "India").contains("India"))
        #expect(LocationService.extractTargetCountries(from: "Bangalore").contains("India"))
        #expect(LocationService.extractTargetCountries(from: "Singapore").contains("Singapore"))
        #expect(LocationService.extractTargetCountries(from: "Hong Kong").contains("Hong Kong"))
        #expect(LocationService.extractTargetCountries(from: "China").contains("China"))
        #expect(LocationService.extractTargetCountries(from: "Japan").contains("Japan"))
        #expect(LocationService.extractTargetCountries(from: "Tokyo").contains("Japan"))
    }

    @Test("Extract Australia")
    func testExtractAustralia() {
        #expect(LocationService.extractTargetCountries(from: "Australia").contains("Australia"))
        #expect(LocationService.extractTargetCountries(from: "Sydney").contains("Australia"))
        #expect(LocationService.extractTargetCountries(from: "Melbourne").contains("Australia"))
    }

    @Test("Extract multiple countries from combined input")
    func testExtractMultipleCountries() {
        let countries = LocationService.extractTargetCountries(from: "Seattle, Toronto, London")
        #expect(countries.contains("United States"))
        #expect(countries.contains("Canada"))
        #expect(countries.contains("United Kingdom"))
        #expect(countries.count == 3)
    }

    @Test("Default to United States for empty input")
    func testDefaultToUSForEmptyInput() {
        let countries = LocationService.extractTargetCountries(from: "")
        #expect(countries.contains("United States"))
        #expect(countries.contains("Canada"))
    }

    @Test("Default to United States for unknown location")
    func testDefaultToUSForUnknownLocation() {
        let countries = LocationService.extractTargetCountries(from: "Unknown City")
        #expect(countries.contains("United States"))
        #expect(countries.count == 1)
    }

    @Test("Case insensitive matching")
    func testCaseInsensitiveMatching() {
        #expect(LocationService.extractTargetCountries(from: "SEATTLE").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "seattle").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "SeAtTlE").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "LONDON").contains("United Kingdom"))
    }

    @Test("State abbreviations mapping")
    func testStateAbbreviations() {
        #expect(LocationService.extractTargetCountries(from: "WA").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "CA").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "NY").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "TX").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "MA").contains("United States"))
    }

    @Test("Major US cities mapping")
    func testMajorUSCities() {
        #expect(LocationService.extractTargetCountries(from: "Redmond").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Bay Area").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Mountain View").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Austin").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Boston").contains("United States"))
        #expect(LocationService.extractTargetCountries(from: "Chicago").contains("United States"))
    }

    // MARK: - getMicrosoftLocationParams Tests

    @Test("Get Microsoft location params for US")
    func testGetMicrosoftLocationParamsUS() {
        let params = LocationService.getMicrosoftLocationParams("Seattle, WA")
        #expect(params.contains("United States"))
    }

    @Test("Get Microsoft location params for multiple countries")
    func testGetMicrosoftLocationParamsMultiple() {
        let params = LocationService.getMicrosoftLocationParams("Seattle, London, Toronto")
        #expect(params.contains("United States"))
        #expect(params.contains("United Kingdom"))
        #expect(params.contains("Canada"))
        #expect(params.count == 3)
    }

    @Test("Get Microsoft location params for Germany")
    func testGetMicrosoftLocationParamsGermany() {
        let params = LocationService.getMicrosoftLocationParams("Berlin")
        #expect(params.contains("Germany"))
    }

    @Test("Get Microsoft location params for India")
    func testGetMicrosoftLocationParamsIndia() {
        let params = LocationService.getMicrosoftLocationParams("Bangalore")
        #expect(params.contains("India"))
    }

    // MARK: - getTikTokLocationCodes Tests

    @Test("Get TikTok location code for Seattle")
    func testGetTikTokLocationCodeSeattle() {
        let codes = LocationService.getTikTokLocationCodes("Seattle")
        #expect(codes.contains("CT_157"))
    }

    @Test("Get TikTok location code for San Francisco")
    func testGetTikTokLocationCodeSanFrancisco() {
        let codes = LocationService.getTikTokLocationCodes("San Francisco")
        #expect(codes.contains("CT_75"))
    }

    @Test("Get TikTok location code for New York")
    func testGetTikTokLocationCodeNewYork() {
        let codes = LocationService.getTikTokLocationCodes("New York")
        #expect(codes.contains("CT_114"))
    }

    @Test("Get TikTok location code for Los Angeles")
    func testGetTikTokLocationCodeLosAngeles() {
        let codes = LocationService.getTikTokLocationCodes("Los Angeles")
        #expect(codes.contains("CT_94"))
    }

    @Test("Get TikTok location code for Austin")
    func testGetTikTokLocationCodeAustin() {
        let codes = LocationService.getTikTokLocationCodes("Austin")
        #expect(codes.contains("CT_247"))
    }

    @Test("Get TikTok location code for London")
    func testGetTikTokLocationCodeLondon() {
        let codes = LocationService.getTikTokLocationCodes("London")
        #expect(codes.contains("CT_93"))
    }

    @Test("Get TikTok location code for Singapore")
    func testGetTikTokLocationCodeSingapore() {
        let codes = LocationService.getTikTokLocationCodes("Singapore")
        #expect(codes.contains("CT_163"))
    }

    @Test("Get TikTok location codes for multiple cities")
    func testGetTikTokLocationCodesMultiple() {
        let codes = LocationService.getTikTokLocationCodes("Seattle, San Francisco, Austin")
        #expect(codes.contains("CT_157")) // Seattle
        #expect(codes.contains("CT_75"))  // SF
        #expect(codes.contains("CT_247")) // Austin
        #expect(codes.count == 3)
    }

    @Test("Get TikTok location codes for state - Washington")
    func testGetTikTokLocationCodesWashingtonState() {
        let codes = LocationService.getTikTokLocationCodes("Washington")
        #expect(codes.contains("CT_157")) // Seattle
    }

    @Test("Get TikTok location codes for state - California")
    func testGetTikTokLocationCodesCaliforniaState() {
        let codes = LocationService.getTikTokLocationCodes("California")
        // Should include SF, LA, Mountain View, San Jose
        #expect(codes.count >= 1)
        #expect(codes.contains("CT_75") || codes.contains("CT_94"))
    }

    @Test("Get TikTok location codes for state - New York")
    func testGetTikTokLocationCodesNewYorkState() {
        let codes = LocationService.getTikTokLocationCodes("New York")
        #expect(codes.contains("CT_114"))
    }

    @Test("Get TikTok location codes for state - Texas")
    func testGetTikTokLocationCodesTexasState() {
        let codes = LocationService.getTikTokLocationCodes("Texas")
        #expect(codes.contains("CT_247")) // Austin
    }

    @Test("TikTok location codes ignore remote keyword")
    func testTikTokLocationCodesIgnoreRemote() {
        let codes = LocationService.getTikTokLocationCodes("Seattle, Remote")
        #expect(codes.contains("CT_157"))
        // Remote should be filtered out
    }

    @Test("TikTok location codes empty for unknown location")
    func testTikTokLocationCodesEmptyForUnknown() {
        let codes = LocationService.getTikTokLocationCodes("Unknown City Name")
        #expect(codes.isEmpty)
    }

    @Test("TikTok location codes case insensitive")
    func testTikTokLocationCodesCaseInsensitive() {
        let codes1 = LocationService.getTikTokLocationCodes("seattle")
        let codes2 = LocationService.getTikTokLocationCodes("SEATTLE")
        let codes3 = LocationService.getTikTokLocationCodes("Seattle")

        #expect(codes1.contains("CT_157"))
        #expect(codes2.contains("CT_157"))
        #expect(codes3.contains("CT_157"))
    }

    @Test("TikTok location codes for international cities")
    func testTikTokLocationCodesInternational() {
        #expect(LocationService.getTikTokLocationCodes("Dublin").contains("CT_37"))
        #expect(LocationService.getTikTokLocationCodes("Paris").contains("CT_5"))
        #expect(LocationService.getTikTokLocationCodes("Berlin").contains("CT_6"))
        #expect(LocationService.getTikTokLocationCodes("Amsterdam").contains("CT_100766"))
        #expect(LocationService.getTikTokLocationCodes("Tokyo").contains("CT_34"))
        #expect(LocationService.getTikTokLocationCodes("Sydney").contains("CT_244"))
        #expect(LocationService.getTikTokLocationCodes("Bangalore").contains("CT_44"))
    }

    // MARK: - Edge Cases

    @Test("Handle input with extra whitespace")
    func testHandleExtraWhitespace() {
        let countries = LocationService.extractTargetCountries(from: "  Seattle  ,  London  ")
        #expect(countries.contains("United States"))
        #expect(countries.contains("United Kingdom"))
    }

    @Test("Handle input with special characters")
    func testHandleSpecialCharacters() {
        let countries = LocationService.extractTargetCountries(from: "Seattle, WA; London, UK")
        #expect(countries.contains("United States"))
        #expect(countries.contains("United Kingdom"))
    }

    @Test("Handle ambiguous abbreviations correctly")
    func testHandleAmbiguousAbbreviations() {
        // CA could mean California or Canada, but based on the code it should map to United States
        let countries = LocationService.extractTargetCountries(from: "CA")
        #expect(countries.contains("United States"))
    }

    @Test("Extract countries from complex filter strings")
    func testExtractFromComplexFilterStrings() {
        let countries = LocationService.extractTargetCountries(from: "Remote - Seattle or San Francisco, Bay Area")
        #expect(countries.contains("United States"))
    }

    @Test("Multiple mappings to same country deduplicated")
    func testMultipleMappingsSameCountry() {
        // Seattle, San Francisco, and California all map to United States
        let countries = LocationService.extractTargetCountries(from: "Seattle, San Francisco, California")
        #expect(countries.contains("United States"))
        #expect(countries.count == 1) // Should be deduplicated
    }
}
