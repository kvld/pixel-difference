import Foundation

public struct Image {
    public let bytes: Data
    public let size: Size

    public var width: Int { size.width }
    public var height: Int { size.height }

    public init(bytes: Data, size: Size) {
        self.bytes = bytes
        self.size = size
    }
}

extension Image {
    func asPixelBuffer() -> PixelBuffer {
        var pixels = PixelBuffer.ofSize(size)

        var offset = 0
        var y = 0
        var x = 0

        while y < height {
            x = 0

            while x < width {
                pixels[y, x] = PixelRGBA(
                    red: bytes[offset],
                    green: bytes[offset + 1],
                    blue: bytes[offset + 2],
                    alpha: bytes[offset + 3]
                )

                offset += 4
                x += 1
            }

            y += 1
        }

        return pixels
    }
}
