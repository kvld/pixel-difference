import XCTest
import PixelDifference

func openImage(_ name: String) throws -> CGImage {
    let time = CFAbsoluteTimeGetCurrent()

    let url = try XCTUnwrap(Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Resources"))
    let referenceData = try XCTUnwrap(CGDataProvider(url: url as CFURL))

    defer {
        print("image parsing time: \(CFAbsoluteTimeGetCurrent() - time)")
    }

    return try XCTUnwrap(
        CGImage(
            pngDataProviderSource: referenceData,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    )
}

final class PixelDifferenceTests: XCTestCase {
    func testDiffSmall() throws {
        let reference = try openImage("1_reference")
        let test = try openImage("1_test")

        let referenceBytes = try XCTUnwrap(reference.dataProvider?.data) as Data
        let testBytes = try XCTUnwrap(test.dataProvider?.data) as Data

        let result = PixelDifference.compare(
            referenceImage: .init(
                bytes: referenceBytes,
                size: .init(width: reference.width, height: reference.height)
            ),
            testImage: .init(
                bytes: testBytes,
                size: .init(width: test.width, height: test.height)
            )
        )

        if case let .differentPixels(pixelsCount) = result.verdict {
            XCTAssertEqual(pixelsCount, 143)
        } else {
            XCTFail("Invalid comparison verdict")
        }
    }

    func testDiffLarge() throws {
        let reference = try openImage("2_reference")
        let test = try openImage("2_test")

        let referenceBytes = try XCTUnwrap(reference.dataProvider?.data) as Data
        let testBytes = try XCTUnwrap(test.dataProvider?.data) as Data

        let result = PixelDifference.compare(
            referenceImage: .init(
                bytes: referenceBytes,
                size: .init(width: reference.width, height: reference.height)
            ),
            testImage: .init(
                bytes: testBytes,
                size: .init(width: test.width, height: test.height)
            )
        )

        if case let .differentPixels(pixelsCount) = result.verdict {
            XCTAssertEqual(pixelsCount, 13)
        } else {
            XCTFail("Invalid comparison verdict")
        }
    }
}
