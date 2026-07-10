@preconcurrency import AVFoundation
import CoreGraphics
import Foundation
import OSLog
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
    case videoTooLong
    case videoTooShort
    case exportFailed
    case stillFrameFailed

    var errorDescription: String? {
        switch self {
        case .missingVideos:
            return "请先选满当前模板需要的视频。"
        case .unreadableVideo:
            return "有视频暂时无法读取，请换一个视频试试。"
        case .videoTooLong:
            return "视频不能超过 5 秒，请先裁剪后再试。"
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
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "LivePhotoComposer"
    )

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

        Self.logger.info(
            "Compose started: template=\(template.id, privacy: .public), videos=\(videoURLs.count)"
        )

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

        Self.logger.info("Compose completed and Live Photo resources are paired")

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

enum NativeVideoInputLimits {
    static let maximumDuration = 5.0
}

private enum NativeVideoComposer {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "VideoPipeline"
    )
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
        logger.info(
            "Video composition started: slots=\(assets.count), outputDuration=\(seconds(outputDuration), privacy: .public)s"
        )
        var renderedSlots: [RenderedSlotVideo] = []
        var intermediateURLs: [URL] = []

        defer {
            cleanup(urls: intermediateURLs)
        }

        for (index, asset) in assets.enumerated() {
            let sourceTrack = try await videoTrack(for: asset)
            let sourceTimeRange = try await usableTimeRange(for: sourceTrack)
            let naturalSize = try await sourceTrack.load(.naturalSize)
            let preferredTransform = try await sourceTrack.load(.preferredTransform)
            logger.info(
                "Input slot \(index): range=\(describe(sourceTimeRange), privacy: .public), naturalSize=\(describe(naturalSize), privacy: .public), transform=\(describe(preferredTransform), privacy: .public)"
            )
            let outputSeconds = CMTimeGetSeconds(outputDuration)
            let maxStart = max(0, CMTimeGetSeconds(sourceTimeRange.duration) - outputSeconds)
            let edit = normalizedEdits[index].clamped(maxStart: maxStart)

            let slotRect = slotRenderRect(for: template.slots[index])
            let slotURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mov")
            intermediateURLs.append(slotURL)

            try await renderSlotVideo(
                sourceTrack: sourceTrack,
                sourceTimeRange: sourceTimeRange,
                edit: edit,
                slotSize: slotRect.size,
                outputDuration: outputDuration,
                outputURL: slotURL
            )
            logger.info(
                "Rendered slot \(index): bytes=\(fileSize(at: slotURL)), target=\(describe(slotRect.size), privacy: .public)"
            )
            renderedSlots.append(RenderedSlotVideo(url: slotURL, slotRect: slotRect))
        }

        try await composeRenderedSlots(
            renderedSlots,
            outputDuration: outputDuration,
            outputURL: outputURL
        )
        logger.info("Final video composed: bytes=\(fileSize(at: outputURL))")
    }

    private static func renderSlotVideo(
        sourceTrack: AVAssetTrack,
        sourceTimeRange: CMTimeRange,
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

        let editOffset = CMTime(seconds: edit.start, preferredTimescale: 600)
        let requestedStart = CMTimeAdd(sourceTimeRange.start, editOffset)
        let latestStart = CMTimeSubtract(CMTimeRangeGetEnd(sourceTimeRange), outputDuration)
        guard CMTimeCompare(latestStart, sourceTimeRange.start) >= 0 else {
            throw NativeLivePhotoComposerError.videoTooShort
        }

        let startTime = CMTimeCompare(requestedStart, latestStart) > 0 ? latestStart : requestedStart
        let requestedRange = CMTimeRange(start: startTime, duration: outputDuration)

        try compositionTrack.insertTimeRange(
            requestedRange,
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
            let sourceTrack = try await videoTrack(for: asset)
            let sourceTimeRange = try await usableTimeRange(for: sourceTrack)
            guard let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                  ) else {
                throw NativeLivePhotoComposerError.unreadableVideo
            }

            try compositionTrack.insertTimeRange(
                CMTimeRange(start: sourceTimeRange.start, duration: outputDuration),
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
        let luminance = averageLuminance(of: cgImage)
        if luminance < 0.015 {
            logger.warning(
                "The first frame is nearly black: averageLuminance=\(luminance, format: .fixed(precision: 4))"
            )
        } else {
            logger.info(
                "First frame decoded: averageLuminance=\(luminance, format: .fixed(precision: 4))"
            )
        }
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
        var duration = min(
            maxDuration,
            CMTime(seconds: NativeSlotEdit.outputDuration(for: edits), preferredTimescale: 600)
        )

        for (index, asset) in assets.enumerated() {
            let track = try await videoTrack(for: asset)
            let timeRange = try await usableTimeRange(for: track)
            guard CMTimeGetSeconds(timeRange.duration) <= NativeVideoInputLimits.maximumDuration else {
                throw NativeLivePhotoComposerError.videoTooLong
            }
            let trackDuration = CMTimeConvertScale(
                timeRange.duration,
                timescale: 600,
                method: .roundTowardZero
            )
            let editDuration = CMTime(
                seconds: index < edits.count
                    ? NativeSlotEdit.normalizedDuration(edits[index].duration)
                    : NativeSlotEdit.maxDuration,
                preferredTimescale: 600
            )
            duration = min(duration, editDuration, trackDuration)
        }

        guard duration >= minDuration else {
            throw NativeLivePhotoComposerError.videoTooShort
        }
        return duration
    }

    private static func videoTrack(for asset: AVURLAsset) async throws -> AVAssetTrack {
        let tracks = try await asset.loadTracks(withMediaType: .video)
        guard let track = tracks.first else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }
        return track
    }

    private static func usableTimeRange(for track: AVAssetTrack) async throws -> CMTimeRange {
        let timeRange = try await track.load(.timeRange)
        let startSeconds = CMTimeGetSeconds(timeRange.start)
        let durationSeconds = CMTimeGetSeconds(timeRange.duration)
        guard timeRange.isValid,
              startSeconds.isFinite,
              durationSeconds.isFinite,
              durationSeconds > 0 else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }
        return timeRange
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
        guard let geometry = NativeVideoRenderLayout.orientedGeometry(
            naturalSize: naturalSize,
            preferredTransform: preferredTransform
        ) else {
            throw NativeLivePhotoComposerError.unreadableVideo
        }
        return geometry
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
                    logger.info(
                        "AVAssetExport completed: bytes=\(fileSize(at: outputURL))"
                    )
                    continuation.resume()
                case .failed, .cancelled:
                    logger.error(
                        "AVAssetExport failed: status=\(exporter.status.rawValue), error=\(String(reflecting: exporter.error), privacy: .public)"
                    )
                    continuation.resume(throwing: exporter.error ?? NativeLivePhotoComposerError.exportFailed)
                default:
                    continuation.resume(throwing: NativeLivePhotoComposerError.exportFailed)
                }
            }
        }
    }

    private static func averageLuminance(of image: CGImage) -> Double {
        let width = 16
        let height = 16
        var pixels = [UInt8](repeating: 0, count: width * height)
        let didRender = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(
                data: bytes.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else {
                return false
            }
            context.interpolationQuality = .low
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didRender else { return 0 }
        return pixels.reduce(0) { $0 + Double($1) } / Double(pixels.count * 255)
    }

    private static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func seconds(_ time: CMTime) -> String {
        String(format: "%.4f", CMTimeGetSeconds(time))
    }

    private static func describe(_ range: CMTimeRange) -> String {
        "start=\(seconds(range.start)), duration=\(seconds(range.duration))"
    }

    private static func describe(_ size: CGSize) -> String {
        String(format: "%.0fx%.0f", size.width, size.height)
    }

    private static func describe(_ transform: CGAffineTransform) -> String {
        String(
            format: "[%.3f %.3f %.3f %.3f %.1f %.1f]",
            transform.a,
            transform.b,
            transform.c,
            transform.d,
            transform.tx,
            transform.ty
        )
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
        let videoTracks = try? await asset.loadTracks(withMediaType: .video)
        let timeRange: CMTimeRange?
        if let videoTrack = videoTracks?.first {
            timeRange = try? await videoTrack.load(.timeRange)
        } else {
            timeRange = nil
        }
        let assetDuration = try? await asset.load(.duration)
        let duration = timeRange?.duration ?? assetDuration
        let thumbnailTime = timeRange?.start ?? .zero
        let thumbnail = try? makeThumbnail(from: asset, at: thumbnailTime)

        return NativeVideoPreview(
            url: videoURL,
            thumbnail: thumbnail,
            duration: duration.flatMap { time in
                let seconds = CMTimeGetSeconds(time)
                return seconds.isFinite ? seconds : nil
            }
        )
    }

    private static func makeThumbnail(from asset: AVURLAsset, at time: CMTime) throws -> UIImage {
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 720, height: 720)

        let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
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
    case durationTooLong
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
