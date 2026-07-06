import Foundation
import CoreGraphics

@main
struct CollageCoreTests {
    static func main() {
        testLiveTemplatesExposeExpectedSlotCounts()
        testDefaultLiveSlotEditMatchesNativeEditorDefaults()
        testLiveSlotEditClampsToEditorBounds()
        testLiveOutputDurationUsesShortestSlotEdit()
        testLiveResultPrimaryActionTitleReflectsSaveState()
        testPhotoResultPrimaryActionTitleReflectsSaveState()
        testNativeVideoRenderLayoutRendersEachClipAtSlotSizeBeforeOverlay()
        testSliderRangeExpandsDegenerateBounds()
        testNativeImageEditClampsToImageEditorBounds()
        testNativeImageEditDragUpdatesFocalPoint()
        testImageJoinPreviewFramesMatchNativeEditor()
        testImageJoinOutputUsesSingleCanvas()
        testImageJoinLiveTemplateMatchesImageJoinLayout()
        testSplitNineProducesNineTiles()
        print("CollageCoreTests passed")
    }

    private static func testLiveTemplatesExposeExpectedSlotCounts() {
        let slotCounts = Dictionary(uniqueKeysWithValues: NativeCollageTemplate.liveTemplates.map { ($0.id, $0.slots.count) })

        expect(slotCounts["left-right"] == 2, "left-right should use 2 slots")
        expect(slotCounts["top-bottom"] == 2, "top-bottom should use 2 slots")
        expect(slotCounts["three-columns"] == 3, "three-columns should use 3 slots")
        expect(slotCounts["three-rows"] == 3, "three-rows should use 3 slots")
        expect(slotCounts["grid-2x2"] == 4, "grid-2x2 should use 4 slots")
        expect(slotCounts["one-big-two-small"] == 3, "one-big-two-small should use 3 slots")
    }

    private static func testDefaultLiveSlotEditMatchesNativeEditorDefaults() {
        let edit = NativeSlotEdit.default

        expect(edit.fitMode == .fill, "default live edit should fill/crop")
        expect(edit.focalX == 0.5, "default horizontal focal point should be centered")
        expect(edit.focalY == 0.5, "default vertical focal point should be centered")
        expect(edit.zoom == 1, "default zoom should be 1x")
        expect(edit.start == 0, "default start should be 0s")
        expect(edit.duration == 3, "default duration should be 3s")
    }

    private static func testLiveSlotEditClampsToEditorBounds() {
        let edit = NativeSlotEdit(
            fitMode: .fill,
            focalX: -0.4,
            focalY: 1.4,
            zoom: 4.2,
            start: 8,
            duration: 5
        ).clamped(maxStart: 2.25)

        expect(edit.focalX == 0, "focalX should clamp to 0...1")
        expect(edit.focalY == 1, "focalY should clamp to 0...1")
        expect(edit.zoom == 3, "zoom should clamp to 1...3")
        expect(edit.start == 2.25, "start should clamp to available range")
        expect(edit.duration == 3, "duration should clamp to 0.5...3")
    }

    private static func testLiveOutputDurationUsesShortestSlotEdit() {
        let edits = [
            NativeSlotEdit.default.withDuration(2.4),
            NativeSlotEdit.default.withDuration(1.35),
            NativeSlotEdit.default.withDuration(3),
        ]

        expect(NativeSlotEdit.outputDuration(for: edits) == 1.35, "output duration should use shortest slot edit")
        expect(NativeSlotEdit.outputDuration(for: []) == 3, "empty edits should fall back to 3s")
    }

    private static func testLiveResultPrimaryActionTitleReflectsSaveState() {
        expect(LiveResultPrimaryAction.title(isSaving: true, didSave: false) == "正在保存", "saving state should take priority")
        expect(LiveResultPrimaryAction.title(isSaving: false, didSave: true) == "打开相册查看", "saved state should offer opening Photos")
        expect(LiveResultPrimaryAction.title(isSaving: false, didSave: false) == "保存为 Live Photo", "initial state should offer saving")
    }

    private static func testPhotoResultPrimaryActionTitleReflectsSaveState() {
        expect(PhotoResultPrimaryAction.title(saveTitle: "保存到相册", isSaving: true, didSave: false) == "正在保存", "saving state should take priority")
        expect(PhotoResultPrimaryAction.title(saveTitle: "保存到相册", isSaving: false, didSave: true) == "打开相册查看", "saved image state should offer opening Photos")
        expect(PhotoResultPrimaryAction.title(saveTitle: "保存全部到相册", isSaving: false, didSave: false) == "保存全部到相册", "initial state should keep the screen-specific save title")
    }

    private static func testNativeVideoRenderLayoutRendersEachClipAtSlotSizeBeforeOverlay() {
        let template = NativeCollageTemplate.liveTemplates.first { $0.id == "left-right" }!
        let left = NativeVideoRenderLayout.slotRect(for: template.slots[0], in: CGSize(width: 1080, height: 1080))
        let right = NativeVideoRenderLayout.slotRect(for: template.slots[1], in: CGSize(width: 1080, height: 1080))

        expect(left == CGRect(x: 0, y: 0, width: 540, height: 1080), "left slot should render as a 540x1080 intermediate")
        expect(right == CGRect(x: 540, y: 0, width: 540, height: 1080), "right slot should render as a 540x1080 intermediate at x=540")

        let fillTransform = NativeVideoRenderLayout.mediaTransform(
            sourceSize: CGSize(width: 1920, height: 1080),
            targetSize: left.size,
            edit: .default
        )
        let renderedBounds = CGRect(x: 0, y: 0, width: 1920, height: 1080).applying(fillTransform)

        expect(renderedBounds.minX == -690, "wide fill source should be centered before the slot renderer clips it")
        expect(renderedBounds.width == 1920, "fill transform should preserve the scaled overflow for slot-local clipping")
    }

    private static func testSliderRangeExpandsDegenerateBounds() {
        let startRange = NativeSliderBounds.resolvedRange(lower: 0, upper: 0, step: 0.05)
        let durationRange = NativeSliderBounds.resolvedRange(lower: 0.5, upper: 0.5, step: 0.05)
        let invalidRange = NativeSliderBounds.resolvedRange(lower: 3, upper: 1, step: 0.05)
        let narrowRange = NativeSliderBounds.resolvedRange(lower: 0, upper: 0.02, step: 0.05)

        expect(startRange.lowerBound == 0, "start slider should keep the requested lower bound")
        expect(startRange.upperBound == 0.05, "start slider should expand zero-width ranges by one step")
        expect(durationRange.lowerBound == 0.5, "duration slider should keep the requested lower bound")
        expect(durationRange.upperBound == 0.55, "duration slider should expand zero-width ranges by one step")
        expect(invalidRange.upperBound > invalidRange.lowerBound, "invalid slider ranges should be repaired before SwiftUI sees them")
        expect(narrowRange.upperBound - narrowRange.lowerBound >= 0.05, "slider ranges narrower than the step should expand")
        expect(NativeSliderBounds.resolvedStep(-1) == 0.01, "non-positive slider steps should be repaired")
    }

    private static func testNativeImageEditClampsToImageEditorBounds() {
        let edit = NativeImageEdit(zoom: 0.2, focalX: -0.5, focalY: 1.5).clamped()

        expect(edit.zoom == 1, "image edit zoom should clamp to minimum cover scale")
        expect(edit.focalX == 0, "image edit focalX should clamp to 0...1")
        expect(edit.focalY == 1, "image edit focalY should clamp to 0...1")

        let maxed = NativeImageEdit(zoom: 4.2, focalX: 0.45, focalY: 0.55).clamped()

        expect(maxed.zoom == 3, "image edit zoom should clamp to maximum editor zoom")
        expect(maxed.focalX == 0.45, "valid focalX should be preserved")
        expect(maxed.focalY == 0.55, "valid focalY should be preserved")
    }

    private static func testNativeImageEditDragUpdatesFocalPoint() {
        let edit = NativeImageEdit(zoom: 1, focalX: 0.5, focalY: 0.5)
        let draggedWide = edit.dragged(
            translation: CGSize(width: 100, height: 0),
            imageSize: CGSize(width: 2000, height: 1000),
            targetSize: CGSize(width: 1000, height: 1000)
        )

        expect(draggedWide.focalX == 0.4, "dragging a wide image right should reveal more of the left side")
        expect(draggedWide.focalY == 0.5, "dragging on an axis without overflow should keep focalY")

        let draggedTall = edit.dragged(
            translation: CGSize(width: 0, height: -250),
            imageSize: CGSize(width: 1000, height: 2000),
            targetSize: CGSize(width: 1000, height: 1000)
        )

        expect(draggedTall.focalX == 0.5, "dragging on an axis without overflow should keep focalX")
        expect(draggedTall.focalY == 0.75, "dragging a tall image up should reveal more of the lower side")

        let clamped = edit.dragged(
            translation: CGSize(width: 2000, height: 0),
            imageSize: CGSize(width: 2000, height: 1000),
            targetSize: CGSize(width: 1000, height: 1000)
        )

        expect(clamped.focalX == 0, "dragged focal values should stay inside editor bounds")
    }

    private static func testImageJoinPreviewFramesMatchNativeEditor() {
        let horizontal = ImageJoinLayout.previewFrames(for: 8, mode: .horizontal)
        let vertical = ImageJoinLayout.previewFrames(for: 8, mode: .vertical)

        expect(horizontal.count == 8, "horizontal preview should expose one frame per selected image")
        expect(horizontal[0] == CGRect(x: 0, y: 0, width: 0.125, height: 1), "first horizontal frame should start at the left edge")
        expect(horizontal[7] == CGRect(x: 0.875, y: 0, width: 0.125, height: 1), "last horizontal frame should end at the right edge")

        expect(vertical.count == 8, "vertical preview should expose one frame per selected image")
        expect(vertical[0] == CGRect(x: 0, y: 0, width: 1, height: 0.125), "first vertical frame should start at the top edge")
        expect(vertical[7] == CGRect(x: 0, y: 0.875, width: 1, height: 0.125), "last vertical frame should end at the bottom edge")
    }

    private static func testImageJoinOutputUsesSingleCanvas() {
        let horizontal = ImageJoinLayout.outputSize(for: 8, mode: .horizontal, tileSize: 3240)
        let vertical = ImageJoinLayout.outputSize(for: 8, mode: .vertical, tileSize: 3240)
        let horizontalLastTile = ImageJoinLayout.tileRect(index: 7, imageCount: 8, mode: .horizontal, tileSize: 3240)
        let verticalLastTile = ImageJoinLayout.tileRect(index: 7, imageCount: 8, mode: .vertical, tileSize: 3240)

        expect(horizontal == CGSize(width: 3240, height: 3240), "horizontal join should export one square canvas split into columns")
        expect(vertical == CGSize(width: 3240, height: 3240), "vertical join should export one square canvas split into rows")
        expect(horizontalLastTile == CGRect(x: 2835, y: 0, width: 405, height: 3240), "last horizontal tile should occupy the last square-canvas column")
        expect(verticalLastTile == CGRect(x: 0, y: 2835, width: 3240, height: 405), "last vertical tile should occupy the last square-canvas row")
    }

    private static func testImageJoinLiveTemplateMatchesImageJoinLayout() {
        let horizontalTemplate = ImageJoinLayout.liveTemplate(for: 3, mode: .horizontal)
        let verticalTemplate = ImageJoinLayout.liveTemplate(for: 3, mode: .vertical)

        expect(horizontalTemplate.slots.map(\.rect) == [
            CGRect(x: 0, y: 0, width: 1.0 / 3.0, height: 1),
            CGRect(x: 1.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1),
            CGRect(x: 2.0 / 3.0, y: 0, width: 1.0 / 3.0, height: 1),
        ], "horizontal live template should split the canvas into equal columns")

        expect(verticalTemplate.slots.map(\.rect) == [
            CGRect(x: 0, y: 0, width: 1, height: 1.0 / 3.0),
            CGRect(x: 0, y: 1.0 / 3.0, width: 1, height: 1.0 / 3.0),
            CGRect(x: 0, y: 2.0 / 3.0, width: 1, height: 1.0 / 3.0),
        ], "vertical live template should split the canvas into equal rows")
    }

    private static func testSplitNineProducesNineTiles() {
        let tiles = SplitNineLayout.tiles(in: CGSize(width: 3240, height: 3240))

        expect(tiles.count == 9, "split-nine should produce exactly 9 tiles")
        expect(tiles.first == CGRect(x: 0, y: 0, width: 1080, height: 1080), "first tile should start at top-left")
        expect(tiles.last == CGRect(x: 2160, y: 2160, width: 1080, height: 1080), "last tile should end at bottom-right")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
        if !condition() {
            fputs("Test failed: \(message)\n", stderr)
            exit(1)
        }
    }
}
