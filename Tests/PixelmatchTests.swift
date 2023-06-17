import XCTest
import SwiftPixelmatch

func openImage(_ name: String) -> CGImage {
    let referenceData = CGDataProvider(
        url: Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Resources")! as CFURL
    )!

    return CGImage(
        pngDataProviderSource: referenceData,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    )!
}

final class PixelmatchTests: XCTestCase {
    func testDiff() throws {
        let reference = openImage("1_reference")
        let test = openImage("1_test")

        Pixelmatch.configuration.threshold = 0.05

        if case let .differentPixels(pixelsCount, _) = Pixelmatch.compare(
            referenceImage: reference,
            testImage: test
        ) {
            XCTAssertEqual(pixelsCount, 143)
        } else {
            XCTFail("Invalid comparison verdict")
        }
    }
}
