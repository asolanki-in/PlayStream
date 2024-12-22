//
//  SampleHandler.swift
//  PlayExtension
//
//  Created by Anil Solanki on 09/11/24.
//

import ReplayKit
import OSLog

class SampleHandler: RPBroadcastSampleHandler {
    private var tcpClient: TCPClient = TCPClient()
    private var imageProcessor: ImageProcessor = ImageProcessor()
    
    private var lastFrameTime: TimeInterval = 0
    private let frameInterval: TimeInterval = 1.0 / 30.0  // 30 FPS


    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        super.broadcastStarted(withSetupInfo: setupInfo)
        lastFrameTime = ProcessInfo.processInfo.systemUptime
    }
    
    override func broadcastPaused() {
        super.broadcastPaused()
    }
    
    override func broadcastResumed() {
        super.broadcastResumed()
    }
    
    override func broadcastFinished() {
        super.broadcastFinished()
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case .video:
            let currentTime = ProcessInfo.processInfo.systemUptime
            let timeSinceLastFrame = currentTime - lastFrameTime

            if timeSinceLastFrame >= frameInterval {
                lastFrameTime = currentTime  // Update the last processed frame time
                processVideoFrame(sampleBuffer)
            } else {
                os_log("Skipping frame to maintain frame rate of 30 FPS", type: .debug)
            }

        default:
            break
        }
    }
    
    private func processVideoFrame(_ sampleBuffer: CMSampleBuffer) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                os_log("Failed to get image buffer from sample buffer", type: .error)
                return
            }
            if let downScaledData = imageProcessor.downscaleImageBuffer(imageBuffer) {
                sendFrameData(downScaledData)
            }
        }

    func sendFrameData(_ data: Data) {
        tcpClient.broadcast(data: data)
    }
}

//    private var videoEncoder: VTCompressionSession?
//    private var tcpClient: TCPClient?
//    private var frameCount: Int = 0
//
//    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
//        print("Broadcast started")
//
//        // Initialize VideoToolbox encoder
//        var encoderSpecification: VTCompressionSession?
//        let encoderStatus = VTCompressionSessionCreate(
//            allocator: kCFAllocatorDefault,
//            width: 1920,
//            height: 1080,
//            codecType: kCMVideoCodecType_H264,
//            encoderSpecification: nil,
//            imageBufferAttributes: nil,
//            compressedDataAllocator: nil,
//            outputCallback: nil,
//            refcon: nil,
//            compressionSessionOut: &encoderSpecification
//        )
//
//        guard encoderStatus == noErr, let encoder = encoderSpecification else {
//            print("Error: Failed to create VTCompressionSession, status: \(encoderStatus)")
//            finishBroadcastWithError(NSError(domain: "com.example", code: Int(encoderStatus), userInfo: nil))
//            return
//        }
//
//        // Configure encoder properties
//        VTSessionSetProperty(encoder, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
//        VTSessionSetProperty(encoder, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
//        VTSessionSetProperty(encoder, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
//
//        // Keyframe interval in frames (every 60 frames at 30 FPS)
//        var frameInterval: Int = 60  // 2 seconds * 30 FPS
//        let frameIntervalCF = CFNumberCreate(kCFAllocatorDefault, .intType, &frameInterval)
//        VTSessionSetProperty(encoder, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: frameIntervalCF)
//
//        // Keyframe interval in duration (2 seconds)
//        var keyframeDuration: Double = 2.0
//        let keyframeDurationCF = CFNumberCreate(kCFAllocatorDefault, .doubleType, &keyframeDuration)
//        VTSessionSetProperty(encoder, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: keyframeDurationCF)
//
//        self.videoEncoder = encoder
//
//        // Initialize TCP client
//        self.tcpClient = TCPClient()
//    }
//
//    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
//        switch sampleBufferType {
//        case .video:
//            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//            let frameProperties = [
//                kVTEncodeFrameOptionKey_ForceKeyFrame: frameCount % 60 == 0 ? kCFBooleanTrue : kCFBooleanFalse
//            ] as CFDictionary
//
//            guard let encoder = self.videoEncoder else { return }
//            VTCompressionSessionEncodeFrame(
//                encoder,
//                imageBuffer: imageBuffer,
//                presentationTimeStamp: timestamp,
//                duration: CMTime.invalid,
//                frameProperties: frameProperties,
//                infoFlagsOut: nil
//            ) { [weak self] status, flags, sampleBuffer in
//                guard let self = self, status == noErr, let sampleBuffer = sampleBuffer else {
//                    print("Error during encoding: \(status)")
//                    return
//                }
//                self.sendEncodedSampleBuffer(sampleBuffer)
//            }
//
//            frameCount += 1
//        default:
//            break
//        }
//    }
//
//    private func sendEncodedSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
//        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
//        var totalLength: Int = 0
//        var dataPointer: UnsafeMutablePointer<Int8>?
//        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &totalLength, dataPointerOut: &dataPointer)
//
//        if let data = dataPointer {
//            let frameData = Data(bytes: data, count: totalLength)
//            self.tcpClient?.broadcast(data: frameData)
//        }
//    }
//
//    override func broadcastFinished() {
//        print("Broadcast finished")
//        videoEncoder = nil
//    }

// TCPClient.swift

//    var compressionSession: VTCompressionSession?
//    var streamSender : StreamSender?
//
//    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
//        setupVideoEncoding(width: 720, height: 1280)
//        streamSender = StreamSender()
//        streamSender?.startListening(on: 9100)
//    }
//
//    override func broadcastFinished() {
//        // Complete any pending frames and invalidate the session
//        if let session = compressionSession {
//            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
//            VTCompressionSessionInvalidate(session)
//            compressionSession = nil
//        }
//
//        // Cancel the UDP connection
//        streamSender?.stop()
//        streamSender = nil
//    }
//
//    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
//        guard sampleBufferType == .video else { return }
//
//        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
//            let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
//            VTCompressionSessionEncodeFrame(
//                compressionSession!,
//                imageBuffer: imageBuffer,
//                presentationTimeStamp: presentationTimeStamp,
//                duration: .invalid,
//                frameProperties: nil,
//                sourceFrameRefcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
//                infoFlagsOut: nil
//            )
//        }
//    }
//
//    // MARK: - Video Encoding Setup (H.264)
//    func setupVideoEncoding(width: Int32, height: Int32) {
//        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
//
//        let status = VTCompressionSessionCreate(
//            allocator: nil,
//            width: width,
//            height: height,
//            codecType: kCMVideoCodecType_H264,
//            encoderSpecification: nil,
//            imageBufferAttributes: nil,
//            compressedDataAllocator: nil,
//            outputCallback: videoCompressionOutputCallback,
//            refcon: selfPointer,
//            compressionSessionOut: &compressionSession
//        )
//
//        guard status == noErr else {
//            print("Error creating compression session: \(status)")
//            return
//        }
//
//        // Real-time encoding
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
//
//        // Bitrate and profile settings
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_AverageBitRate, value: NSNumber(value: 500_000))
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
//
//        // Insert SPS/PPS into every IDR frame
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: NSNumber(value: 30)) // Keyframe every 30 frames
//        VTSessionSetProperty(compressionSession!, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: NSNumber(value: 2)) // Keyframe every 2 seconds
//
//        VTCompressionSessionPrepareToEncodeFrames(compressionSession!)
//    }
//
//
//
//    func getDataFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Data? {
//        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return nil }
//        let length = CMBlockBufferGetDataLength(blockBuffer)
//        var data = Data(count: length)
//
//        data.withUnsafeMutableBytes { ptr in
//            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
//        }
//
//        return data
//    }
//
//    func sendFrame(data: Data) {
//        if (streamSender != nil) {
//            streamSender?.connections.forEach { connection in
//                streamSender?.sendData(to: connection, data: data)
//            }
//        }
//    }


// Global callback function
//func videoCompressionOutputCallback(
//    outputCallbackRefCon: UnsafeMutableRawPointer?,
//    sourceFrameRefCon: UnsafeMutableRawPointer?,
//    status: OSStatus,
//    infoFlags: VTEncodeInfoFlags,
//    sampleBuffer: CMSampleBuffer?
//) {
//    guard status == noErr, let sampleBuffer = sampleBuffer else { return }
//
//    // Access `self` using `outputCallbackRefCon`
//    let handler = Unmanaged<SampleHandler>.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
//
//    if let data = handler.getDataFromSampleBuffer(sampleBuffer) {
//        handler.sendFrame(data: data)
//    }
//}
