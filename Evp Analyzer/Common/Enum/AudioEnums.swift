//
//  AudioEnums.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 21/08/2022.
//

import UIKit
import SoundWave

enum AudioErrorType: Error {
    case alreadyRecording
    case alreadyPlaying
    case notCurrentlyPlaying
    case audioFileWrongPath
    case recordFailed
    case playFailed
    case recordPermissionNotGranted
    case internalError
}

extension AudioErrorType: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .alreadyRecording:
            return "The application is currently recording sounds"
        case .alreadyPlaying:
            return "The application is already playing a sound"
        case .notCurrentlyPlaying:
            return "The application is not currently playing"
        case .audioFileWrongPath:
            return "Invalid path for audio file"
        case .recordFailed:
            return "Unable to record sound at the moment, please try again"
        case .playFailed:
            return "Unable to play sound at the moment, please try again"
        case .recordPermissionNotGranted:
            return "Unable to record sound because the permission has not been granted. This can be changed in your settings."
        case .internalError:
            return "An error occured while trying to process audio command, please try again"
        }
    }
}

enum AudioRecodingState {
    case ready
    case recording
    case recorded
    case playing
    case paused

    var buttonImage: UIImage {
        switch self {
        case .ready:
            return UIImage(named: "play-button") ?? UIImage()
        case .recording:
            return UIImage(named: "play-button") ?? UIImage()
        case .recorded, .paused:
            return UIImage(named: "play-button") ?? UIImage()
        case .playing:
            return UIImage(named: "icons8-pause-button-100") ?? UIImage()
        }
    }

    var audioVisualizationMode: AudioVisualizationView.AudioVisualizationMode {
        switch self {
        case .ready, .recording:
            return .write
        case .paused, .playing, .recorded:
            return .read
        }
    }
}
