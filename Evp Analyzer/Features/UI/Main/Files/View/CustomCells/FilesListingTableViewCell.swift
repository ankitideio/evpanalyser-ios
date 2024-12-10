//
//  FilesListingTableViewCell.swift
//  Evp Analyzer
//
//  Created by MACBOOK PRO on 13/06/2022.
//

import UIKit
import SoundWave
import AVFoundation
import Foundation
import EZAudio
struct SoundRecord {
    var audioFilePathLocal: URL?
    var meteringLevels: [Float]?
}

protocol FilesListingTableViewCellDelegate: AnyObject {
    func deleteButtonTapped(_ cell: FilesListingTableViewCell)
    func shareButtonTapped(_ cell: FilesListingTableViewCell)
}

class FilesListingTableViewCell: UITableViewCell {

    @IBOutlet weak var audioPlot: EZAudioPlot!
    @IBOutlet weak var moreMenuView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var filenameLabel: UILabel!
    @IBOutlet weak var startBtn: UIButton!
    
    @IBOutlet var waveView: AudioVisualizationView!
    
    weak var delegate: FilesListingTableViewCellDelegate?
    var dataSource: RecordingModel?
    var currentAudioRecord: SoundRecord?
    let noiseFloor: Float = -80
    var audioVisualizationTimeInterval: TimeInterval = 0.05

    private var isPlaying = false
    
    var audioPlayer: EZAudioPlayer!
 
    var cellIndex: Int?
    
     var currentState: AudioRecodingState = .recorded {
        didSet {
            self.startBtn.setImage(self.currentState.buttonImage, for: .normal)
            self.waveView.audioVisualizationMode = self.currentState.audioVisualizationMode
        }
    }
    
   
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // notifications audio finished
     
        self.audioPlot.plotType = EZPlotType.rolling

        NotificationCenter.default.addObserver(self, selector: #selector(self.didFinishRecordOrPlayAudio),
                                               name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: nil)
    }
   
   
  

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func didTapPlayButton() {
        self.startBtn.isSelected = !self.startBtn.isSelected
        
        if self.startBtn.isSelected {
            if self.currentState == .recorded || self.currentState == .paused {
                do {
                    self.audioPlot.isHidden = false
                    let duration = try self.startPlaying()
                    self.currentState = .playing
                    self.waveView.meteringLevels = self.currentAudioRecord!.meteringLevels
//                    self.waveView.play(for: duration)
                    try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth,.allowBluetoothA2DP,.defaultToSpeaker,.allowAirPlay,.duckOthers])
                       try AVAudioSession.sharedInstance().setActive(true)
                   
                    audioPlayer?.delegate = self
                    audioPlayer?.shouldLoop = false
                    audioPlayer?.play()
                    self.cellIndex = startBtn.tag
                    print("Select CEll","\(self.cellIndex ?? 0)")
                } catch {
//                    self.showAlert(with: error)
                }
            }
        } else {
            if self.currentState == .playing {
                do {
                    try self.pausePlaying()
                   
                    self.currentState = .paused
//                    self.waveView.pause()
                    audioPlayer?.delegate = nil
                    
                    audioPlayer?.pause()
                    
                    print("pause audio----")
                } catch {
//                    self.showAlert(with: error)
                }
            }
        }
    }
    
    @IBAction func moreOptionAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        moreMenuView.isHidden = !sender.isSelected
    }
    
    @IBAction func deleteTapAction(_ sender: UIButton) {
        delegate?.deleteButtonTapped(self)
    }
    
    @IBAction func shareTapAction(_ sender: UIButton) {
        delegate?.shareButtonTapped(self)
    }
}

extension FilesListingTableViewCell {
    func startPlaying() throws -> TimeInterval {
        guard let currentAudioRecord = self.currentAudioRecord else {
            throw AudioErrorType.audioFileWrongPath
        }
        
        if self.isPlaying {
            return try AudioPlayerManager.shared.resume()
        } else {
            guard let audioFilePath = currentAudioRecord.audioFilePathLocal else {
                fatalError("tried to unwrap audio file path that is nil")
            }
            if FileManager.default.fileExists(atPath: audioFilePath.path) {
                print("The file already exists at path")
                print("Audio Path---",audioFilePath)
                if
                    let audioFile = EZAudioFile(url: audioFilePath) {
                    
                    audioPlayer = EZAudioPlayer(audioFile: audioFile)
                 
                }
            }
                self.isPlaying = true
                return try AudioPlayerManager.shared.play(at: audioFilePath, with: self.audioVisualizationTimeInterval)
            
        }
    }
    func pausePlaying() throws {
        try AudioPlayerManager.shared.pause()
    }
    
    func bindData(model: RecordingModel) {
        self.startBtn.isSelected = false
        self.dataSource = model
        if let url = model.url {
            self.currentState = .recorded
            self.setupWave(url: url)
        }
        self.filenameLabel.text = model.fileName
        self.dateLabel.text = model.date
    }
    func setupWave(url: URL) {
        self.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: [])
        self.currentAudioRecord?.meteringLevels = self.waveView.scaleSoundDataToFitScreen()

        self.bindAudio(url: url)
    }
    func bindAudio(url: URL) {
        var outputArray : [Float] = []
        AudioContext.load(fromAudioURL: url, completionHandler: { audioContext in
            guard let audioContext = audioContext else {
//                fatalError("Couldn't create the audioContext")
                print("fatal error")
                return
            }
            outputArray = self.render(audioContext: audioContext, targetSamples: 200)
            self.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: outputArray)
        })
    }
    @objc private func didFinishRecordOrPlayAudio(_ notification: Notification) {
       
        self.currentState = .recorded
        self.isPlaying = false
        DispatchQueue.main.asyncAfter(deadline: .now()+0.5){
            self.startBtn.isSelected = false
            self.audioPlot.clear()
            self.audioPlot.isHidden = true
        }
        
        
    }
}

// MARK:- Loading metering from audio url
extension FilesListingTableViewCell {
    func render(audioContext: AudioContext?, targetSamples: Int = 100) -> [Float]{
        guard let audioContext = audioContext else {
            fatalError("Couldn't create the audioContext")
        }
        
        let sampleRange: CountableRange<Int> = 0..<audioContext.totalSamples
        
        guard let reader = try? AVAssetReader(asset: audioContext.asset)
            else {
                return [Float]()
//                fatalError("Couldn't initialize the AVAssetReader")
        }
        
        reader.timeRange = CMTimeRange(start: CMTime(value: Int64(sampleRange.lowerBound), timescale: audioContext.asset.duration.timescale),
                                       duration: CMTime(value: Int64(sampleRange.count), timescale: audioContext.asset.duration.timescale))
        
        let outputSettingsDict: [String : Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVLinearPCMBitDepthKey: 8,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let readerOutput = AVAssetReaderTrackOutput(track: audioContext.assetTrack,
                                                    outputSettings: outputSettingsDict)
        readerOutput.alwaysCopiesSampleData = false
        reader.add(readerOutput)
        
        var channelCount = 1
        let formatDescriptions = audioContext.assetTrack.formatDescriptions as! [CMAudioFormatDescription]
        for item in formatDescriptions {
            guard let fmtDesc = CMAudioFormatDescriptionGetStreamBasicDescription(item) else {
                fatalError("Couldn't get the format description")
            }
            channelCount = Int(fmtDesc.pointee.mChannelsPerFrame)
        }
        
        let samplesPerPixel = max(1, channelCount * sampleRange.count / targetSamples)
        let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
        
        var outputSamples = [Float]()
        var sampleBuffer = Data()
        
        // 16-bit samples
        reader.startReading()
        defer { reader.cancelReading() }
        
        while reader.status == .reading {
            guard let readSampleBuffer = readerOutput.copyNextSampleBuffer(),
                let readBuffer = CMSampleBufferGetDataBuffer(readSampleBuffer) else {
                    break
            }
            // Append audio sample buffer into our current sample buffer
            var readBufferLength = 0
            var readBufferPointer: UnsafeMutablePointer<Int8>?
            CMBlockBufferGetDataPointer(readBuffer,
                                        atOffset: 0,
                                        lengthAtOffsetOut: &readBufferLength,
                                        totalLengthOut: nil,
                                        dataPointerOut: &readBufferPointer)
            sampleBuffer.append(UnsafeBufferPointer(start: readBufferPointer, count: readBufferLength))
            CMSampleBufferInvalidate(readSampleBuffer)
            
            let totalSamples = sampleBuffer.count / MemoryLayout<Int16>.size
            let downSampledLength = totalSamples / samplesPerPixel
            let samplesToProcess = downSampledLength * samplesPerPixel
            
            guard samplesToProcess > 0 else { continue }
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
            //print("Status: \(reader.status)")
        }
        
        // Process the remaining samples at the end which didn't fit into samplesPerPixel
        let samplesToProcess = sampleBuffer.count / MemoryLayout<Int16>.size
        if samplesToProcess > 0 {
            let downSampledLength = 1
            let samplesPerPixel = samplesToProcess
            let filter = [Float](repeating: 1.0 / Float(samplesPerPixel), count: samplesPerPixel)
            
            processSamples(fromData: &sampleBuffer,
                           outputSamples: &outputSamples,
                           samplesToProcess: samplesToProcess,
                           downSampledLength: downSampledLength,
                           samplesPerPixel: samplesPerPixel,
                           filter: filter)
            //print("Status: \(reader.status)")
        }
        
        // if (reader.status == AVAssetReaderStatusFailed || reader.status == AVAssetReaderStatusUnknown)
        guard reader.status == .completed else {
            fatalError("Couldn't read the audio file")
        }
        
        return outputSamples
    }

    func processSamples(fromData sampleBuffer: inout Data,
                        outputSamples: inout [Float],
                        samplesToProcess: Int,
                        downSampledLength: Int,
                        samplesPerPixel: Int,
                        filter: [Float]) {
        
        sampleBuffer.withUnsafeBytes { (samples: UnsafeRawBufferPointer) in
            var processingBuffer = [Float](repeating: 0.0, count: samplesToProcess)
            
            let sampleCount = vDSP_Length(samplesToProcess)
            
            //Create an UnsafePointer<Int16> from samples
            let unsafeBufferPointer = samples.bindMemory(to: Int16.self)
            let unsafePointer = unsafeBufferPointer.baseAddress!
            
            //Convert 16bit int samples to floats
            vDSP_vflt16(unsafePointer, 1, &processingBuffer, 1, sampleCount)
            
            //Take the absolute values to get amplitude
            vDSP_vabs(processingBuffer, 1, &processingBuffer, 1, sampleCount)
            
            //get the corresponding dB, and clip the results
            getdB(from: &processingBuffer)
            
            //Downsample and average
            var downSampledData = [Float](repeating: 0.0, count: downSampledLength)
            vDSP_desamp(processingBuffer,
                        vDSP_Stride(samplesPerPixel),
                        filter, &downSampledData,
                        vDSP_Length(downSampledLength),
                        vDSP_Length(samplesPerPixel))
            
            //Remove processed samples
            sampleBuffer.removeFirst(samplesToProcess * MemoryLayout<Int16>.size)
            
            var data = [Float]()
            for each in downSampledData {
                let val = abs(each)
                let result = val/100
                data.append(result)
            }
            
//            outputSamples += downSampledData
            outputSamples += data
        }
    }

    func getdB(from normalizedSamples: inout [Float]) {
        // Convert samples to a log scale
        var zero: Float = 32768.0
        vDSP_vdbcon(normalizedSamples, 1, &zero, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count), 1)
        
        //Clip to [noiseFloor, 0]
        var ceil: Float = 0.0
        var noiseFloorMutable = noiseFloor
        vDSP_vclip(normalizedSamples, 1, &noiseFloorMutable, &ceil, &normalizedSamples, 1, vDSP_Length(normalizedSamples.count))
    }
}




