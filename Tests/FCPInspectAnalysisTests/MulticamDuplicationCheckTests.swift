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

        // All three UIDs must be surfaced.
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

        // Oldest modDate comes first. The duplets are both 2026-03-02 and
        // ORIG is 2026-04-15, so a duplet UID appears before the ORIG UID.
        let origRange = try XCTUnwrap(finding.description.range(of: "bE6PqP2TRO2D7xuONhMJQA"))
        let ghost1Range = try XCTUnwrap(finding.description.range(of: "ARyUeB2ORCmRpTpliivHNw"))
        let ghost2Range = try XCTUnwrap(finding.description.range(of: "7OzQq5dhQMqEH8dQ1DKfvQ"))
        XCTAssertLessThan(ghost1Range.lowerBound, origRange.lowerBound)
        XCTAssertLessThan(ghost2Range.lowerBound, origRange.lowerBound)
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

    func testLikelyOriginalIsOldestModDate() {
        // Ghosts are born with a fresh modDate when FCP creates them during
        // match-frame. An untouched original keeps its ancient creation date.
        // So oldest modDate = likely original, newest = likely ghost.
        let older = Date(timeIntervalSince1970: 1_700_000_000)
        let newer = Date(timeIntervalSince1970: 1_800_000_000)
        let doc = FCPXMLDocument(
            version: "1.14",
            medias: [
                makeMedia(id: "r1", uid: "Original", name: "original", modDate: older, angleIDs: ["a"]),
                makeMedia(id: "r2", uid: "Ghost", name: "ghost", modDate: newer, angleIDs: ["a"])
            ]
        )
        let findings = MulticamDuplicationCheck().run(on: doc)
        XCTAssertEqual(findings.count, 1)
        let desc = findings[0].description
        guard let oRange = desc.range(of: "Original"),
              let gRange = desc.range(of: "Ghost") else {
            return XCTFail("UIDs missing from finding body")
        }
        XCTAssertLessThan(oRange.lowerBound, gRange.lowerBound,
                          "oldest modDate should be listed as likely original, first")
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
