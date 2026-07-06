@preconcurrency import AVFoundation
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct PreparedLivePhotoResources {
    let imageURL: URL
    let videoURL: URL
}

enum LivePhotoResourceWriter {
    static func prepare(imageURL: URL, videoURL: URL) async throws -> PreparedLivePhotoResources {
        let identifier = UUID().uuidString.uppercased()
        let preparedImageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        let preparedVideoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")

        try writePairedImage(inputURL: imageURL, outputURL: preparedImageURL, identifier: identifier)
        try await writePairedVideo(inputURL: videoURL, outputURL: preparedVideoURL, identifier: identifier)

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

            func finish(_ result: Result<Void, Error>) {
                guard !didResume else { return }
                didResume = true

                switch result {
                case .success:
                    writer.finishWriting {
                        if writer.status == .completed {
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: writer.error ?? LivePhotoResourceError.videoWriteFailed)
                        }
                    }
                case .failure(let error):
                    reader.cancelReading()
                    writer.cancelWriting()
                    continuation.resume(throwing: error)
                }
            }

            writerInput.requestMediaDataWhenReady(on: queue) {
                while writerInput.isReadyForMoreMediaData {
                    if let sampleBuffer = readerOutput.copyNextSampleBuffer() {
                        guard writerInput.append(sampleBuffer) else {
                            finish(.failure(writer.error ?? LivePhotoResourceError.videoWriteFailed))
                            return
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
}

enum LivePhotoResourceError: Error {
    case invalidImage
    case imageWriteFailed
    case invalidVideo
    case videoWriteFailed
    case metadataWriteFailed
}
