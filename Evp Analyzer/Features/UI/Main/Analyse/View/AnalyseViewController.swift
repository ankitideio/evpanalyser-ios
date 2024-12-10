//
//  AnalyseViewController.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit
import Charts
//import DSWaveformImage
import AVFAudio
import SoundWave
import EZAudio
enum AudioState{
    case start
    case pause
    case stop
}
class AnalyseViewController: BaseViewController {
    //MARK: - IBOutlets & Properties
    @IBOutlet weak var waveView: UIView!
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var audioPlot: EZAudioPlot!
    
    @IBOutlet weak var shareBtn: UIButton!{
        didSet{
            shareBtn.layer.cornerRadius = shareBtn.frame.height / 2.0
        }
    }
    @IBOutlet weak var slider: UISlider!
    
    @IBOutlet weak var deleteAudioBtn: UIButton!{
        didSet{
            deleteAudioBtn.layer.cornerRadius = deleteAudioBtn.frame.height / 2.0
        }
    }
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var fileNameLabel: UILabel!
    @IBOutlet private var audioVisualizationView: AudioVisualizationView!
    
    var values = [ChartDataEntry]()
    var audioState : AudioState = .stop
//    let waveformView = WaveformLiveView()

    //var player: EZAudioPlayer?
    var controller = UIDocumentInteractionController()
   var player: AVAudioPlayer?
    var playerEzAudio: EZAudioPlayer?
    var seconds: Int = 0
    var currentRate: Float?
    private var isPlaying = false
    var audioViewModel = AnalyseViewModel()
    let noiseFloor: Float = -80
    var ezAudioPlotData: [Float] = []
    var audioVisualizationTimeInterval: TimeInterval = 0.05
    private var currentState: AudioRecodingState = .recorded {
        didSet {
            self.startBtn.setImage(self.currentState.buttonImage, for: .normal)
//            self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
        }
    }
  
         
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = AVAudioSession.sharedInstance()
        try! session.overrideOutputAudioPort(.speaker)
        NotificationCenter.default.addObserver(self, selector: #selector(self.play), name: Notification.Name(rawValue: "playAudio"), object: nil)
        self.setGraph()
        self.setupVisualisationView()
        self.setupAudioPlot()
     
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       // self.player = EZAudioPlayer(delegate: self)
        
        self.slider.value = 1
        self.currentRate = 1
//        if let player = AudioPlayerManager.shared.audioPlayer{
//            player.rate = 1
//        }
    }
    
 
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        playerEzAudio?.delegate = nil
        DispatchQueue.main.asyncAfter(deadline: .now()){
            self.values.removeAll()
            
            self.timerLabel.text = "00:00"
            self.startBtn.isSelected = false
            self.audioState = .stop
            self.player = nil
            self.playerEzAudio = nil
           
            self.playerEzAudio?.pause()
            AudioPlayerManager.shared.audioPlayer = nil
            self.audioPlot.clear()
            //        self.ezAudioPlot.removeFromSuperview()
            //        self.waveformView.reset()
            //        self.waveformView.removeFromSuperview()
            self.lineChartView.clear()
        }
    }

  
    
    //MARK: - IBActions
    
    @IBAction func sliderAction(_ sender: UISlider) {
        print("slider value :\(sender.value)")
//        player?.rate = sender.value
        self.currentRate = sender.value
        self.playerEzAudio?.pan = sender.value
        if let player = AudioPlayerManager.shared.audioPlayer{
            print("slider value :\(sender.value)")
            player.rate = sender.value
        }
       
    }
    
    @IBAction func shareAction(_ sender: Any) {
        let filesTab = self.tabBarController?.viewControllers?[2] as! FilesViewController
        
        if filesTab.selectedFile == ""{
            self.showAlert(title: "", msg: "There is no audio to share")
        }else{
            let audioURL = getDocumentsDirectory().appendingPathComponent("\(filesTab.selectedFile).m4a")
            
            let activityVC = UIActivityViewController(activityItems: [audioURL],applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func deleteAudioAction(_ sender: Any) {
        let alertController = UIAlertController(title: "Delete!", message: "Do you want to Delete this file?", preferredStyle: .alert)
        
        let noAction = UIAlertAction(title: "NO", style: .default)
        let yesAction = UIAlertAction(title: "YES", style: .default) { _ in
            let filesTab = self.tabBarController?.viewControllers?[2] as! FilesViewController
            self.deleteRecording(name: filesTab.selectedFile)
        }
        
        alertController.addAction(noAction)
        alertController.addAction(yesAction)
        
        self.present(alertController, animated: true)
    }
    
    func setupVisualisationView() {
        self.audioViewModel.audioMeteringLevelUpdate = { [weak self] meteringLevel in
            guard let self = self, self.audioVisualizationView.audioVisualizationMode == .write else {
                return
            }
            self.audioVisualizationView.add(meteringLevel: meteringLevel)
        }
        self.currentState = .ready
//        if self.viewModel.entry.id == "" {
//            self.currentState = .ready
//        }
        self.audioViewModel.audioDidFinish = { [weak self] in
            self?.currentState = .recorded
            self?.startBtn.isSelected = false
            self?.audioVisualizationView.stop()
        }
    }
 
    @IBAction func startPauseAudioAction(_ sender: Any) {
        self.startBtn.isSelected = !self.startBtn.isSelected
        
        //        if self.startBtn.isSelected {
        if self.currentState == .recorded || self.currentState == .paused {
            do{
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
                              try AVAudioSession.sharedInstance().setActive(true)
                
                self.setupAudioPlot()
                print("select")
               self.playAudioWithWave()
               
              
//                let duration = try self.audioViewModel.startPlaying()
                self.currentState = .playing
                self.audioVisualizationView.meteringLevels = self.audioViewModel.currentAudioRecord!.meteringLevels
                //                    self.audioVisualizationView.play(for: duration)
                if let player = AudioPlayerManager.shared.audioPlayer {
                    if let rate = self.currentRate {
                        player.rate = rate
                        
                        
                    }
                }
                }
            catch{
                
            }
            
        } else if self.currentState == .playing {
                self.playerEzAudio?.pause()
                self.playerEzAudio?.delegate = nil
          
          
//                    try self.audioViewModel.pausePlaying()
                    self.currentState = .paused
    
//            }
        }
    }
    
    //MARK: - Functions
    
    private func setupAudioPlot(){
        self.waveView.backgroundColor = UIColor.black
        self.audioPlot.plotType = .rolling
        self.audioPlot.gain = 2
        self.audioPlot.color = UIColor(red: 40/255, green: 199/255, blue: 89/255, alpha: 1.0)
//        waveformView.frame = CGRect(x: 0, y: 0, width: self.waveView.frame.size.width, height: self.waveView.frame.size.height)
//        self.audioPlot.backgroundColor = .white
//        self.audioPlot.color = .green
//        self.audioPlot.plotType = .rolling
//        self.audioPlot.shouldFill = true
//        self.audioPlot.shouldMirror = true
       
//        waveformView.configuration = waveformView.configuration.with(backgroundColor: .black, style:.filled(UIColor.darkGray), dampening: waveformView.configuration.dampening?.with(percentage: 0.3))
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
            self.audioViewModel.currentAudioRecord = SoundRecord(audioFilePathLocal: url, meteringLevels: outputArray)
        })
    }
    
    func playAudioWithWave(){
        let filesTab = self.tabBarController?.viewControllers?[2] as! FilesViewController
        
        let fileName = filesTab.selectedFile + ".m4a"
       
        let path = getDocumentsDirectory().appendingPathComponent(fileName)
      
        self.currentState = .recorded
        self.audioViewModel.currentAudioRecord = SoundRecord(audioFilePathLocal: path, meteringLevels: [])
        self.audioViewModel.currentAudioRecord!.meteringLevels = self.audioVisualizationView.scaleSoundDataToFitScreen()
        if FileManager.default.fileExists(atPath: path.path) {
            print("The file already exists at path")
            print("Audio Path---",path)
            if
                
                let audioFile = EZAudioFile(url: path) {
                
                playerEzAudio = EZAudioPlayer(audioFile: audioFile)
                playerEzAudio?.delegate = self
                playerEzAudio?.shouldLoop = false
                playerEzAudio?.play()
               
            }
            self.bindAudio(url: path)
//            self.waveformView.removeFromSuperview()
//            self.waveView.addSubview(waveformView)
          
            self.audioState = .start
        }
    }
 
   
    @objc func play() {
        let filesTab = self.tabBarController?.viewControllers?[2] as! FilesViewController
        
        let fileName = filesTab.selectedFile + ".m4a"
        self.fileNameLabel.text = filesTab.selectedFile
        let path = getDocumentsDirectory().appendingPathComponent(fileName)
      
        self.currentState = .recorded
        self.audioViewModel.currentAudioRecord = SoundRecord(audioFilePathLocal: path, meteringLevels: [])
        self.audioViewModel.currentAudioRecord!.meteringLevels = self.audioVisualizationView.scaleSoundDataToFitScreen()
        if FileManager.default.fileExists(atPath: path.path) {
            print("The file already exists at path")
            print("Audio Path---",path)
           
            self.bindAudio(url: path)
            
//            self.playerEzAudio?.delegate = self
//            self.waveformView.removeFromSuperview()
//            self.waveView.addSubview(waveformView)
          
        }
    }
  

    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        
        return documentsDirectory
    }
    
    func deleteRecording(name: String){
        let path = getDocumentsDirectory().appendingPathComponent(name.appending(".m4a"))
        let manager = FileManager.default
        
        if manager.fileExists(atPath: path.path) {
            
            do {
                try manager.removeItem(at: path)
                let userDefaults = UserDefaults.standard
                let filesTab = self.tabBarController?.viewControllers?[2] as! FilesViewController
                filesTab.selectedFile = ""
                self.fileNameLabel.text = ""
                filesTab.recordingData.removeAll(where: {$0.fileName == name})
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: filesTab.recordingData)
                userDefaults.set(encodedData, forKey: "recordedData")
                self.tabBarController?.selectedIndex = 2

            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("File is not exist.")
        }
    }
    
        //SetupGraph
    
    private func setGraph() {
        lineChartView.noDataFont = UIFont.systemFont(ofSize: 15.0)
        lineChartView.noDataTextColor = UIColor(red: 1.00, green: 0.75, blue: 0.00, alpha: 1.00)
        lineChartView.backgroundColor = UIColor.black
        lineChartView.setScaleMinima(Double(values.count) / 500.0, scaleY: 1.0)
        lineChartView.leftAxis.drawLabelsEnabled = false
        lineChartView.rightAxis.drawLabelsEnabled = false
        lineChartView.xAxis.drawLabelsEnabled = false
        lineChartView.legend.enabled = false
        lineChartView.doubleTapToZoomEnabled = false
        lineChartView.scaleYEnabled = false
    }
    
        // ------Graph Populate Data------
    
    private func setData(count: Float){
        values.append(ChartDataEntry(x: Double(values.count), y: Double(count)))
        var set1: LineChartDataSet
        set1 = LineChartDataSet(entries: values, label: "DataSet 1")
        set1.drawIconsEnabled = false
        set1.circleRadius = 0.0
        set1.circleHoleRadius = 0.0
        set1.drawCirclesEnabled = false
        set1.drawCircleHoleEnabled = false
        set1.mode = LineChartDataSet.Mode.cubicBezier
        set1.colors = [UIColor.red]
        var dataSets: [ILineChartDataSet] = [ILineChartDataSet]()
        dataSets.append(set1)
        let data = LineChartData(dataSets: dataSets)
        lineChartView.data = data
        
        lineChartView.centerViewTo(xValue: Double(values.count), yValue: Double(count) / 2, axis: YAxis.AxisDependency.left)
    }
    func formatTime(_ seconds: Int) -> String {
           // Format seconds into HH:MM:SS
           let formattedHours = String(format: "%02d", seconds / 3600)
           let formattedMinutes = String(format: "%02d", (seconds % 3600) / 60)
           let formattedSeconds = String(format: "%02d", seconds % 60)
           
           return "\(formattedHours):\(formattedMinutes)"
       }
}


extension AnalyseViewController: EZAudioPlayerDelegate{
   
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, in audioFile: EZAudioFile!) {
        
        DispatchQueue.main.async {
         
            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            self.audioPlot.setNeedsDisplay()
            self.setData(count: buffer[0]!.pointee)
        }
    }
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, reachedEndOf audioFile: EZAudioFile!) {
        
        DispatchQueue.main.async {
            self.audioState = .stop
            self.currentState = .paused
            self.audioPlot.clear()
            self.startBtn.isSelected = false
            self.startBtn.setImage(UIImage(named: "play-button"), for: .normal)
            print("End audio")
            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                self.timerLabel.text = "00:00"
                self.audioPlot.color = .clear
            }
        }
    }
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, updatedPosition framePosition: Int64, in audioFile: EZAudioFile!) {
     
        DispatchQueue.main.async {
            self.seconds += 1
            let formattedTime = self.formatTime(self.seconds)
            
           self.timerLabel.text = formattedTime
        }
    }
}

// MARK:- Loading metering from audio url
extension AnalyseViewController {
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





