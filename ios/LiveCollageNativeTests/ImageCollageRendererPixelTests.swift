import CoreGraphics
import UIKit

@main
struct ImageCollageRendererPixelTests {
    static func main() throws {
        try testHorizontalJoinClipsEachImageToItsColumn()
        try testVerticalJoinClipsEachImageToItsRow()
        try testLongHorizontalJoinExtendsTheCanvas()
        try testLongVerticalJoinExtendsTheCanvas()
        testImageOrientationNormalizationAppliesMirroringMetadata()
        testImageOrientationNormalizationAppliesVerticalOrientationMetadata()
        print("ImageCollageRendererPixelTests passed")
    }

    private static func testHorizontalJoinClipsEachImageToItsColumn() throws {
        let image = try ImageCollageRenderer.join(
            images: [
                solidImage(.red, size: CGSize(width: 1000, height: 100)),
                solidImage(.green, size: CGSize(width: 1000, height: 100)),
                solidImage(.blue, size: CGSize(width: 1000, height: 100)),
            ],
            mode: .horizontal,
            tileSize: 300
        )

        let left = sample(image, at: CGPoint(x: 50, y: 150))
        let middle = sample(image, at: CGPoint(x: 150, y: 150))
        let right = sample(image, at: CGPoint(x: 250, y: 150))

        expect(left.isClose(to: .red), "left column should stay red, got \(left)")
        expect(middle.isClose(to: .green), "middle column should stay green, got \(middle)")
        expect(right.isClose(to: .blue), "right column should stay blue, got \(right)")
    }

    private static func testVerticalJoinClipsEachImageToItsRow() throws {
        let image = try ImageCollageRenderer.join(
            images: [
                solidImage(.red, size: CGSize(width: 100, height: 1000)),
                solidImage(.green, size: CGSize(width: 100, height: 1000)),
                solidImage(.blue, size: CGSize(width: 100, height: 1000)),
            ],
            mode: .vertical,
            tileSize: 300
        )

        let top = sample(image, at: CGPoint(x: 150, y: 50))
        let middle = sample(image, at: CGPoint(x: 150, y: 150))
        let bottom = sample(image, at: CGPoint(x: 150, y: 250))

        expect(top.isClose(to: .red), "top row should stay red, got \(top)")
        expect(middle.isClose(to: .green), "middle row should stay green, got \(middle)")
        expect(bottom.isClose(to: .blue), "bottom row should stay blue, got \(bottom)")
    }

    private static func testLongHorizontalJoinExtendsTheCanvas() throws {
        let image = try ImageCollageRenderer.join(
            images: [solidImage(.red), solidImage(.green), solidImage(.blue)],
            mode: .horizontal,
            canvasStyle: .long,
            tileSize: 100
        )

        expect(image.size == CGSize(width: 300, height: 100), "horizontal long join should extend its width")
        expect(sample(image, at: CGPoint(x: 50, y: 50)).isClose(to: .red), "first long tile should stay red")
        expect(sample(image, at: CGPoint(x: 150, y: 50)).isClose(to: .green), "second long tile should stay green")
        expect(sample(image, at: CGPoint(x: 250, y: 50)).isClose(to: .blue), "third long tile should stay blue")
    }

    private static func testLongVerticalJoinExtendsTheCanvas() throws {
        let image = try ImageCollageRenderer.join(
            images: [solidImage(.red), solidImage(.green), solidImage(.blue)],
            mode: .vertical,
            canvasStyle: .long,
            tileSize: 100
        )

        expect(image.size == CGSize(width: 100, height: 300), "vertical long join should extend its height")
        expect(sample(image, at: CGPoint(x: 50, y: 50)).isClose(to: .red), "first long tile should stay red")
        expect(sample(image, at: CGPoint(x: 50, y: 150)).isClose(to: .green), "second long tile should stay green")
        expect(sample(image, at: CGPoint(x: 50, y: 250)).isClose(to: .blue), "third long tile should stay blue")
    }

    private static func testImageOrientationNormalizationAppliesMirroringMetadata() {
        let source = stripedImage(left: .red, right: .blue)
        guard let cgImage = source.cgImage else {
            expect(false, "orientation fixture should expose a CGImage")
            return
        }

        let mirrored = UIImage(cgImage: cgImage, scale: 1, orientation: .upMirrored)
        let normalized = ImageOrientationNormalizer.normalized(mirrored)

        expect(normalized.imageOrientation == .up, "normalized images should remove orientation metadata")
        expect(sample(normalized, at: CGPoint(x: 0, y: 0)).isClose(to: .blue), "mirrored image should place blue on the left")
        expect(sample(normalized, at: CGPoint(x: 1, y: 0)).isClose(to: .red), "mirrored image should place red on the right")
    }

    private static func testImageOrientationNormalizationAppliesVerticalOrientationMetadata() {
        let source = stripedImage(top: .red, bottom: .blue)
        guard let cgImage = source.cgImage else {
            expect(false, "orientation fixture should expose a CGImage")
            return
        }

        let upsideDown = UIImage(cgImage: cgImage, scale: 1, orientation: .down)
        let normalized = ImageOrientationNormalizer.normalized(upsideDown)

        expect(normalized.imageOrientation == .up, "normalized images should remove vertical orientation metadata")
        expect(sample(normalized, at: CGPoint(x: 0, y: 0)).isClose(to: .blue), "down image should place blue on top")
        expect(sample(normalized, at: CGPoint(x: 0, y: 1)).isClose(to: .red), "down image should place red on bottom")
    }

    private static func stripedImage(left: UIColor, right: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 2, height: 1), format: format).image { context in
            left.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            right.setFill()
            context.fill(CGRect(x: 1, y: 0, width: 1, height: 1))
        }
    }

    private static func stripedImage(top: UIColor, bottom: UIColor) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: 1, height: 2), format: format).image { context in
            top.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
            bottom.setFill()
            context.fill(CGRect(x: 0, y: 1, width: 1, height: 1))
        }
    }

    private static func solidImage(_ color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private static func sample(_ image: UIImage, at point: CGPoint) -> SampledColor {
        guard let cgImage = image.cgImage,
              let cropped = cgImage.cropping(to: CGRect(x: Int(point.x), y: Int(point.y), width: 1, height: 1)) else {
            return SampledColor(red: 0, green: 0, blue: 0, alpha: 0)
        }

        var pixel = [UInt8](repeating: 0, count: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        pixel.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )

            context?.draw(cropped, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        return SampledColor(red: pixel[0], green: pixel[1], blue: pixel[2], alpha: pixel[3])
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("Test failed: \(message)\n", stderr)
            exit(1)
        }
    }
}

private struct SampledColor {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    func isClose(to color: UIColor) -> Bool {
        var expectedRed: CGFloat = 0
        var expectedGreen: CGFloat = 0
        var expectedBlue: CGFloat = 0
        var expectedAlpha: CGFloat = 0
        color.getRed(&expectedRed, green: &expectedGreen, blue: &expectedBlue, alpha: &expectedAlpha)

        return abs(Int(red) - Int(expectedRed * 255)) <= 2
            && abs(Int(green) - Int(expectedGreen * 255)) <= 2
            && abs(Int(blue) - Int(expectedBlue * 255)) <= 2
            && abs(Int(alpha) - Int(expectedAlpha * 255)) <= 2
    }
}
