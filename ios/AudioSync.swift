import Accelerate
import AVFoundation
import Foundation

@objc(AudioSync)
class AudioSync: NSObject {

  @objc(calculateSyncOffset:audioFile2Path:withResolver:withRejecter:)
    func calculateSyncOffset(
        _ audioFile1Path: NSString,
        _ audioFile2Path: NSString,
        _ resolve: RCTPromiseResolveBlock,
        _ reject: RCTPromiseRejectBlock
    ) -> Void {
        let syncOffset = getSyncOffsetBetweenAudioFiles(audioFile1Path, audioFile2Path)
        
        resolve(["syncOffset": syncOffset ?? 0.0])
    }
    
  func getSyncOffsetBetweenAudioFiles(
    _ audioFile1Path: NSString,
    _ audioFile2Path: NSString
  ) -> Double? {
    var audioFile1: AVAudioFile?
    do {
     audioFile1 = try AVAudioFile(forReading: URL.init(string: audioFile1Path as String)!)
    } catch let er {
     print("Error loading audioFile1: \(er)")
     return nil
    }
    var audioFile2: AVAudioFile?
    do {
     audioFile2 = try AVAudioFile(forReading: URL.init(string: audioFile2Path as String)!)
    } catch let er {
     print("Error loading audioFile2: \(er)")
     return nil
    }

    // compare the file lengths so we always compare the longer file against the shorter
    if (Double(audioFile2!.length) / audioFile2!.processingFormat.sampleRate) > (Double(audioFile1!.length) / audioFile1!.processingFormat.sampleRate) {
     let t: AVAudioFile = audioFile1!
     audioFile1 = audioFile2!
     audioFile1 = t
    }

    // return early if sample rates don't match
    if (audioFile1!.processingFormat.sampleRate != audioFile2!.processingFormat.sampleRate) {
     print("ERROR: Audio sample rates do not match!")
     return nil
    }

    let workingFrequency = audioFile1!.processingFormat.sampleRate

    // prepare a variable which represents the stride over the sample data - IE, only look at one in every 50 samples
    //   this saves on processing time/battery usage and at 441.kHz should still give us sample accuracy to within ~1.1337ms
    let samplingStride: Int = 50

    // prepare PCM buffers for inputs
    guard let audioFile1Buffer = AVAudioPCMBuffer(
     pcmFormat: audioFile1!.processingFormat,
     frameCapacity: AVAudioFrameCount(audioFile1!.length - 1)) else {
     print("Error preparing PCM buffer for audioFile1")
     return nil
    }
    guard let audioFile2Buffer = AVAudioPCMBuffer(
     pcmFormat: audioFile2!.processingFormat,
     frameCapacity: AVAudioFrameCount(audioFile2!.length - 1)) else {
     print("Error preparing PCM buffer for audioFile2")
     return nil
    }

    // read input files into PCM buffers
    do {
     try audioFile1!.read(into: audioFile1Buffer)
    } catch let er {
     print("Error reading audioFile1 into buffer: \(er)")
     return nil
    }
    do {
     try audioFile2!.read(into: audioFile2Buffer)
    } catch let er {
     print("Error reading audioFile2 into buffer: \(er)")
     return nil
    }

    // create a pointer to the memory address containing the raw float audio data from the first channel of audioFile1
    let audioFile1SamplePointer: UnsafeMutablePointer<Float> = audioFile1Buffer.floatChannelData![0]
    let audioFile1BufferSize: AVAudioFrameCount = audioFile1Buffer.frameLength

    // create a pointer to the memory address containing the raw float audio data from the first channel of audioFile2
    let audioFile2SamplePointer: UnsafeMutablePointer<Float> = audioFile2Buffer.floatChannelData![0]
    let audioFile2BufferSize: AVAudioFrameCount = audioFile2Buffer.frameLength

    // loop through the audioFile1 sample data until we find some non-zero values
    var audioFile1BufferPaddingCount: Int = 0
    while (audioFile1SamplePointer[audioFile1BufferPaddingCount] == 0 && ((audioFile1BufferPaddingCount + 1) < audioFile1BufferSize)) {
     audioFile1BufferPaddingCount += 1
    }
    // determine the amount of zero-padding in the float data held in the audioFile1 sample data pointer
    let audioFile1BufferSizeWithoutPadding: Int = (Int(audioFile1BufferSize) - audioFile1BufferPaddingCount) / samplingStride

    // loop through the audioFile1 sample data until we find some non-zero values
    var audioFile2BufferPaddingCount: Int = 0
    while (audioFile1SamplePointer[audioFile2BufferPaddingCount] == 0 && ((audioFile2BufferPaddingCount + 1) < audioFile2BufferSize)) {
     audioFile2BufferPaddingCount += 1
    }
    // determine the amount of zero-padding in the float data held in the audioFile2 sample data pointer
    let audioFile2BufferSizeWithoutPadding: Int = (Int(audioFile2BufferSize) - audioFile2BufferPaddingCount) / samplingStride

    // prepare a new buffer large enough to hold both the audio buffers minus their padding
    let audioFile1NewBufferSize: Int = (audioFile1BufferSizeWithoutPadding + audioFile2BufferSizeWithoutPadding * 2) * MemoryLayout<Float>.size
    let audioFile1NewBufferPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: audioFile1NewBufferSize)
    audioFile1NewBufferPointer.initialize(
     repeating: 0.0,
     count: (audioFile2BufferSizeWithoutPadding * MemoryLayout<Float>.size)
    )

    // create a pointer to the same memory address as audioFile1NewBufferPointer but shifted by audioFile2BufferSizeWithoutPadding instances
    let audioFile1ShiftedBufferPointer: UnsafeMutablePointer<Float> = audioFile1NewBufferPointer.advanced(by: audioFile2BufferSizeWithoutPadding)

    // populate shifted buffer with data from the audioFile1SamplePointer
    var i = audioFile1BufferPaddingCount * 2
    var audioFile1NewBufferIndex: Int = 0
    while i < audioFile1BufferSize {
     audioFile1ShiftedBufferPointer.advanced(by: audioFile1NewBufferIndex).pointee = audioFile1SamplePointer[i]
     audioFile1NewBufferIndex += 1
     i += 1 * samplingStride
    }

    // prepare a new buffer pointer large enough to fit the audioFile2 buffer less any zero-padding
    let audioFile2NewBufferSize: Int = Int(audioFile2BufferSizeWithoutPadding * MemoryLayout<Float>.size)
    let audioFile2NewBufferPointer: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: audioFile2NewBufferSize)

    // populate audioFile2NewBuffer with data from the audioFile2SamplePointer
    var j = audioFile2BufferPaddingCount * 2
    var audioFile2NewBufferIndex: Int = 0
    while j < audioFile2BufferSize {
     audioFile2NewBufferPointer.advanced(by: audioFile2NewBufferIndex).pointee = audioFile2SamplePointer[j]
     audioFile2NewBufferIndex += 1
     j += 1 * samplingStride
    }

    // prepare the input variables to feed into vDSP_conv

    // filter stride values should be positive so we perform cross-correlation rather than convolution
    let audioFile1Stride: Int = 1
    let audioFile2Stride: Int = 1
    let correlationResultStride: Int = 1

    let audioFile1Length: Int = audioFile1BufferSizeWithoutPadding
    let audioFile1Input: UnsafeMutablePointer<Float> = audioFile1NewBufferPointer

    let audioFile2Length: Int = audioFile2NewBufferIndex
    let audioFile2Input: UnsafeMutablePointer<Float> = audioFile2NewBufferPointer

    // prepare a float array to contain the results from the cross-correlation function
    let correlationResultBufferSize = ((audioFile1Length + audioFile2Length) / audioFile1Stride) * MemoryLayout<Float>.size
    let correlationResultLength: Int = (audioFile1Length + audioFile2Length) / audioFile1Stride
    let correlationResult: UnsafeMutablePointer<Float> = UnsafeMutablePointer<Float>.allocate(capacity: correlationResultBufferSize)

    // pass our variables into vDSP_conv, making sure to pass correlationResult by reference so it is populated
    vDSP_conv(
     audioFile1Input,
     audioFile1Stride,
     audioFile2Input,
     audioFile2Stride,
     correlationResult,
     correlationResultStride,
     vDSP_Length(correlationResultLength),
     vDSP_Length(audioFile2Length)
    )
    free(audioFile1Input)
    free(audioFile2Input)

    // loop through the correlationResult to determine the index with the strongest match in amplitude
    var maxResult: Float = Float.leastNormalMagnitude
    var maxResultIndex: Int = 0
    var k = 0
    while k < correlationResultLength {
     if (abs(correlationResult[k]) > maxResult) {
       maxResult = correlationResult[k]
       maxResultIndex = k
     }
     k += 1
    }
    free(correlationResult)

    // determine the index from the original audioFile2 buffer at which the correlationResult occured
    let matchingResultIndex: Int = (maxResultIndex - (audioFile2BufferSizeWithoutPadding + (audioFile2BufferPaddingCount / samplingStride)))
    let samplingWindowCount: Int = Int(workingFrequency) / samplingStride

    // divide the sample index by the number of sampling windows to get our ms offset
    let syncOffset: Double = Double(matchingResultIndex) / Double(samplingWindowCount)

    print("The biggest match is \(maxResult) at the position: \(maxResultIndex)")
    print("Sync offset is: \(syncOffset) seconds")

    return syncOffset
  }
}
