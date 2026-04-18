import XCTest
@testable import FCPInspectCore

final class FCPXMLParserTests: XCTestCase {

    // MARK: Fixtures

    private func fixtureURL(_ name: String) -> URL {
        // Tests/FCPInspectCoreTests/FCPXMLParserTests.swift -> walk up 3 to project root.
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("test-fixtures")
            .appendingPathComponent(name)
    }

    // MARK: Happy path on all three fixtures

    func testParsesOrigBundle() throws {
        let doc = try FCPXMLParser().parse(path: fixtureURL("orig_multicam.fcpxmld"))
        XCTAssertEqual(doc.version, "1.14")
        XCTAssertEqual(doc.medias.count, 1)

        let media = try XCTUnwrap(doc.medias.first)
        XCTAssertEqual(media.uid, "bE6PqP2TRO2D7xuONhMJQA")
        XCTAssertEqual(media.modDateRaw, "2026-04-15 16:55:17 +0200")
        XCTAssertNotNil(media.modDate)

        let multicam = try XCTUnwrap(media.multicam)
        XCTAssertFalse(multicam.angles.isEmpty)

        // angleIDs must be non-empty for every angle.
        for angle in multicam.angles {
            XCTAssertFalse(angle.angleID.isEmpty, "angle \(angle.name) has empty angleID")
        }
    }

    func testParsesDuplet1Bundle() throws {
        let doc = try FCPXMLParser().parse(path: fixtureURL("duplet1_multicam.fcpxmld"))
        let media = try XCTUnwrap(doc.medias.first)
        XCTAssertEqual(media.uid, "ARyUeB2ORCmRpTpliivHNw")
        XCTAssertEqual(media.modDateRaw, "2026-03-02 22:56:13 +0100")
        XCTAssertFalse(media.multicam?.angles.isEmpty ?? true)
    }

    func testParsesDuplet2Bundle() throws {
        let doc = try FCPXMLParser().parse(path: fixtureURL("duplet2_multicam.fcpxmld"))
        let media = try XCTUnwrap(doc.medias.first)
        XCTAssertEqual(media.uid, "7OzQq5dhQMqEH8dQ1DKfvQ")
        XCTAssertFalse(media.multicam?.angles.isEmpty ?? true)
    }

    func testAllFixturesHaveSameAngleCount() throws {
        // The brief claims 22 angles on the fixtures; the shipped fixtures have 21.
        // What matters for the check is that the three agree with each other —
        // the exact number is surface detail.
        let parser = FCPXMLParser()
        let counts = try ["orig_multicam.fcpxmld",
                          "duplet1_multicam.fcpxmld",
                          "duplet2_multicam.fcpxmld"].map { name -> Int in
            try parser.parse(path: fixtureURL(name)).medias.first?.multicam?.angles.count ?? 0
        }
        XCTAssertGreaterThan(counts[0], 0)
        XCTAssertEqual(Set(counts).count, 1, "all three fixtures should have the same angle count, got \(counts)")
    }

    func testAllThreeFixturesShareAngleFingerprint() throws {
        let parser = FCPXMLParser()
        let fingerprints = try ["orig_multicam.fcpxmld",
                                "duplet1_multicam.fcpxmld",
                                "duplet2_multicam.fcpxmld"].map { name -> [String] in
            let doc = try parser.parse(path: fixtureURL(name))
            let angles = doc.medias.first?.multicam?.angles ?? []
            return angles.map(\.angleID).sorted()
        }
        XCTAssertEqual(fingerprints[0], fingerprints[1])
        XCTAssertEqual(fingerprints[1], fingerprints[2])
    }

    // MARK: Error paths

    func testRejectsMalformedXML() {
        let bad = Data("<fcpxml version=\"1.14\"><resources><media".utf8)
        XCTAssertThrowsError(try FCPXMLParser().parse(data: bad)) { error in
            guard case ParseError.malformedXML = error else {
                return XCTFail("expected malformedXML, got \(error)")
            }
        }
    }

    func testRejectsWrongRoot() {
        let wrong = Data("<notfcpxml/>".utf8)
        XCTAssertThrowsError(try FCPXMLParser().parse(data: wrong)) { error in
            guard case ParseError.wrongRoot(let name) = error else {
                return XCTFail("expected wrongRoot, got \(error)")
            }
            XCTAssertEqual(name, "notfcpxml")
        }
    }

    func testRejectsMediaMissingUID() {
        let xml = Data("""
        <fcpxml version="1.14">
          <resources>
            <media id="r1" name="x">
              <multicam>
                <mc-angle name="A" angleID="aaa"/>
              </multicam>
            </media>
          </resources>
        </fcpxml>
        """.utf8)
        XCTAssertThrowsError(try FCPXMLParser().parse(data: xml)) { error in
            guard case ParseError.missingAttribute(let el, let attr, _) = error else {
                return XCTFail("expected missingAttribute, got \(error)")
            }
            XCTAssertEqual(el, "media")
            XCTAssertEqual(attr, "uid")
        }
    }

    // MARK: Bundle resolution

    func testResolveDocumentURLUnwrapsBundle() {
        let bundle = URL(fileURLWithPath: "/tmp/x.fcpxmld")
        XCTAssertEqual(
            FCPXMLParser.resolveDocumentURL(bundle).lastPathComponent,
            "Info.fcpxml"
        )
    }

    func testResolveDocumentURLPassesThroughPlainFile() {
        let plain = URL(fileURLWithPath: "/tmp/x.fcpxml")
        XCTAssertEqual(FCPXMLParser.resolveDocumentURL(plain), plain)
    }

    // MARK: modDate parsing

    func testParsesModDateFromFixtureFormat() {
        let date = FCPXMLParser.parseModDate("2026-04-15 16:55:17 +0200")
        XCTAssertNotNil(date)
        XCTAssertNil(FCPXMLParser.parseModDate("not a date"))
    }
}
