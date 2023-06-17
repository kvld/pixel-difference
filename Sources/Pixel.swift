import CoreGraphics
import Foundation

struct PixelRGBA: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    static var clear: PixelRGBA {
        .init(red: 0, green: 0, blue: 0, alpha: 0)
    }
}

typealias PixelBuffer = [[PixelRGBA]]

extension CGImage {
    static func make(from buffer: PixelBuffer) -> CGImage? {
        var bytes: [UInt8] = []
        for row in buffer {
            for pixel in row {
                bytes.append(contentsOf: [pixel.red, pixel.green, pixel.blue, pixel.alpha])
            }
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let provider = CGDataProvider(data: Data(bytes) as CFData) else {
            return nil
        }

        return CGImage(
            width: buffer[0].count,
            height: buffer.count,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: 4 * buffer[0].count,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        )
    }

    func asPixelBuffer() -> PixelBuffer? {
        guard let buffer = self.dataProvider?.data as? Data else {
            return nil
        }

        var pixels = PixelBuffer()

        var offset = 0
        for _ in 0..<height {
            var row: [PixelRGBA] = []

            for _ in 0..<width {
                row.append(
                    PixelRGBA(
                        red: buffer[offset],
                        green: buffer[offset + 1],
                        blue: buffer[offset + 2],
                        alpha: buffer[offset + 3]
                    )
                )
                offset += 4
            }

            pixels.append(row)
        }

        return pixels
    }
}

extension CGColor {
    func asPixel() -> PixelRGBA {
        let color = converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil) ?? self

        guard let components = color.components else {
            return .clear
        }

        return .init(
            red: UInt8(components[0] * 255),
            green: UInt8(components[1] * 255),
            blue: UInt8(components[2] * 255),
            alpha: UInt8(components[3] * 255)
        )
    }
}
