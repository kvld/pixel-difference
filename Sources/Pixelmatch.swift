import Foundation
import CoreGraphics

public struct PixelmatchConfiguration {
    /// matching threshold (0 to 1); smaller is more sensitive
    public var threshold: Double
    /// whether to skip anti-aliasing detection
    public var includeAA: Bool
    /// opacity of original image in diff output
    public var alpha: Double
    /// color of anti-aliased pixels in diff output
    public var aaColor: CGColor
    /// color of different pixels in diff output
    public var diffColor: CGColor
    /// whether to detect dark on light differences between img1 and img2 and set an alternative color to differentiate between the two
    public var diffColorAlt: CGColor?
    /// draw the diff over a transparent background (a mask)
    public var diffMask: Bool
    /// diff mask background
    public var diffMaskBackground: CGColor

    public init(
        threshold: Double = 0.1,
        includeAA: Bool = false,
        alpha: Double = 0.1,
        aaColor: CGColor = .init(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),
        diffColor: CGColor = .init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
        diffColorAlt: CGColor? = nil,
        diffMask: Bool = false,
        diffMaskBackground: CGColor = .init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
    ) {
        self.threshold = threshold
        self.includeAA = includeAA
        self.alpha = alpha
        self.aaColor = aaColor
        self.diffColor = diffColor
        self.diffColorAlt = diffColorAlt
        self.diffMask = diffMask
        self.diffMaskBackground = diffMaskBackground
    }
}

public enum ComparisonVerdict {
    case differentSize
    case differentPixels(pixelsCount: Int, difference: CGImage?)
    case equal
}

public enum Pixelmatch {
    public static var configuration = PixelmatchConfiguration()

    public static func compare(referenceImage: CGImage, testImage: CGImage) -> ComparisonVerdict? {
        guard referenceImage.width == testImage.width, referenceImage.height == testImage.height else {
            return .differentSize
        }

        let referenceBuffer = referenceImage.asPixelBuffer()
        let testBuffer = testImage.asPixelBuffer()

        guard let referenceBuffer, let testBuffer else {
            return nil
        }

        if referenceBuffer == testBuffer {
            return .equal
        }

        // maximum acceptable square distance between two colors;
        // 35215 is the maximum possible value for the YIQ difference metric
        let maxDelta = 35215 * configuration.threshold * configuration.threshold

        var diffCount = 0
        var diff = PixelBuffer(
            repeating: [PixelRGBA](
                repeating: configuration.diffMaskBackground.asPixel(),
                count: referenceBuffer[0].count
            ),
            count: referenceBuffer.count
        )

        for y in 0..<referenceImage.height {
            for x in 0..<referenceImage.width {
                let p1 = referenceBuffer[y][x]
                let p2 = testBuffer[y][x]

                let delta = p1.colorDelta(with: p2, yOnly: false)

                if abs(delta) > maxDelta {
                    // check difference kind – antialiasing or true pixel difference
                    if !configuration.includeAA,
                        (checkAntialiasing(firstImage: referenceBuffer, secondImage: testBuffer, x: x, y: y)
                         || checkAntialiasing(firstImage: testBuffer, secondImage: referenceBuffer, x: x, y: y)) {
                        diff[y][x] = configuration.aaColor.asPixel()
                    } else {
                        diffCount += 1

                        if let diffAltColor = configuration.diffColorAlt, delta < 0 {
                            diff[y][x] = diffAltColor.asPixel()
                        } else {
                            diff[y][x] = configuration.diffColor.asPixel()
                        }
                    }
                } else {
                    // pixels are similar, there is no difference
                    if !configuration.diffMask {
                        diff[y][x] = p1.grayed(resultAlpha: configuration.alpha)
                    }
                }
            }
        }

        return .differentPixels(pixelsCount: diffCount, difference: CGImage.make(from: diff))
    }

    // Check if a pixel is likely a part of anti-aliasing;
    // based on "Anti-aliased Pixel and Intensity Slope Detector" paper by V. Vysniauskas, 2009
    private static func checkAntialiasing(firstImage: PixelBuffer, secondImage: PixelBuffer, x: Int, y: Int) -> Bool {
        let firstX = max(x - 1, 0)
        let lastX = min(x + 1, firstImage[0].count - 1)

        let firstY = max(y - 1, 0)
        let lastY = min(y + 1, firstImage.count - 1)

        var zeroes = firstX == x || x == lastX || firstY == y || lastY == y ? 1 : 0

        var darkestPixel: (x: Int, y: Int)?
        var darkestDelta: Double = 0

        var brightestPixel: (x: Int, y: Int)?
        var brightestDelta: Double = 0

        for _x in firstX...lastX {
            for _y in firstY...lastY {
                if _x == x, _y == y {
                    continue
                }

                // brightness delta between the center pixel and adjacent one
                let delta = firstImage[y][x].colorDelta(with: firstImage[_y][_x], yOnly: false)

                if delta.isZero {
                    zeroes += 1
                    // if found more than 2 equal siblings, it's definitely not anti-aliasing
                    if zeroes > 2 {
                        return false
                    }
                } else if delta < darkestDelta {
                    darkestDelta = delta
                    darkestPixel = (_x, _y)
                } else if delta > brightestDelta {
                    brightestDelta = delta
                    brightestPixel = (_x, _y)
                }
            }
        }

        // if there are no both darker and brighter pixels among siblings, it's not anti-aliasing
        guard let darkestPixel, let brightestPixel else {
            return false
        }

        // if either the darkest or the brightest pixel has 3+ equal siblings in both images
        // (definitely not anti-aliased), this pixel is anti-aliased
        let hasDarkestSiblings = checkSiblings(image: firstImage, x: darkestPixel.x, y: darkestPixel.y)
            && checkSiblings(image: secondImage, x: darkestPixel.x, y: darkestPixel.y)

        let hasBrightestSiblings = checkSiblings(image: firstImage, x: brightestPixel.x, y: brightestPixel.y)
            && checkSiblings(image: secondImage, x: brightestPixel.x, y: brightestPixel.y)

        return hasDarkestSiblings || hasBrightestSiblings
    }

    private static func checkSiblings(image: PixelBuffer, x: Int, y: Int) -> Bool {
        let firstX = max(x - 1, 0)
        let lastX = min(x + 1, image[0].count - 1)

        let firstY = max(y - 1, 0)
        let lastY = min(y + 1, image.count - 1)

        var zeroes = firstX == x || x == lastX || firstY == y || lastY == y ? 1 : 0

        for _x in firstX...lastX {
            for _y in firstY...lastY {
                if _x == x, _y == y {
                    continue
                }

                if image[y][x] == image[_y][_x] {
                    zeroes += 1
                }

                if zeroes > 2 {
                    return true
                }
            }
        }

        return false
    }
}

extension PixelRGBA {
    var rgb2y: Double {
        Double(red) * 0.29889531 + Double(green) * 0.58662247 + Double(blue) * 0.11448223
    }

    var rgb2i: Double {
        Double(red) * 0.59597799 - Double(green) * 0.27417610 - Double(blue) * 0.32180189
    }

    var rgb2q: Double {
        Double(red) * 0.21147017 - Double(green) * 0.52261711 + Double(blue) * 0.31114694
    }

    func blended() -> PixelRGBA {
        let alpha: Double = Double(alpha) / 255
        let red = 255 + (Double(red) - 255) * alpha
        let green = 255 + (Double(green) - 255) * alpha
        let blue = 255 + (Double(blue) - 255) * alpha

        return .init(red: UInt8(red), green: UInt8(green), blue: UInt8(blue), alpha: 255)
    }

    func grayed(resultAlpha: Double) -> PixelRGBA {
        let component = 255.0 + (rgb2y - 255.0) * (Double(alpha) / 255.0) * resultAlpha
        return .init(red: UInt8(component), green: UInt8(component), blue: UInt8(component), alpha: 255)
    }

    // calculate color difference according to the paper "Measuring perceived color difference
    // using YIQ NTSC transmission color space in mobile applications" by Y. Kotsarenko and F. Ramos
    func colorDelta(with pixel: PixelRGBA, yOnly: Bool) -> Double {
        if self == pixel {
            return 0
        }

        let blendedPixel1 = blended()
        let blendedPixel2 = pixel.blended()

        let y1 = blendedPixel1.rgb2y
        let y2 = blendedPixel2.rgb2y

        let y = y1 - y2

        if yOnly {
            return y
        }

        let i = blendedPixel1.rgb2i - blendedPixel2.rgb2i
        let q = blendedPixel1.rgb2q - blendedPixel2.rgb2q

        let delta = 0.5053 * y * y + 0.299 * i * i + 0.1957 * q * q

        return y1 > y2 ? -delta : delta
    }
}
