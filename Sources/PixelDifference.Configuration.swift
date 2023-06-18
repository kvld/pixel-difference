import Foundation

extension PixelDifference {
    public struct Configuration {
        /// Threshold for comparison, must be in range [0;1], smaller is more sensitive
        public var threshold: Double

        /// Skip antialiased pixels while comparison
        public var shouldIgnoreAntialiasing: Bool

        /// Opacity of original image in diff image
        public var originalImageAlpha: Double

        /// Diff image colors
        public var diffColors: Colors

        /// Draw diff mask
        public var drawDiffMask: Bool

        public struct Colors {
            /// Color of anti-aliased pixels in diff image
            public var antialiasedPixelColor: RGBColor
            /// Color of pixel that is darker on the reference image than on the test
            public var darkerPixelColor: RGBColor
            /// Color of pixel that is brighter on the reference image than on the test
            public var brighterPixelColor: RGBColor
            /// Color of the mask if selected
            public var maskBackgroundColor: RGBColor

            public static var `default`: Colors {
                .init(
                    antialiasedPixelColor: .yellow,
                    darkerPixelColor: .red,
                    brighterPixelColor: .red,
                    maskBackgroundColor: .clear
                )
            }
        }

        public static var `default`: Configuration {
            .init(
                threshold: 0.05,
                shouldIgnoreAntialiasing: false,
                originalImageAlpha: 0.1,
                diffColors: .default,
                drawDiffMask: false
            )
        }
    }
}

