@preconcurrency import AVFoundation
import CoreGraphics
import Foundation
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct NativeVideoSelection: Identifiable {
    let id = UUID()
    let item: PhotosPickerItem
}

struct NativeLiveDraft: Identifiable, Hashable {
    let id = UUID()
    let imageURL: URL
    let videoURL: URL

    static func == (lhs: NativeLiveDraft, rhs: NativeLiveDraft) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

enum NativeLivePhotoComposerError: LocalizedError {
    case missingVideos
    case unreadableVideo
    case videoTooShort
    case exportFailed
    case stillFrameFailed

    var errorDescription: String? {
        switch self {
        case .missingVideos:
            return "请先选满当前模板需要的视频。"
        case .unreadableVideo:
            return "有视频暂时无法读取，请换一个视频试试。"
        case .videoTooShort:
            return "视频太短，暂时无法合成 Live Photo。"
        case .exportFailed:
            return "视频合成失败，请换一组视频试试。"
        case .stillFrameFailed:
            return "静态封面生成失败，请重试。"
        }
    }
}

actor NativeLivePhotoComposer {
    func compose(
        template: NativeCollageTemplate,
        videos: [NativeVideoSelection],
        edits: [NativeSlotEdit]
    ) async throws -> NativeLiveDraft {
        guard videos.count == template.slots.count else {
            throw NativeLivePhotoComposerError.missingVideos
        }

        let pickedVideos = try await loadPickedVideos(videos)
        let sourceURLs = pickedVideos.map(\.url)
        return try await compose(template: template, videoURLs: sourceURLs, edits: edits, shouldCleanupSourceURLs: true)
    }

    func compose(
        template: NativeCollageTemplate,
        videoURLs: [URL],
        edits: [NativeSlotEdit]
    ) async throws -> NativeLiveDraft {
        try await compose(template: template, videoURLs: videoURLs, edits: edits, shouldCleanupSourceURLs: false)
    }

    private func compose(
        template: NativeCollageTemplate,
        videoURLs: [URL],
        edits: [NativeSlotEdit],
        shouldCleanupSourceURLs: Bool
    ) async throws -> NativeLiveDraft {
        guard videoURLs.count == template.slots.count else {
            throw NativeLivePhotoComposerError.missingVideos
        }

        let sourceURLs = videoURLs
        let normalizedEdits = NativeSlotEdit.edits(edits, fitting: template.slots.count)
        let composedVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        let stillImageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")

        try await NativeVideoComposer.compose(
            sourceURLs: sourceURLs,
            template: template,
            edits: normalizedEdits,
            outputURL: composedVideoURL
        )
        try NativeVideoComposer.extractStillFrame(
            from: composedVideoURL,
            outputURL: stillImageURL
        )

        let prepared = try await LivePhotoResourceWriter.prepare(
            imageURL: stillImageURL,
            videoURL: composedVideoURL
        )

        cleanup(urls: (shouldCleanupSourceURLs ? sourceURLs : []) + [composedVideoURL, stillImageURL])
        return NativeLiveDraft(imageURL: prepared.imageURL, videoURL: prepared.videoURL)
    }

    private func loadPickedVideos(_ videos: [NativeVideoSelection]) async throws -> [PickedVideo] {
        var pickedVideos: [PickedVideo] = []

        for video in videos {
            guard let pickedVideo = try await video.item.loadTransferable(type: PickedVideo.self) else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }
            pickedVideos.append(pickedVideo)
        }

        return pickedVideos
    }

    private func cleanup(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}

struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let sourceURL = received.file
            let extensionValue = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
            let copiedURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension(extensionValue)

            if FileManager.default.fileExists(atPath: copiedURL.path) {
                try FileManager.default.removeItem(at: copiedURL)
            }
            try FileManager.default.copyItem(at: sourceURL, to: copiedURL)
            return PickedVideo(url: copiedURL)
        }
    }
}

private enum NativeVideoComposer {
    private static let renderSize = CGSize(width: 1080, height: 1080)
    private static let maxDuration = CMTime(seconds: 3, preferredTimescale: 600)
    private static let minDuration = CMTime(seconds: 0.5, preferredTimescale: 600)

    private struct RenderedSlotVideo {
        let url: URL
        let slotRect: CGRect
    }

    static func compose(
        sourceURLs: [URL],
        template: NativeCollageTemplate,
        edits: [NativeSlotEdit],
        outputURL: URL
    ) async throws {
        let assets = sourceURLs.map { AVURLAsset(url: $0) }
        let normalizedEdits = NativeSlotEdit.edits(edits, fitting: template.slots.count)
        let outputDuration = try await resolvedOutputDuration(for: assets, edits: normalizedEdits)
        var renderedSlots: [RenderedSlotVideo] = []
        var intermediateURLs: [URL] = []

        defer {
            cleanup(urls: intermediateURLs)
        }

        for (index, asset) in assets.enumerated() {
            let assetDuration = try await asset.load(.duration)
            let outputSeconds = CMTimeGetSeconds(outputDuration)
            let maxStart = max(0, CMTimeGetSeconds(assetDuration) - outputSeconds)
            let edit = normalizedEdits[index].clamped(maxStart: maxStart)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard let sourceTrack = videoTracks.first else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }

            let slotRect = slotRenderRect(for: template.slots[index])
            let slotURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            intermediateURLs.append(slotURL)

            try await renderSlotVideo(
                sourceTrack: sourceTrack,
                edit: edit,
                slotSize: slotRect.size,
                outputDuration: outputDuration,
                outputURL: slotURL
            )
            renderedSlots.append(RenderedSlotVideo(url: slotURL, slotRect: slotRect))
        }

        try await composeRenderedSlots(
            renderedSlots,
            outputDuration: outputDuration,
            outputURL: outputURL
        )
    }

    private static func renderSlotVideo(
        sourceTrack: AVAssetTrack,
        edit: NativeSlotEdit,
        slotSize: CGSize,
        outputDuration: CMTime,
        outputURL: URL
    ) async throws {
        let composition = AVMutableComposition()
        guard let compositionTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }

        let startTime = CMTime(seconds: edit.start, preferredTimescale: 600)
        try compositionTrack.insertTimeRange(
            CMTimeRange(start: startTime, duration: outputDuration),
            of: sourceTrack,
            at: .zero
        )

        let transform = try await renderTransform(for: sourceTrack, targetSize: slotSize, edit: edit)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
        layerInstruction.setTransform(transform, at: .zero)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: outputDuration)
        instruction.backgroundColor = UIColor.black.cgColor
        instruction.layerInstructions = [layerInstruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = slotSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]

        try await export(
            composition: composition,
            videoComposition: videoComposition,
            outputURL: outputURL
        )
    }

    private static func composeRenderedSlots(
        _ renderedSlots: [RenderedSlotVideo],
        outputDuration: CMTime,
        outputURL: URL
    ) async throws {
        let composition = AVMutableComposition()
        var layerInstructions: [AVMutableVideoCompositionLayerInstruction] = []

        for renderedSlot in renderedSlots {
            let asset = AVURLAsset(url: renderedSlot.url)
            let videoTracks = try await asset.loadTracks(withMediaType: .video)
            guard let sourceTrack = videoTracks.first,
                  let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }

            try compositionTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: outputDuration),
                of: sourceTrack,
                at: .zero
            )

            let normalizedTransform = try await normalizedTrackTransform(for: sourceTrack)
            let overlayTransform = normalizedTransform.concatenating(
                CGAffineTransform(
                    translationX: renderedSlot.slotRect.minX,
                    y: renderedSlot.slotRect.minY
                )
            )
            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
            layerInstruction.setTransform(overlayTransform, at: .zero)
            layerInstructions.append(layerInstruction)
        }

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: outputDuration)
        instruction.backgroundColor = UIColor.black.cgColor
        instruction.layerInstructions = layerInstructions.reversed()

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]

        try await export(
            composition: composition,
            videoComposition: videoComposition,
            outputURL: outputURL
        )
    }

    static func extractStillFrame(from videoURL: URL, outputURL: URL) throws {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = renderSize

        let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
        let image = UIImage(cgImage: cgImage)
        guard let data = image.jpegData(compressionQuality: 0.95) else {
            throw NativeLivePhotoComposerError.stillFrameFailed
        }

        try data.write(to: outputURL, options: .atomic)
    }

    private static func resolvedOutputDuration(
        for assets: [AVURLAsset],
        edits: [NativeSlotEdit]
    ) async throws -> CMTime {
        var durationSeconds = NativeSlotEdit.outputDuration(for: edits)

        for (index, asset) in assets.enumerated() {
            let assetDuration = try await asset.load(.duration)
            guard assetDuration > .zero else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }

            let assetSeconds = CMTimeGetSeconds(assetDuration)
            let editDuration = index < edits.count ? NativeSlotEdit.normalizedDuration(edits[index].duration) : NativeSlotEdit.maxDuration
            durationSeconds = min(durationSeconds, editDuration, assetSeconds)
        }

        let duration = CMTime(seconds: durationSeconds, preferredTimescale: 600)
        guard duration >= minDuration else {
            throw NativeLivePhotoComposerError.videoTooShort
        }
        return duration
    }

    private static func renderTransform(
        for track: AVAssetTrack,
        targetSize: CGSize,
        edit: NativeSlotEdit
    ) async throws -> CGAffineTransform {
        let geometry = try await orientedTrackGeometry(for: track)

        return geometry.transform.concatenating(
            NativeVideoRenderLayout.mediaTransform(
                sourceSize: geometry.size,
                targetSize: targetSize,
                edit: edit
            )
        )
    }

    private static func orientedTrackGeometry(
        for track: AVAssetTrack
    ) async throws -> (transform: CGAffineTransform, size: CGSize) {
        let naturalSize = try await track.load(.naturalSize)
        let preferredTransform = try await track.load(.preferredTransform)
        let transformedSize = naturalSize.applying(preferredTransform)
        let orientedSize = CGSize(
            width: abs(transformedSize.width),
            height: abs(transformedSize.height)
        )

        guard orientedSize.width > 0, orientedSize.height > 0 else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }

        var normalizedTransform = preferredTransform
        if transformedSize.width < 0 {
            normalizedTransform = normalizedTransform.concatenating(
                CGAffineTransform(translationX: -transformedSize.width, y: 0)
            )
        }
        if transformedSize.height < 0 {
            normalizedTransform = normalizedTransform.concatenating(
                CGAffineTransform(translationX: 0, y: -transformedSize.height)
            )
        }

        return (normalizedTransform, orientedSize)
    }

    private static func normalizedTrackTransform(for track: AVAssetTrack) async throws -> CGAffineTransform {
        try await orientedTrackGeometry(for: track).transform
    }

    private static func slotRenderRect(for slot: CollageSlot) -> CGRect {
        NativeVideoRenderLayout.slotRect(for: slot, in: renderSize)
    }

    private static func cleanup(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func export(
        composition: AVMutableComposition,
        videoComposition: AVMutableVideoComposition,
        outputURL: URL
    ) async throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NativeLivePhotoComposerError.exportFailed
        }

        exporter.outputURL = outputURL
        exporter.outputFileType = .mov
        exporter.videoComposition = videoComposition
        exporter.shouldOptimizeForNetworkUse = true

        let exporterBox = UnsafeSendableBox(exporter)
        try await withCheckedThrowingContinuation { continuation in
            exporterBox.value.exportAsynchronously {
                let exporter = exporterBox.value
                switch exporter.status {
                case .completed:
                    continuation.resume()
                case .failed, .cancelled:
                    continuation.resume(throwing: exporter.error ?? NativeLivePhotoComposerError.exportFailed)
                default:
                    continuation.resume(throwing: NativeLivePhotoComposerError.exportFailed)
                }
            }
        }
    }
}

private final class UnsafeSendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}

enum NativeVideoMetadataLoader {
    static func preview(for videoURL: URL) async -> NativeVideoPreview {
        let asset = AVURLAsset(url: videoURL)
        let duration = try? await asset.load(.duration)
        let thumbnail = try? makeThumbnail(from: asset)

        return NativeVideoPreview(
            url: videoURL,
            thumbnail: thumbnail,
            duration: duration.flatMap { time in
                let seconds = CMTimeGetSeconds(time)
                return seconds.isFinite ? seconds : nil
            }
        )
    }

    private static func makeThumbnail(from asset: AVURLAsset) throws -> UIImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)

        let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
        return UIImage(cgImage: cgImage)
    }
}

struct NativeVideoPreview: @unchecked Sendable {
    let url: URL
    let thumbnail: UIImage?
    let duration: Double?
}

enum NativeVideoPreviewLoadError: Error {
    case timeout
}

struct NativeImageJoinLiveSource: @unchecked Sendable {
    let image: UIImage
    let liveVideoURL: URL?
    let edit: NativeImageEdit
}

actor NativeImageJoinLiveComposer {
    func compose(
        sources: [NativeImageJoinLiveSource],
        mode: ImageJoinMode
    ) async throws -> NativeLiveDraft {
        guard !sources.isEmpty else {
            throw ImageCollageRenderError.emptyInput
        }
        guard sources.contains(where: { $0.liveVideoURL != nil }) else {
            throw NativeLivePhotoComposerError.missingVideos
        }

        let liveVideoURLs = sources.compactMap(\.liveVideoURL)
        let outputDuration = try await resolvedOutputDuration(for: liveVideoURLs)
        let composedVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        let stillImageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        var generatedVideoURLs: [URL] = []

        defer {
            cleanup(urls: generatedVideoURLs + [composedVideoURL, stillImageURL])
        }

        var sourceVideoURLs: [URL] = []
        for source in sources {
            if let liveVideoURL = source.liveVideoURL {
                sourceVideoURLs.append(liveVideoURL)
                continue
            }

            let stillVideoURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            try await Self.writeStillVideo(
                image: source.image,
                duration: outputDuration,
                outputURL: stillVideoURL
            )
            generatedVideoURLs.append(stillVideoURL)
            sourceVideoURLs.append(stillVideoURL)
        }

        let template = ImageJoinLayout.liveTemplate(for: sources.count, mode: mode)
        let edits = sources.map { source in
            let edit = source.edit.clamped()
            return NativeSlotEdit(
                fitMode: .fill,
                focalX: edit.focalX,
                focalY: edit.focalY,
                zoom: edit.zoom,
                start: 0,
                duration: CMTimeGetSeconds(outputDuration)
            )
        }

        try await NativeVideoComposer.compose(
            sourceURLs: sourceVideoURLs,
            template: template,
            edits: edits,
            outputURL: composedVideoURL
        )

        let stillImage = try ImageCollageRenderer.join(
            images: sources.map(\.image),
            edits: sources.map(\.edit),
            mode: mode,
            tileSize: 1080
        )
        guard let stillImageData = stillImage.jpegData(compressionQuality: 0.95) else {
            throw NativeLivePhotoComposerError.stillFrameFailed
        }
        try stillImageData.write(to: stillImageURL, options: .atomic)

        let prepared = try await LivePhotoResourceWriter.prepare(
            imageURL: stillImageURL,
            videoURL: composedVideoURL
        )
        return NativeLiveDraft(imageURL: prepared.imageURL, videoURL: prepared.videoURL)
    }

    private func resolvedOutputDuration(for liveVideoURLs: [URL]) async throws -> CMTime {
        var seconds = NativeSlotEdit.maxDuration

        for url in liveVideoURLs {
            let asset = AVURLAsset(url: url)
            let duration = try await asset.load(.duration)
            guard duration > .zero else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }

            let assetSeconds = CMTimeGetSeconds(duration)
            guard assetSeconds.isFinite else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }
            seconds = min(seconds, assetSeconds)
        }

        let normalizedSeconds = min(NativeSlotEdit.maxDuration, seconds)
        let duration = CMTime(seconds: normalizedSeconds, preferredTimescale: 600)
        guard duration >= CMTime(seconds: NativeSlotEdit.minDuration, preferredTimescale: 600) else {
            throw NativeLivePhotoComposerError.videoTooShort
        }

        return duration
    }

    private static func writeStillVideo(
        image: UIImage,
        duration: CMTime,
        outputURL: URL
    ) async throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let videoSize = normalizedVideoSize(for: image.size)
        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: Int(videoSize.width),
                AVVideoHeightKey: Int(videoSize.height),
            ]
        )
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(videoSize.width),
                kCVPixelBufferHeightKey as String: Int(videoSize.height),
            ]
        )

        guard writer.canAdd(input) else {
            throw NativeLivePhotoComposerError.exportFailed
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw writer.error ?? NativeLivePhotoComposerError.exportFailed
        }
        writer.startSession(atSourceTime: .zero)

        guard let pixelBuffer = makePixelBuffer(from: image, size: videoSize) else {
            writer.cancelWriting()
            throw NativeLivePhotoComposerError.exportFailed
        }

        let frameDuration = CMTime(value: 1, timescale: 30)
        let endFrameTime = duration > frameDuration ? duration - frameDuration : .zero
        guard adaptor.append(pixelBuffer, withPresentationTime: .zero),
              adaptor.append(pixelBuffer, withPresentationTime: endFrameTime) else {
            writer.cancelWriting()
            throw writer.error ?? NativeLivePhotoComposerError.exportFailed
        }

        input.markAsFinished()
        writer.endSession(atSourceTime: duration)

        let writerBox = UnsafeSendableBox(writer)
        try await withCheckedThrowingContinuation { continuation in
            writerBox.value.finishWriting {
                let writer = writerBox.value
                if writer.status == .completed {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: writer.error ?? NativeLivePhotoComposerError.exportFailed)
                }
            }
        }
    }

    private static func normalizedVideoSize(for imageSize: CGSize) -> CGSize {
        let width = max(imageSize.width, 2)
        let height = max(imageSize.height, 2)
        let scale = min(1, 1080 / max(width, height))

        func even(_ value: CGFloat) -> CGFloat {
            max(2, floor(value * scale / 2) * 2)
        }

        return CGSize(width: even(width), height: even(height))
    }

    private static func makePixelBuffer(from image: UIImage, size: CGSize) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ] as CFDictionary
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            attributes,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else {
            return nil
        }

        UIGraphicsPushContext(context)
        UIColor.black.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        image.draw(in: CGRect(origin: .zero, size: size))
        UIGraphicsPopContext()

        return pixelBuffer
    }

    private func cleanup(urls: [URL]) {
        for url in urls {
            try? FileManager.default.removeItem(at: url)
        }
    }
}
