import XCTest
@testable import FCPInspectCore

final class RationalTests: XCTestCase {

    func testParsesIntegerSeconds() throws {
        let r = try Rational.parse("1800s")
        XCTAssertEqual(r.numerator, 1800)
        XCTAssertEqual(r.denominator, 1)
    }

    func testParsesFractionalSeconds() throws {
        let r = try Rational.parse("958072/25s")
        XCTAssertEqual(r.numerator, 958072)
        XCTAssertEqual(r.denominator, 25)
    }

    func testParsesSubFrameFraction() throws {
        let r = try Rational.parse("100/2500s")
        XCTAssertEqual(r.numerator, 100)
        XCTAssertEqual(r.denominator, 2500)
    }

    func testParsesZero() throws {
        let r = try Rational.parse("0s")
        XCTAssertEqual(r, Rational(numerator: 0))
    }

    func testParseRejectsEmpty() {
        XCTAssertThrowsError(try Rational.parse("s"))
        XCTAssertThrowsError(try Rational.parse(""))
    }

    func testParseRejectsGarbage() {
        XCTAssertThrowsError(try Rational.parse("abc/123s"))
        XCTAssertThrowsError(try Rational.parse("12/xys"))
        XCTAssertThrowsError(try Rational.parse("12/0s"))
    }

    func testComparableDoesNotLoseFractionPrecision() throws {
        // 100/2500 == 1/25 but neither is simplified, and comparison must
        // still work via cross-multiplication without overflow for the
        // values FCPXML actually produces.
        let a = try Rational.parse("100/2500s")
        let b = try Rational.parse("1/25s")
        XCTAssertFalse(a < b)
        XCTAssertFalse(b < a)
    }

    func testDescriptionRoundtrips() throws {
        XCTAssertEqual(try Rational.parse("1800s").description, "1800s")
        XCTAssertEqual(try Rational.parse("958072/25s").description, "958072/25s")
    }
}
