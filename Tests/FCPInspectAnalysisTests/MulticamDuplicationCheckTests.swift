import XCTest
@testable import FCPInspectCore
@testable import FCPInspectAnalysis

final class MulticamDuplicationCheckTests: XCTestCase {

    // MARK: Helpers

    private func fixtureURL(_ name: String) -> URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("test-fixtures")
            .appendingPathComponent(name)
    }

    private func mergedDocument(_ names: [String]) throws -> FCPXMLDocument {
        let parser = FCPXMLParser()
        let docs = try names.map { try parser.parse(path: fixtureURL($0)) }
        let medias = docs.flatMap(\.medias)
        return FCPXMLDocument(version: docs.first?.version ?? "", medias: medias)
    }

    private func makeMedia(
        id: String,
        uid: String,
        name: String,
        modDate: Date?,
        angleIDs: [String]
    ) -> Media {
        let location = XMLLocation(xpath: "/fcpxml/resources/media[\(id)]")
        let angles = angleIDs.enumerated().map { idx, aid in
            MCAngle(
                name: "angle-\(idx)",
                angleID: aid,
                assetClips: [],
                location: XMLLocation(xpath: location.xpath + "/mc-angle[\(idx + 1)]")
            )
        }
        let mc = Multicam(
            format: "r2",
            tcStart: nil,
            tcFormat: "NDF",
            angles: angles,
            location: XMLLocation(xpath: location.xpath + "/multicam")
        )
        return Media(
            id: id,
            name: name,
            uid: uid,
            modDateRaw: modDate.map { "\($0)" },
            modDate: modDate,
            multicam: mc,
            location: location
        )
    }

    // MARK: Fixture-driven positive case

    func testMergedFixturesReportOneFindingWithThreeMasters() throws {
        let doc = try mergedDocument([
            "orig_multicam.fcpxmld",
            "duplet1_multicam.fcpxmld",
            "duplet2_multicam.fcpxmld"
        ])

        let findings = MulticamDuplicationCheck().run(on: doc)
        XCTAssertEqual(findings.count, 1, "expected a single grouped finding")

        let finding = try XCTUnwrap(findings.first)
        XCTAssertEqual(finding.severity, .warning)
        XCTAssertEqual(finding.checkID, "multicam-duplication")
        XCTAssertEqual(finding.location.count, 3, "all three media locations should be attached")

        // ORIG has the newest modDate → is the authoritative master.
        XCTAssertTrue(
            finding.description.contains("bE6PqP2TRO2D7xuONhMJQA"),
            "ORIG UID should appear in finding"
        )
        XCTAssertTrue(
            finding.description.contains("ARyUeB2ORCmRpTpliivHNw"),
            "duplet1 UID should appear"
        )
        XCTAssertTrue(
            finding.description.contains("7OzQq5dhQMqEH8dQ1DKfvQ"),
            "duplet2 UID should appear"
        )

        // Authoritative master comes before either ghost in the text.
        let origRange = try XCTUnwrap(finding.description.range(of: "bE6PqP2TRO2D7xuONhMJQA"))
        let ghost1Range = try XCTUnwrap(finding.description.range(of: "ARyUeB2ORCmRpTpliivHNw"))
        let ghost2Range = try XCTUnwrap(finding.description.range(of: "7OzQq5dhQMqEH8dQ1DKfvQ"))
        XCTAssertLessThan(origRange.lowerBound, ghost1Range.lowerBound)
        XCTAssertLessThan(origRange.lowerBound, ghost2Range.lowerBound)
    }

    // MARK: Edge cases

    func testSingleMulticamYieldsNoFinding() {
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [makeMedia(
                id: "r1",
                uid: "OnlyOne",
                name: "solo",
                modDate: Date(),
                angleIDs: ["a", "b", "c"]
            )]
        )
        XCTAssertTrue(MulticamDuplicationCheck().run(on: doc).isEmpty)
    }

    func testTwoMulticamsWithIdenticalUIDYieldNoFinding() {
        // Same UID means they're the same master referenced twice, not ghosts.
        let date = Date()
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [
                makeMedia(id: "r1", uid: "Same", name: "a", modDate: date, angleIDs: ["a", "b"]),
                makeMedia(id: "r2", uid: "Same", name: "b", modDate: date, angleIDs: ["a", "b"])
            ]
        )
        XCTAssertTrue(MulticamDuplicationCheck().run(on: doc).isEmpty)
    }

    func testMulticamsWithDisjointAngleIDsYieldNoFinding() {
        let date = Date()
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [
                makeMedia(id: "r1", uid: "U1", name: "a", modDate: date, angleIDs: ["a", "b"]),
                makeMedia(id: "r2", uid: "U2", name: "b", modDate: date, angleIDs: ["c", "d"])
            ]
        )
        XCTAssertTrue(MulticamDuplicationCheck().run(on: doc).isEmpty)
    }

    func testAuthoritativeMasterIsNewestModDate() {
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_800_000_000)
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [
                makeMedia(id: "r1", uid: "Ghost", name: "ghost", modDate: older, angleIDs: ["a"]),
                makeMedia(id: "r2", uid: "Master", name: "master", modDate: newer, angleIDs: ["a"])
            ]
        )
        let findings = MulticamDuplicationCheck().run(on: doc)
        XCTAssertEqual(findings.count, 1)
        let desc = findings[0].description
        // "Master" UID appears before "Ghost" UID in the rendered body.
        guard let mRange = desc.range(of: "Master"),
              let gRange = desc.range(of: "Ghost") else {
            return XCTFail("UIDs missing from finding body")
        }
        XCTAssertLessThan(mRange.lowerBound, gRange.lowerBound)
    }

    func testEmptyFingerprintDoesNotTrigger() {
        // Two media objects with <multicam> but no angles shouldn't get grouped.
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [
                makeMedia(id: "r1", uid: "U1", name: "a", modDate: Date(), angleIDs: []),
                makeMedia(id: "r2", uid: "U2", name: "b", modDate: Date(), angleIDs: [])
            ]
        )
        XCTAssertTrue(MulticamDuplicationCheck().run(on: doc).isEmpty)
    }
}
