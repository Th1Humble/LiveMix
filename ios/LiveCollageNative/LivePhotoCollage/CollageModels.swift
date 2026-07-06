import CoreGraphics
import Foundation

struct CollageSlot: Hashable, Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat

    var rect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }
}

struct NativeCollageTemplate: Hashable, Identifiable {
    let id: String
    let name: String
    let detail: String
    let slots: [CollageSlot]

    static let liveTemplates: [NativeCollageTemplate] = [
        NativeCollageTemplate(
            id: "left-right",
            name: "左右",
            detail: "两段并排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.5, height: 1),
                CollageSlot(id: 1, x: 0.5, y: 0, width: 0.5, height: 1),
            ]
        ),
        NativeCollageTemplate(
            id: "top-bottom",
            name: "上下",
            detail: "两段叠放",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1, height: 0.5),
                CollageSlot(id: 1, x: 0, y: 0.5, width: 1, height: 0.5),
            ]
        ),
        NativeCollageTemplate(
            id: "three-columns",
            name: "三列",
            detail: "三段横排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1 / 3, height: 1),
                CollageSlot(id: 1, x: 1 / 3, y: 0, width: 1 / 3, height: 1),
                CollageSlot(id: 2, x: 2 / 3, y: 0, width: 1 / 3, height: 1),
            ]
        ),
        NativeCollageTemplate(
            id: "three-rows",
            name: "三行",
            detail: "三段竖排",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 1, height: 1 / 3),
                CollageSlot(id: 1, x: 0, y: 1 / 3, width: 1, height: 1 / 3),
                CollageSlot(id: 2, x: 0, y: 2 / 3, width: 1, height: 1 / 3),
            ]
        ),
        NativeCollageTemplate(
            id: "grid-2x2",
            name: "四宫格",
            detail: "四段网格",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.5, height: 0.5),
                CollageSlot(id: 1, x: 0.5, y: 0, width: 0.5, height: 0.5),
                CollageSlot(id: 2, x: 0, y: 0.5, width: 0.5, height: 0.5),
                CollageSlot(id: 3, x: 0.5, y: 0.5, width: 0.5, height: 0.5),
            ]
        ),
        NativeCollageTemplate(
            id: "one-big-two-small",
            name: "一大两小",
            detail: "主画面加两个小画面",
            slots: [
                CollageSlot(id: 0, x: 0, y: 0, width: 0.64, height: 1),
                CollageSlot(id: 1, x: 0.64, y: 0, width: 0.36, height: 0.5),
                CollageSlot(id: 2, x: 0.64, y: 0.5, width: 0.36, height: 0.5),
            ]
        ),
    ]
}

enum NativeFitMode: String, Hashable {
    case fill
    case fit
}

struct NativeSlotEdit: Hashable {
    static let minDuration: Double = 0.5
    static let maxDuration: Double = 3
    static let defaultZoom: CGFloat = 1
    static let maxZoom: CGFloat = 3
    static let `default` = NativeSlotEdit()

    var fitMode: NativeFitMode
    var focalX: CGFloat
    var focalY: CGFloat
    var zoom: CGFloat
    var start: Double
    var duration: Double

    init(
        fitMode: NativeFitMode = .fill,
        focalX: CGFloat = 0.5,
        focalY: CGFloat = 0.5,
        zoom: CGFloat = NativeSlotEdit.defaultZoom,
        start: Double = 0,
        duration: Double = NativeSlotEdit.maxDuration
    ) {
        self.fitMode = fitMode
        self.focalX = focalX
        self.focalY = focalY
        self.zoom = zoom
        self.start = start
        self.duration = duration
    }

    func clamped(maxStart: Double) -> NativeSlotEdit {
        NativeSlotEdit(
            fitMode: fitMode,
            focalX: Self.clamp(focalX, min: 0, max: 1),
            focalY: Self.clamp(focalY, min: 0, max: 1),
            zoom: Self.clamp(zoom, min: Self.defaultZoom, max: Self.maxZoom),
            start: Self.clamp(start, min: 0, max: max(0, maxStart)),
            duration: Self.normalizedDuration(duration)
        )
    }

    func withDuration(_ duration: Double) -> NativeSlotEdit {
        var edit = self
        edit.duration = Self.normalizedDuration(duration)
        return edit
    }

    static func normalizedDuration(_ value: Double) -> Double {
        guard value.isFinite else { return maxDuration }
        return clamp(value, min: minDuration, max: maxDuration)
    }

    static func outputDuration(for edits: [NativeSlotEdit]) -> Double {
        guard !edits.isEmpty else { return maxDuration }
        return edits.map { normalizedDuration($0.duration) }.min() ?? maxDuration
    }

    static func edits(_ edits: [NativeSlotEdit], fitting slotCount: Int) -> [NativeSlotEdit] {
        (0..<slotCount).map { index in
            index < edits.count ? edits[index] : .default
        }
    }

    private static func clamp<T: Comparable>(_ value: T, min minValue: T, max maxValue: T) -> T {
        Swift.min(Swift.max(value, minValue), maxValue)
    }
}

enum NativeSliderBounds {
    static func resolvedStep(_ step: Double) -> Double {
        step.isFinite && step > 0 ? step : 0.01
    }

    static func resolvedRange(lower: Double, upper: Double, step: Double) -> ClosedRange<Double> {
        let safeLower = lower.isFinite ? lower : 0
        let safeUpper = upper.isFinite ? upper : safeLower
        let safeStep = resolvedStep(step)

        if safeUpper - safeLower >= safeStep {
            return safeLower...safeUpper
        }

        return safeLower...(safeLower + safeStep)
    }

    static func clamped(_ value: Double, in range: ClosedRange<Double>) -> Double {
        guard value.isFinite else { return range.lowerBound }
        return min(max(value, range.lowerBound), range.upperBound)
    }
}

enum LiveResultPrimaryAction {
    static func title(isSaving: Bool, didSave: Bool) -> String {
        if isSaving { return "正在保存" }
        return didSave ? "打开相册查看" : "保存为 Live Photo"
    }
}

enum PhotoResultPrimaryAction {
    static func title(saveTitle: String, isSaving: Bool, didSave: Bool) -> String {
        if isSaving { return "正在保存" }
        return didSave ? "打开相册查看" : saveTitle
    }
}

struct NativeImageEdit: Hashable {
    static let defaultZoom: CGFloat = 1
    static let maxZoom: CGFloat = 3
    static let `default` = NativeImageEdit()

    var zoom: CGFloat
    var focalX: CGFloat
    var focalY: CGFloat

    init(
        zoom: CGFloat = NativeImageEdit.defaultZoom,
        focalX: CGFloat = 0.5,
        focalY: CGFloat = 0.5
    ) {
        self.zoom = zoom
        self.focalX = focalX
        self.focalY = focalY
    }

    func clamped() -> NativeImageEdit {
        NativeImageEdit(
            zoom: Self.clamp(zoom, min: Self.defaultZoom, max: Self.maxZoom),
            focalX: Self.clamp(focalX, min: 0, max: 1),
            focalY: Self.clamp(focalY, min: 0, max: 1)
        )
    }

    func dragged(translation: CGSize, imageSize: CGSize, targetSize: CGSize) -> NativeImageEdit {
        guard imageSize.width > 0,
              imageSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return clamped()
        }

        let edit = clamped()
        let baseScale = max(targetSize.width / imageSize.width, targetSize.height / imageSize.height)
        let scale = baseScale * edit.zoom
        let renderedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let overflowX = max(0, renderedSize.width - targetSize.width)
        let overflowY = max(0, renderedSize.height - targetSize.height)

        return NativeImageEdit(
            zoom: edit.zoom,
            focalX: overflowX > 0 ? edit.focalX - translation.width / overflowX : edit.focalX,
            focalY: overflowY > 0 ? edit.focalY - translation.height / overflowY : edit.focalY
        ).clamped()
    }

    static func edits(_ edits: [NativeImageEdit], fitting imageCount: Int) -> [NativeImageEdit] {
        (0..<imageCount).map { index in
            index < edits.count ? edits[index].clamped() : .default
        }
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        guard value.isFinite else { return minValue }
        return Swift.min(Swift.max(value, minValue), maxValue)
    }
}

enum NativeVideoRenderLayout {
    static func slotRect(for slot: CollageSlot, in renderSize: CGSize) -> CGRect {
        let minX = (slot.x * renderSize.width).rounded()
        let minY = (slot.y * renderSize.height).rounded()
        let maxX = ((slot.x + slot.width) * renderSize.width).rounded()
        let maxY = ((slot.y + slot.height) * renderSize.height).rounded()

        return CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX),
            height: max(1, maxY - minY)
        )
    }

    static func mediaTransform(
        sourceSize: CGSize,
        targetSize: CGSize,
        edit: NativeSlotEdit
    ) -> CGAffineTransform {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              targetSize.width > 0,
              targetSize.height > 0 else {
            return .identity
        }

        let baseScale: CGFloat
        switch edit.fitMode {
        case .fill:
            baseScale = max(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        case .fit:
            baseScale = min(targetSize.width / sourceSize.width, targetSize.height / sourceSize.height)
        }

        let scale = baseScale * (edit.fitMode == .fill ? edit.zoom : 1)
        let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let overflowX = max(0, scaledSize.width - targetSize.width)
        let overflowY = max(0, scaledSize.height - targetSize.height)
        let translateX: CGFloat
        let translateY: CGFloat

        switch edit.fitMode {
        case .fill:
            translateX = -overflowX * edit.focalX
            translateY = -overflowY * edit.focalY
        case .fit:
            translateX = (targetSize.width - scaledSize.width) / 2
            translateY = (targetSize.height - scaledSize.height) / 2
        }

        return CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: translateX, y: translateY))
    }
}

enum ImageJoinMode: String, CaseIterable, Identifiable {
    case horizontal
    case vertical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .horizontal:
            return "左右拼接"
        case .vertical:
            return "上下拼接"
        }
    }
}

enum ImageJoinLayout {
    static let maxPreviewCount = 9

    static func outputSize(for imageCount: Int, mode: ImageJoinMode, tileSize: CGFloat) -> CGSize {
        CGSize(width: tileSize, height: tileSize)
    }

    static func tileRect(index: Int, imageCount: Int, mode: ImageJoinMode, tileSize: CGFloat) -> CGRect {
        let count = max(1, min(maxPreviewCount, imageCount))
        let safeIndex = max(0, min(index, count - 1))

        switch mode {
        case .horizontal:
            let width = floor(tileSize / CGFloat(count))
            let x = CGFloat(safeIndex) * width
            let maxX = safeIndex == count - 1 ? tileSize : x + width
            return CGRect(x: x, y: 0, width: max(1, maxX - x), height: tileSize)
        case .vertical:
            let height = floor(tileSize / CGFloat(count))
            let y = CGFloat(safeIndex) * height
            let maxY = safeIndex == count - 1 ? tileSize : y + height
            return CGRect(x: 0, y: y, width: tileSize, height: max(1, maxY - y))
        }
    }

    static func previewFrames(for imageCount: Int, mode: ImageJoinMode) -> [CGRect] {
        let count = max(1, min(maxPreviewCount, imageCount))

        return (0..<count).map { index in
            switch mode {
            case .horizontal:
                let width = 1 / CGFloat(count)
                return CGRect(x: CGFloat(index) * width, y: 0, width: width, height: 1)
            case .vertical:
                let height = 1 / CGFloat(count)
                return CGRect(x: 0, y: CGFloat(index) * height, width: 1, height: height)
            }
        }
    }

    static func liveTemplate(for imageCount: Int, mode: ImageJoinMode) -> NativeCollageTemplate {
        let slots = previewFrames(for: imageCount, mode: mode).enumerated().map { index, frame in
            CollageSlot(
                id: index,
                x: frame.minX,
                y: frame.minY,
                width: frame.width,
                height: frame.height
            )
        }

        return NativeCollageTemplate(
            id: "image-join-\(mode.rawValue)-\(slots.count)",
            name: mode.title,
            detail: "图片与 Live Photo 拼接",
            slots: slots
        )
    }
}

enum SplitNineLayout {
    static func tiles(in size: CGSize) -> [CGRect] {
        let tileWidth = size.width / 3
        let tileHeight = size.height / 3

        return (0..<9).map { index in
            let column = index % 3
            let row = index / 3
            return CGRect(
                x: CGFloat(column) * tileWidth,
                y: CGFloat(row) * tileHeight,
                width: tileWidth,
                height: tileHeight
            )
        }
    }
}
