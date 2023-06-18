public struct RGBColor {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double

    public init(
        red: Double,
        green: Double,
        blue: Double,
        alpha: Double
    ) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension RGBColor {
    public static var clear: RGBColor { .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0) }

    public static var red: RGBColor { .init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0) }

    public static var yellow: RGBColor { .init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) }
}

extension RGBColor {
    var pixel: PixelRGBA {
        .init(red: UInt8(red * 255), green: UInt8(green * 255), blue: UInt8(blue * 255), alpha: UInt8(alpha * 255))
    }
}
