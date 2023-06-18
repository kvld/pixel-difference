import Foundation

struct PixelRGBA: Equatable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    static var clear: PixelRGBA {
        .init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    var components: [UInt8] {
        [red, green, blue, alpha]
    }
}

struct PixelBuffer: Equatable {
    private(set) var bytes: [PixelRGBA]
    let size: Size

    subscript(_ row: Int, _ column: Int) -> PixelRGBA {
        get {
            bytes[row * size.width + column]
        }
        set {
            bytes[row * size.width + column] = newValue
        }
    }

    static func == (lhs: PixelBuffer, rhs: PixelBuffer) -> Bool {
        lhs.bytes == rhs.bytes
    }

    static func ofSize(_ size: Size) -> PixelBuffer {
        PixelBuffer(bytes: .init(repeating: .clear, count: size.width * size.height), size: size)
    }
}
