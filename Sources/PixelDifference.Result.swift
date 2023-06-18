import Foundation

#if canImport(Darwin)
import CoreGraphics
#endif

extension PixelDifference {
    /// Result of images comparison
    public struct Result {
        public let verdict: Verdict
        public var difference: DifferenceImage?
    }
}

extension PixelDifference.Result {
    public enum Verdict {
        case differentSize
        case differentPixels(pixelsCount: Int)
        case equal
    }

    public struct DifferenceImage {
        let buffer: PixelBuffer

        #if canImport(Darwin)
        public var cgImage: CGImage? {
            CGImage.make(from: buffer)
        }
        #endif

        public var bytes: Data {
            .init(buffer.bytes.flatMap(\.components))
        }
    }
}
