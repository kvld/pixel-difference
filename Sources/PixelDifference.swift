import Foundation

public enum PixelDifference {
    public static var configuration = Configuration.default

    public static func compare(
        referenceImage: Image,
        testImage: Image
    ) -> Result {
        let time = CFAbsoluteTimeGetCurrent()

        guard referenceImage.width == testImage.width, referenceImage.height == testImage.height else {
            return .init(verdict: .differentSize)
        }

        let referenceBuffer = referenceImage.asPixelBuffer()
        let testBuffer = testImage.asPixelBuffer()

        if referenceBuffer == testBuffer {
            return .init(verdict: .equal)
        }

        // Maximum square distance between two colors, 35215 – max of Kotsarenko/Ramos YIQ diff metric
        let maxDelta = 35215 * configuration.threshold * configuration.threshold

        var diffCount = 0
        var diff = PixelBuffer.ofSize(referenceImage.size)

        var y = 0
        var x = 0

        while y < referenceImage.height {
            x = 0

            while x < referenceImage.width {
                let p1 = referenceBuffer[y, x]
                let p2 = testBuffer[y, x]

                let delta = p1.colorDelta(with: p2, yOnly: false)

                if abs(delta) > maxDelta {
                    if !configuration.shouldIgnoreAntialiasing,
                        (checkAntialiasing(firstImage: referenceBuffer, secondImage: testBuffer, x: x, y: y)
                         || checkAntialiasing(firstImage: testBuffer, secondImage: referenceBuffer, x: x, y: y)) {
                        diff[y, x] = configuration.diffColors.antialiasedPixelColor.pixel
                    } else {
                        diffCount += 1

                        diff[y, x] = delta < 0
                            ? configuration.diffColors.darkerPixelColor.pixel
                            : configuration.diffColors.brighterPixelColor.pixel
                    }
                } else {
                    if !configuration.drawDiffMask {
                        diff[y, x] = p1.grayed(resultAlpha: configuration.originalImageAlpha)
                    }
                }
                x += 1
            }
            y += 1
        }

        if diffCount == 0 {
            return .init(verdict: .equal)
        }

        return .init(
            verdict: .differentPixels(pixelsCount: diffCount),
            difference: .init(buffer: diff)
        )
    }

    // Check antialiased pixels
    // according to the paper "Anti-aliased Pixel and Intensity Slope Detector" by V. Vysniauskas
    private static func checkAntialiasing(firstImage: PixelBuffer, secondImage: PixelBuffer, x: Int, y: Int) -> Bool {
        let firstX = max(x - 1, 0)
        let lastX = min(x + 1, firstImage.size.width - 1)

        let firstY = max(y - 1, 0)
        let lastY = min(y + 1, firstImage.size.height - 1)

        var siblings = firstX == x || x == lastX || firstY == y || lastY == y ? 1 : 0

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
                let delta = firstImage[y, x].colorDelta(with: firstImage[_y, _x], yOnly: false)

                if delta.isZero {
                    siblings += 1
                    // if found more than 2 equal siblings, it's definitely not anti-aliasing
                    if siblings > 2 {
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
        let hasDarkestSiblings = checkEqualSiblings(image: firstImage, x: darkestPixel.x, y: darkestPixel.y)
            && checkEqualSiblings(image: secondImage, x: darkestPixel.x, y: darkestPixel.y)

        let hasBrightestSiblings = checkEqualSiblings(image: firstImage, x: brightestPixel.x, y: brightestPixel.y)
            && checkEqualSiblings(image: secondImage, x: brightestPixel.x, y: brightestPixel.y)

        return hasDarkestSiblings || hasBrightestSiblings
    }

    private static func checkEqualSiblings(image: PixelBuffer, x: Int, y: Int) -> Bool {
        let firstX = max(x - 1, 0)
        let lastX = min(x + 1, image.size.width - 1)

        let firstY = max(y - 1, 0)
        let lastY = min(y + 1, image.size.height - 1)

        var siblings = firstX == x || x == lastX || firstY == y || lastY == y ? 1 : 0

        for _x in firstX...lastX {
            for _y in firstY...lastY {
                if _x == x, _y == y {
                    continue
                }

                if image[y, x] == image[_y, _x] {
                    siblings += 1
                }

                if siblings > 2 {
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

    // Color difference according to the paper "Measuring perceived color difference using YIQ NTSC
    // transmission color space in mobile applications" by Y. Kotsarenko and F. Ramos
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
