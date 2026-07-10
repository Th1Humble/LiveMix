@preconcurrency import AVFoundation
import Foundation
import ImageIO
import OSLog
import UniformTypeIdentifiers

struct PreparedLivePhotoResources {
    let imageURL: URL
    let videoURL: URL
}

enum LivePhotoResourceWriter {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "LiveMix",
        category: "LivePhotoResourceWriter"
    )

    static func prepare(imageURL: URL, videoURL: URL) async throws -> PreparedLivePhotoResources {
        let identifier = UUID().uuidString.uppercased()
        let preparedImageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        let preparedVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        logger.info(
            "Pairing Live Photo resources: imageBytes=\(fileSize(at: imageURL)), videoBytes=\(fileSize(at: videoURL))"
        )
        do {
            try writePairedImage(inputURL: imageURL, outputURL: preparedImageURL, identifier: identifier)
            try await writePairedVideo(inputURL: videoURL, outputURL: preparedVideoURL, identifier: identifier)
        } catch {
            logger.error(
                "Live Photo resource pairing failed: \(String(reflecting: error), privacy: .public)"
            )
            throw error
        }

        logger.info(
            "Live Photo resources paired: imageBytes=\(fileSize(at: preparedImageURL)), videoBytes=\(fileSize(at: preparedVideoURL))"
        )

        return PreparedLivePhotoResources(imageURL: preparedImageURL, videoURL: preparedVideoURL)
    }

    private static func writePairedImage(inputURL: URL, outputURL: URL, identifier: String) throws {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw LivePhotoResourceError.invalidImage
        }

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw LivePhotoResourceError.imageWriteFailed
        }

        var properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
        var makerApple = properties[kCGImagePropertyMakerAppleDictionary] as? [String: Any] ?? [:]
        makerApple["17"] = identifier
        properties[kCGImagePropertyMakerAppleDictionary] = makerApple

        CGImageDestinationAddImageFromSource(destination, source, 0, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw LivePhotoResourceError.imageWriteFailed
        }
    }

    private static func writePairedVideo(inputURL: URL, outputURL: URL, identifier: String) async throws {
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        let asset = AVURLAsset(url: inputURL)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        guard let videoTrack = videoTracks.first else {
            throw LivePhotoResourceError.invalidVideo
        }
        let timeRange = try await videoTrack.load(.timeRange)
        let naturalSize = try await videoTrack.load(.naturalSize)
        let preferredTransform = try await videoTrack.load(.preferredTransform)
        logger.info(
            "Pairing video track: range=\(describe(timeRange), privacy: .public), naturalSize=\(describe(naturalSize), privacy: .public), transform=\(describe(preferredTransform), privacy: .public)"
        )

        let reader = try AVAssetReader(asset: asset)
        let readerOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
        readerOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(readerOutput) else {
            throw LivePhotoResourceError.videoWriteFailed
        }
        reader.add(readerOutput)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        writer.shouldOptimizeForNetworkUse = true
        writer.metadata = [contentIdentifierMetadata(identifier)]

        let formatDescriptions = try await videoTrack.load(.formatDescriptions)
        let writerInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: nil,
            sourceFormatHint: formatDescriptions.first
        )
        writerInput.expectsMediaDataInRealTime = false
        writerInput.transform = try await videoTrack.load(.preferredTransform)
        guard writer.canAdd(writerInput) else {
            throw LivePhotoResourceError.videoWriteFailed
        }
        writer.add(writerInput)

        let metadataInput = AVAssetWriterInput(
            mediaType: .metadata,
            outputSettings: nil,
            sourceFormatHint: try stillImageTimeMetadataFormatDescription()
        )
        guard writer.canAdd(metadataInput) else {
            throw LivePhotoResourceError.metadataWriteFailed
        }
        writer.add(metadataInput)
        let metadataAdaptor = AVAssetWriterInputMetadataAdaptor(assetWriterInput: metadataInput)

        guard writer.startWriting() else {
            throw writer.error ?? LivePhotoResourceError.videoWriteFailed
        }
        guard reader.startReading() else {
            writer.cancelWriting()
            throw reader.error ?? LivePhotoResourceError.videoWriteFailed
        }

        writer.startSession(atSourceTime: .zero)
        try appendStillImageTime(using: metadataAdaptor)
        metadataInput.markAsFinished()

        try await copyVideoSamples(
            reader: reader,
            readerOutput: readerOutput,
            writer: writer,
            writerInput: writerInput
        )
    }

    private static func copyVideoSamples(
        reader: AVAssetReader,
        readerOutput: AVAssetReaderTrackOutput,
        writer: AVAssetWriter,
        writerInput: AVAssetWriterInput
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let queue = DispatchQueue(label: "live-photo-video-writer")
            var didResume = false
            var sampleCount = 0
            var timestampOffset: CMTime?
            var firstInputPresentationTime = CMTime.invalid
            var lastOutputEndTime = CMTime.zero

            func finish(_ result: Result<Void, Error>) {
                guard !didResume else { return }
                didResume = true

                switch result {
                case .success:
                    if lastOutputEndTime > .zero {
                        writer.endSession(atSourceTime: lastOutputEndTime)
                    }
                    logger.info(
                        "Video samples copied: count=\(sampleCount), firstInputPTS=\(describe(firstInputPresentationTime), privacy: .public), outputEnd=\(describe(lastOutputEndTime), privacy: .public)"
                    )
                    writer.finishWriting {
                        if writer.status == .completed {
                            logger.info("Paired video writer completed")
                            continuation.resume()
                        } else {
                            logger.error(
                                "Paired video writer failed: \(String(reflecting: writer.error), privacy: .public)"
                            )
                            continuation.resume(throwing: writer.error ?? LivePhotoResourceError.videoWriteFailed)
                        }
                    }
                case .failure(let error):
                    logger.error(
                        "Copying paired video samples failed: \(String(reflecting: error), privacy: .public)"
                    )
                    reader.cancelReading()
                    writer.cancelWriting()
                    continuation.resume(throwing: error)
                }
            }

            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        if timestampOffset == nil {
                            timestampOffset = presentationTime.isValid && !presentationTime.isIndefinite
                                ? presentationTime
                                : .zero
                            firstInputPresentationTime = presentationTime
                        }

                        let outputSample: CMSampleBuffer
                        do {
                            outputSample = try retimedSampleBuffer(
                                sampleBuffer,
                                subtracting: timestampOffset ?? .zero
                            )
                        } catch {
                            finish(.failure(error))
                            return
                        }

                        guard writerInput.append(outputSample) else {
                            finish(.failure(writer.error ?? LivePhotoResourceError.videoWriteFailed))
                            return
                        }
                        sampleCount += 1
                        let outputPresentationTime = CMSampleBufferGetPresentationTimeStamp(outputSample)
                        let outputDuration = CMSampleBufferGetDuration(outputSample)
                        if outputPresentationTime.isValid, !outputPresentationTime.isIndefinite {
                            let sampleEnd = outputDuration.isValid && !outputDuration.isIndefinite
                                ? CMTimeAdd(outputPresentationTime, outputDuration)
                                : outputPresentationTime
                            lastOutputEndTime = max(lastOutputEndTime, sampleEnd)
                        }
                    } else {
                        writerInput.markAsFinished()

                        if reader.status == .completed {
                            finish(.success(()))
                        } else {
                            finish(.failure(reader.error ?? LivePhotoResourceError.videoWriteFailed))
                        }
                        return
                    }
                }
            }
        }
    }

    private static func retimedSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        subtracting offset: CMTime
    ) throws -> CMSampleBuffer {
        guard offset.isValid, !offset.isIndefinite, offset != .zero else {
            return sampleBuffer
        }

        var timingCount = 0
        let countStatus = CMSampleBufferGetSampleTimingInfoArray(
            sampleBuffer,
            entryCount: 0,
            arrayToFill: nil,
            entriesNeededOut: &timingCount
        )
        guard countStatus == noErr, timingCount > 0 else {
            throw LivePhotoResourceError.videoWriteFailed
        }

        var timing = [CMSampleTimingInfo](
            repeating: CMSampleTimingInfo(
                duration: .invalid,
                presentationTimeStamp: .invalid,
                decodeTimeStamp: .invalid
            ),
            count: timingCount
        )
        let timingStatus = timing.withUnsafeMutableBufferPointer { buffer in
            CMSampleBufferGetSampleTimingInfoArray(
                sampleBuffer,
                entryCount: buffer.count,
                arrayToFill: buffer.baseAddress,
                entriesNeededOut: &timingCount
            )
        }
        guard timingStatus == noErr else {
            throw LivePhotoResourceError.videoWriteFailed
        }

        for index in timing.indices {
            if timing[index].presentationTimeStamp.isValid,
               !timing[index].presentationTimeStamp.isIndefinite {
                timing[index].presentationTimeStamp = CMTimeSubtract(
                    timing[index].presentationTimeStamp,
                    offset
                )
            }
            if timing[index].decodeTimeStamp.isValid,
               !timing[index].decodeTimeStamp.isIndefinite {
                timing[index].decodeTimeStamp = CMTimeSubtract(
                    timing[index].decodeTimeStamp,
                    offset
                )
            }
        }

        var output: CMSampleBuffer?
        let createStatus = timing.withUnsafeBufferPointer { buffer in
            CMSampleBufferCreateCopyWithNewTiming(
                allocator: kCFAllocatorDefault,
                sampleBuffer: sampleBuffer,
                sampleTimingEntryCount: buffer.count,
                sampleTimingArray: buffer.baseAddress!,
                sampleBufferOut: &output
            )
        }
        guard createStatus == noErr, let output else {
            throw LivePhotoResourceError.videoWriteFailed
        }
        return output
    }

    private static func contentIdentifierMetadata(_ identifier: String) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = "com.apple.quicktime.content.identifier" as NSString
        item.value = identifier as NSString
        item.dataType = kCMMetadataBaseDataType_UTF8 as String
        return item.copy() as! AVMetadataItem
    }

    private static func appendStillImageTime(using adaptor: AVAssetWriterInputMetadataAdaptor) throws {
        let item = AVMutableMetadataItem()
        item.keySpace = .quickTimeMetadata
        item.key = "com.apple.quicktime.still-image-time" as NSString
        item.value = 0 as NSNumber
        item.dataType = kCMMetadataBaseDataType_SInt8 as String

        let timeRange = CMTimeRange(start: .zero, duration: CMTime(value: 1, timescale: 100))
        let group = AVTimedMetadataGroup(items: [item], timeRange: timeRange)
        guard adaptor.append(group) else {
            throw LivePhotoResourceError.metadataWriteFailed
        }
    }

    private static func stillImageTimeMetadataFormatDescription() throws -> CMFormatDescription {
        let specification: [CFString: Any] = [
            kCMMetadataFormatDescriptionMetadataSpecificationKey_Identifier: "mdta/com.apple.quicktime.still-image-time",
            kCMMetadataFormatDescriptionMetadataSpecificationKey_DataType: kCMMetadataBaseDataType_SInt8 as String,
        ]
        var formatDescription: CMFormatDescription?
        let status = CMMetadataFormatDescriptionCreateWithMetadataSpecifications(
            allocator: kCFAllocatorDefault,
            metadataType: kCMMetadataFormatType_Boxed,
            metadataSpecifications: [specification] as CFArray,
            formatDescriptionOut: &formatDescription
        )

        guard status == noErr, let formatDescription else {
            throw LivePhotoResourceError.metadataWriteFailed
        }

        return formatDescription
    }

    private static func fileSize(at url: URL) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return Int64(values?.fileSize ?? 0)
    }

    private static func describe(_ time: CMTime) -> String {
        guard time.isValid, !time.isIndefinite else { return "invalid" }
        return String(format: "%.4f", CMTimeGetSeconds(time))
    }

    private static func describe(_ range: CMTimeRange) -> String {
        "start=\(describe(range.start)), duration=\(describe(range.duration))"
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

enum LivePhotoResourceError: Error {
    case invalidImage
    case imageWriteFailed
    case invalidVideo
    case videoWriteFailed
    case metadataWriteFailed
}
