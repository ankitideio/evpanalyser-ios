//
//  AudioManager.swift
//  Barechats
//
//  Created by Rameez Hasan on 06/10/2021.
//

import Foundation
import AVFoundation
import Accelerate

class AudioPlayerManager: NSObject {
    static let shared = AudioPlayerManager()

    var isRunning: Bool {
        guard let audioPlayer = self.audioPlayer, audioPlayer.isPlaying else {
            return false
        }
        return true
    }

    var audioPlayer: AVAudioPlayer?
    var player: AVPlayer?
    var audioMeteringLevelTimer: Timer?

    // MARK: - Reinit and play from the beginning

    func play(at url: URL, with audioVisualizationTimeInterval: TimeInterval = 0.05) throws -> TimeInterval {
        if AudioRecorderManager.shared.isRunning {
            print("Audio Player did fail to start: AVFoundation is recording")
            throw AudioErrorType.alreadyRecording
        }
        
        if self.isRunning {
            print("Audio Player did fail to start: already playing a file")
            throw AudioErrorType.alreadyPlaying
        }
        
        do {
            let data =  try Data.init(contentsOf: url)
            try self.audioPlayer = AVAudioPlayer.init(data: data)//AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.updateMeters()
            self.audioPlayer?.enableRate = true
        } catch {
            print(error)
            print("error")
        }
        self.setupPlayer(with: audioVisualizationTimeInterval)
        print("Started to play sound")
        
        self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
                                                            selector: #selector(AudioPlayerManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        
        return self.audioPlayer?.duration ?? TimeInterval.init(0.0)
    }

    func play(_ data: Data, with audioVisualizationTimeInterval: TimeInterval = 0.05) throws -> TimeInterval {
        try self.audioPlayer = AVAudioPlayer(data: data)
        self.setupPlayer(with: audioVisualizationTimeInterval)
        print("Started to play sound")

        return self.audioPlayer!.duration
    }
    
    private func setupPlayer(with audioVisualizationTimeInterval: TimeInterval) {
        if let player = self.audioPlayer {
            player.play()
            player.isMeteringEnabled = true
            player.delegate = self
            
            self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
                selector: #selector(AudioPlayerManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        }
    }

    // MARK: - Resume and pause current if exists

    func resume() throws -> TimeInterval {
        if self.audioPlayer?.play() == false {
            print("Audio Player did fail to resume for internal reason")
            throw AudioErrorType.internalError
        }

        print("Resumed sound")
        return (self.audioPlayer?.duration ?? 0) - (self.audioPlayer?.currentTime ?? 0)
    }

    func pause() throws {
        if !self.isRunning {
            print("Audio Player did fail to start: there is nothing currently playing")
            throw AudioErrorType.notCurrentlyPlaying
        }

        self.audioPlayer?.pause()
        print("Paused current playing sound")
    }

    func stop() throws {
        if !self.isRunning {
            print("Audio Player did fail to stop: there is nothing currently playing")
            throw AudioErrorType.notCurrentlyPlaying
        }
        
        self.audioPlayer?.stop()
        print("Audio player stopped")
    }
    
    // MARK: - Private

    @objc private func timerDidUpdateMeter() {
        if self.isRunning {
            self.audioPlayer!.updateMeters()
            let averagePower = self.audioPlayer!.averagePower(forChannel: 0)
            let percentage: Float = pow(10, (0.05 * averagePower))
            NotificationCenter.default.post(name: .audioPlayerManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
        }
    }
}

extension AudioPlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        NotificationCenter.default.post(name: .audioPlayerManagerMeteringLevelDidFinishNotification, object: self)
    }
}

extension Notification.Name {
    static let audioPlayerManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidUpdateNotification")
    static let audioPlayerManagerMeteringLevelDidFinishNotification = Notification.Name("AudioPlayerManagerMeteringLevelDidFinishNotification")
}


let audioPercentageUserInfoKey = "percentage"

final class AudioRecorderManager: NSObject {
    let audioFileNamePrefix = "barechats-Audio-"
    let encoderBitRate: Int = 320000
    let numberOfChannels: Int = 2
    let sampleRate: Double = 44100.0

    static let shared = AudioRecorderManager()

    var isPermissionGranted = false
    var isRunning: Bool {
        guard let recorder = self.recorder, recorder.isRecording else {
            return false
        }
        return true
    }

    var currentRecordPath: URL?

    var recorder: AVAudioRecorder?
    private var audioMeteringLevelTimer: Timer?

    func askPermission(completion: ((Bool) -> Void)? = nil) {
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            self?.isPermissionGranted = granted
            completion?(granted)
            print("Audio Recorder did not grant permission")
        }
    }

    func startRecording(with audioVisualizationTimeInterval: TimeInterval = 0.05,url: URL, completion: @escaping (URL?, Error?) -> Void) {
        func startRecordingReturn() {
            do {
                completion(try internalStartRecording(with: audioVisualizationTimeInterval, url: url), nil)
            } catch {
                completion(nil, error)
            }
        }
        
        if !self.isPermissionGranted {
            self.askPermission { granted in
                startRecordingReturn()
            }
        } else {
            startRecordingReturn()
        }
    }
    
    fileprivate func internalStartRecording(with audioVisualizationTimeInterval: TimeInterval,url: URL) throws -> URL {
        if self.isRunning {
            throw AudioErrorType.alreadyPlaying
        }
        
        let recordSettings = [
            AVFormatIDKey: NSNumber(value:kAudioFormatLinearPCM),//NSNumber(value: kAudioFormatMPEGLayer3),//NSNumber(value:kAudioFormatAppleLossless),
            AVEncoderAudioQualityKey : AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey : self.encoderBitRate,
            AVNumberOfChannelsKey: self.numberOfChannels,
            AVSampleRateKey : self.sampleRate
        ] as [String : Any]
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
//        guard let path = URL.documentsPath(forFileName: self.audioFileNamePrefix + NSUUID().uuidString) else {
//            print("Incorrect path for new audio file")
//            throw AudioErrorType.audioFileWrongPath
//        }
        
//        let path = documentsDirectory.appendingPathComponent("\(self.audioFileNamePrefix)\(UUID().uuidString).m4a")
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.allowBluetooth,.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)
        
        self.recorder = try AVAudioRecorder(url: url, settings: recordSettings)
        self.recorder!.delegate = self
        self.recorder!.isMeteringEnabled = true
        
        if !self.recorder!.prepareToRecord() {
            print("Audio Recorder prepare failed")
            throw AudioErrorType.recordFailed
        }
        
        if !self.recorder!.record() {
            print("Audio Recorder start failed")
            throw AudioErrorType.recordFailed
        }
        
        self.audioMeteringLevelTimer = Timer.scheduledTimer(timeInterval: audioVisualizationTimeInterval, target: self,
            selector: #selector(AudioRecorderManager.timerDidUpdateMeter), userInfo: nil, repeats: true)
        
        print("Audio Recorder did start - creating file at index: \(url.absoluteString)")
        
        self.currentRecordPath = url
        return url
    }

    func stopRecording() throws {
        self.audioMeteringLevelTimer?.invalidate()
        self.audioMeteringLevelTimer = nil
        
        if !self.isRunning {
            print("Audio Recorder did fail to stop")
            throw AudioErrorType.notCurrentlyPlaying
        }
        
        self.recorder!.stop()
        print("Audio Recorder did stop successfully")
    }

    func reset() throws {
        if self.isRunning {
            print("Audio Recorder tried to remove recording before stopping it")
            throw AudioErrorType.alreadyRecording
        }
        
        self.recorder?.deleteRecording()
        self.recorder = nil
        self.currentRecordPath = nil
        
        print("Audio Recorder did remove current record successfully")
    }

    @objc func timerDidUpdateMeter() {
        if self.isRunning {
            self.recorder!.updateMeters()
            let averagePower = recorder!.averagePower(forChannel: 0)
            let percentage: Float = pow(10, (0.05 * averagePower))
            NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidUpdateNotification, object: self, userInfo: [audioPercentageUserInfoKey: percentage])
        }
    }
}

extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFinishNotification, object: self)
        print("Audio Recorder finished successfully")
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        NotificationCenter.default.post(name: .audioRecorderManagerMeteringLevelDidFailNotification, object: self)
        print("Audio Recorder error")
    }
}

extension Notification.Name {
    static let audioRecorderManagerMeteringLevelDidUpdateNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidUpdateNotification")
    static let audioRecorderManagerMeteringLevelDidFinishNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFinishNotification")
    static let audioRecorderManagerMeteringLevelDidFailNotification = Notification.Name("AudioRecorderManagerMeteringLevelDidFailNotification")
    // Refresh Home Page
    static let homePageDataUpdateNotificationObserver = Notification.Name("HomePageDataUpdateNotificationObserver")
}

final class AudioContext {
    
    /// The audio asset URL used to load the context
    public let audioURL: URL
    
    /// Total number of samples in loaded asset
    public let totalSamples: Int
    
    /// Loaded asset
    public let asset: AVAsset
    
    // Loaded assetTrack
    public let assetTrack: AVAssetTrack
    
    private init(audioURL: URL, totalSamples: Int, asset: AVAsset, assetTrack: AVAssetTrack) {
        self.audioURL = audioURL
        self.totalSamples = totalSamples
        self.asset = asset
        self.assetTrack = assetTrack
    }
    
    public static func load(fromAudioURL audioURL: URL, completionHandler: @escaping (_ audioContext: AudioContext?) -> ()) {
        let asset = AVURLAsset(url: audioURL, options: [AVURLAssetPreferPreciseDurationAndTimingKey: NSNumber(value: true as Bool)])
        
        guard let assetTrack = asset.tracks(withMediaType: AVMediaType.audio).first else {
//            fatalError("Couldn't load AVAssetTrack")
            return
        }
        
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: "duration", error: &error)
            switch status {
            case .loaded:
                guard
                    let formatDescriptions = assetTrack.formatDescriptions as? [CMAudioFormatDescription],
                    let audioFormatDesc = formatDescriptions.first,
                    let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(audioFormatDesc)
                else { break }
                
                let totalSamples = Int((asbd.pointee.mSampleRate) * Float64(asset.duration.value) / Float64(asset.duration.timescale))
                let audioContext = AudioContext(audioURL: audioURL, totalSamples: totalSamples, asset: asset, assetTrack: assetTrack)
                completionHandler(audioContext)
                return
                
            case .failed, .cancelled, .loading, .unknown:
                print("Couldn't load asset: \(error?.localizedDescription ?? "Unknown error")")
            }
            
            completionHandler(nil)
        }
    }
}
