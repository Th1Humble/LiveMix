import UIKit

enum ImageOrientationNormalizer {
    static func normalized(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up, image.scale == 1, image.cgImage != nil {
            return image
        }

        let pixelSize: CGSize
        if let cgImage = image.cgImage {
            let rawSize = CGSize(width: cgImage.width, height: cgImage.height)
            switch image.imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                pixelSize = CGSize(width: rawSize.height, height: rawSize.width)
            default:
                pixelSize = rawSize
            }
        } else {
            pixelSize = CGSize(
                width: max(1, image.size.width * image.scale),
                height: max(1, image.size.height * image.scale)
            )
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        format.preferredRange = .standard
        return UIGraphicsImageRenderer(size: pixelSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
        }
    }
}

enum ImageCollageRenderError: Error {
    case emptyInput
    case exportFailed
}

enum ImageCollageRenderer {
    static func join(
        images: [UIImage],
        edits: [NativeImageEdit] = [],
        mode: ImageJoinMode,
        canvasStyle: ImageJoinCanvasStyle = .square,
        tileSize: CGFloat = 1080
    ) throws -> UIImage {
        guard !images.isEmpty else {
            throw ImageCollageRenderError.emptyInput
        }

        let outputSize = ImageJoinLayout.outputSize(
            for: images.count,
            mode: mode,
            canvasStyle: canvasStyle,
            tileSize: tileSize
        )
        let resolvedEdits = NativeImageEdit.edits(edits, fitting: images.count)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: outputSize))

            for (index, image) in images.enumerated() {
                let tileRect = ImageJoinLayout.tileRect(
                    index: index,
                    imageCount: images.count,
                    mode: mode,
                    canvasStyle: canvasStyle,
                    tileSize: tileSize
                )
                context.cgContext.saveGState()
                context.cgContext.clip(to: tileRect)
                drawAspectFill(image, in: tileRect, edit: resolvedEdits[index])
                context.cgContext.restoreGState()
            }
        }
    }

    static func splitNine(
        image: UIImage,
        edit: NativeImageEdit = .default,
        tileSize: CGFloat = 1080
    ) throws -> [UIImage] {
        let canvasSize = CGSize(width: tileSize * 3, height: tileSize * 3)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let squareImage = UIGraphicsImageRenderer(size: canvasSize, format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: canvasSize))
            drawAspectFill(image, in: CGRect(origin: .zero, size: canvasSize), edit: edit)
        }

        return SplitNineLayout.tiles(in: canvasSize).map { rect in
            let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
            return renderer.image { _ in
                squareImage.draw(
                    at: CGPoint(x: -rect.origin.x, y: -rect.origin.y)
                )
            }
        }
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect, edit: NativeImageEdit) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let resolvedEdit = edit.clamped()
        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height) * resolvedEdit.zoom
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let overflowX = max(0, drawSize.width - rect.width)
        let overflowY = max(0, drawSize.height - rect.height)
        let drawOrigin = CGPoint(
            x: rect.minX - overflowX * resolvedEdit.focalX,
            y: rect.minY - overflowY * resolvedEdit.focalY
        )

        image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
    }
}
