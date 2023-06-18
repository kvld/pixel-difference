#if canImport(Darwin)
import CoreGraphics
import Foundation

extension CGImage {
    static func make(from buffer: PixelBuffer) -> CGImage? {
        var bytes: [UInt8] = []
        for pixel in buffer.bytes {
            bytes.append(contentsOf: pixel.components)
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else {
            return nil
        }
        
        return CGImage(
            width: buffer.size.width,
            height: buffer.size.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4 * buffer.size.width,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }
}
#endif
