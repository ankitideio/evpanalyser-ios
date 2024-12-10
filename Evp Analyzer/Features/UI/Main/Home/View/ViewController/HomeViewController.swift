//
//  HomeViewController.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit
import Charts
import AVFoundation
//import DSWaveformImage
import GoogleMobileAds
import SmartGauge
import SoundWave
import EZAudio
class HomeViewController: BaseViewController {
    
    //MARK: - IBOutlets & Properties
   
    @IBOutlet weak var auditPlot: EZAudioPlot!
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var recordFileNameLabel: UILabel!
    @IBOutlet weak var recordBtn: UIButton!
    @IBOutlet weak var decibleValueLabel: UILabel!
    @IBOutlet weak var gaugeValueLabel: UILabel!
    @IBOutlet weak var gaugeView: SmartGauge!
    @IBOutlet private var audioVisualizationView: AudioVisualizationView!
    
    var values = [ChartDataEntry]()
    private var microphone = EZMicrophone()
    var isAudioRecordingGranted: Bool!
    var audioRecorder: AVAudioRecorder?
    var meterTimer:Timer?
    var recordingSession: AVAudioSession!
//    let waveformView = WaveformLiveView()
    var date = ""
    private var interstitial: GADInterstitialAd?

    private var isRecording = false {
        
        didSet {
            
            if isRecording {
                
                //self.audioPlot.clear()
               // self.microphone.startFetchingAudio()
                //Start recording
//                self.setup_recorder()
                meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self, selector:#selector(self.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            } else {
                //self.microphone.stopFetchingAudio()
                self.finishAudioRecording(success: true)
                //Stop Recording and save audio
            }
        }
    }
    
    private var currentState: AudioRecodingState = .ready {
        didSet {
            self.recordBtn.setImage(self.currentState.buttonImage, for: .normal)
            self.audioVisualizationView.audioVisualizationMode = self.currentState.audioVisualizationMode
        }
    }
    
    var audioViewModel = HomeViewModel()
    
    //MARK: - ViewCycleMethods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestBluetoothMicrophonePermission()
        self.setupGaugeView()
        self.check_record_permission()
        self.setGraph()
        self.setupAudioPlot()
        self.setupVisualisationView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        audioRecorder?.stop()
        audioRecorder = nil
        meterTimer?.invalidate()
        DispatchQueue.main.async {
            self.resetValues()
        }
    }
    func requestBluetoothMicrophonePermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if granted {
                // Permission granted, you can now access the Bluetooth microphone
                print("Bluetooth microphone permission granted.")
            } else {
                // Permission denied or restricted
                print("Bluetooth microphone permission denied.")
            }
        }
    }

    func checkBluetoothMicrophonePermission() {
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission

        switch permissionStatus {
        case .granted:
            print("Bluetooth microphone permission already granted.")
            // Access the Bluetooth microphone here
        case .denied:
            print("Bluetooth microphone permission denied.")
            // Inform the user about the denied permission
        case .undetermined:
            print("Bluetooth microphone permission not determined. Requesting...")
            requestBluetoothMicrophonePermission()
        @unknown default:
            print("Unexpected permission status.")
        }
    }
    func showAlert(with error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        })
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    //MARK: - IBActions
    
    @IBAction func recordAction(_ sender: Any) {
//        self.recordBtn.isSelected = !self.recordBtn.isSelected
        //        isRecording = !isRecording
        if self.currentState == .ready || self.currentState == .recorded{
            self.checkBluetoothMicrophonePermission()
            self.audioViewModel.startRecording(url: self.getFileUrl()) { [weak self] soundRecord, error in
                if let error = error {
                    self?.showAlert(with: error)
                    return
                }
                self?.auditPlot.clear()
                self?.auditPlot.isHidden = false
                self?.currentState = .recording
                self?.recordBtn.isSelected = true
                self?.meterTimer = Timer.scheduledTimer(timeInterval: 0.1, target:self!, selector:#selector(self?.updateAudioMeter(timer:)), userInfo:nil, repeats:true)
            }
        } else {
            switch self.currentState {
            case .recording:

                self.audioViewModel.currentAudioRecord!.meteringLevels = self.audioVisualizationView.scaleSoundDataToFitScreen()
                self.audioVisualizationView.audioVisualizationMode = .read
                do {
                    try self.audioViewModel.stopRecording()
                    self.currentState = .recorded
                    self.recordBtn.isSelected = false
                    if let audioData = self.audioViewModel.currentAudioRecord?.audioFilePathLocal {
                        print(audioData)
                        self.finishAudioRecording(success: true)
                    }
                } catch {
                    self.currentState = .ready
                    self.showAlert(with: error)
                }
            default:
                print("")
            }
        }
    }
    
    //MARK: - Functions'
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
            self?.recordBtn.isSelected = false
            self?.audioVisualizationView.stop()
        }
    }
    
    private func setupGaugeView() {
        gaugeView.numberOfMajorTicks = 10
        gaugeView.numberOfMinorTicks = 3
        
        gaugeView.gaugeAngle = 65
        gaugeView.gaugeValue = CGFloat()
        self.gaugeValueLabel.text = "0.0 db"
        gaugeView.valueFont = UIFont.systemFont(ofSize: 10, weight: .thin)
        gaugeView.gaugeTrackColor = UIColor.blue
        gaugeView.enableLegends = false
        gaugeView.gaugeViewPercentage = 0.70
        gaugeView.legendSize = CGSize(width: 25, height: 20)
        if let font = CTFontCreateUIFontForLanguage(.system, 30.0, nil) {
            gaugeView.legendFont = font
        }
        gaugeView.coveredTickValueColor = UIColor.darkGray
        
        let first = SGRanges("0 - 60", fromValue: 0, toValue: 60, color: GaugeRangeColorsSet.first)
        let second = SGRanges("60 - 80", fromValue: 60, toValue: 80, color: GaugeRangeColorsSet.second)
        let third = SGRanges("80 - 100", fromValue: 80, toValue: 100, color: GaugeRangeColorsSet.third)
        
        print(third.toValue)
        gaugeView.rangesList = [first, second, third]
        gaugeView.gaugeMaxValue = third.toValue
        gaugeView.enableRangeColorIndicator = true
      
    }
    
    func check_record_permission()
    {
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            isAudioRecordingGranted = true
            break
        case AVAudioSession.RecordPermission.denied:
            isAudioRecordingGranted = false
            break
        case AVAudioSession.RecordPermission.undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ (allowed) in
                if allowed {
                    self.isAudioRecordingGranted = true
                } else {
                    self.isAudioRecordingGranted = false
                }
            })
            break
        default:
            break
        }
    }
    
    //setup audio plot
    
    private func setupAudioPlot(){
        self.auditPlot.plotType = .rolling
      
//        waveformView.frame = CGRect(x: 0, y: 0, width: self.audioPlot.frame.size.width, height: self.audioPlot.frame.size.height)
//        waveformView.configuration = waveformView.configuration.with(backgroundColor: .black, style:.filled(UIColor.darkGray), dampening: waveformView.configuration.dampening?.with(percentage: 0.3), position: .middle)
        
        //        self.audioPlot.color           = UIColor(red: 0.29, green: 0.51, blue: 0.42, alpha: 1.00)
        //        self.audioPlot.plotType        = EZPlotType.rolling
        //        self.audioPlot.shouldFill      = true
        //        self.audioPlot.shouldMirror    = true
    }
    
    // Setup Graph
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
    
    func setup_recorder()
    {
        
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode:.default, options: [.allowBluetooth,.defaultToSpeaker])
            try recordingSession.setActive(true)
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            recordingSession.requestRecordPermission() { [weak self] allowed in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if allowed {
                        
                      
                        do {
                            let settings: [String: Any] = [
                                AVFormatIDKey: kAudioFormatLinearPCM,
                                AVSampleRateKey: 44100.0,
                                AVNumberOfChannelsKey: 2,
                                
                                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
                            ]
                            
                            self.audioRecorder = try AVAudioRecorder(url: self.getFileUrl(), settings: settings)
                            self.audioRecorder?.delegate = self
                            self.audioRecorder?.isMeteringEnabled = true
                            
//                            self.audioPlot.addSubview(self.waveformView)
                            self.audioRecorder?.prepareToRecord()
                            self.audioRecorder?.record()
                            
                        } catch {
                            self.finishAudioRecording(success: false)
                        }
                    } else {
                        // failed to record!
                        self.showAlert(title: "", msg:"Allow microphone permission from settings in order to record audio.")
                        print("recording failed")
                    }
                }
            }
        } catch let error {
            // failed to record!
            if error.localizedDescription.contains("561017449"){
                self.showAlert(title: "", msg: "The app isn’t allowed to record the audio because the mic is in use by another app.")
            }else{
                self.showAlert(title: "", msg: error.localizedDescription)
            }
        }
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL
    {
        let date = Date()
        let dateFormat = DateFormatter()
        let dateFormat1 = DateFormatter()
        dateFormat.dateFormat = "yyyyMMdd_HH_mm_ss"
        dateFormat1.dateFormat = "d MMM, yyyy"
        let dateString = dateFormat.string(from: date)
        self.date = dateFormat1.string(from: date)
        let filename = "recording_\(dateString)"
        self.recordFileNameLabel.text = filename
        let filePath = getDocumentsDirectory().appendingPathComponent("\(filename).m4a")
        return filePath
    }
    
    @objc func updateAudioMeter(timer: Timer)
    {
        if let recorder = AudioRecorderManager.shared.recorder {
            if recorder.isRecording
            {
              
                self.microphone = EZMicrophone(delegate: self, startsImmediately: true)
                let hr = Int((recorder.currentTime / 60) / 60)
                let min = Int(recorder.currentTime / 60)
                let sec = Int(recorder.currentTime.truncatingRemainder(dividingBy: 60))
                print(hr)
                let totalTimeString = String(format: "%02d:%02d", min, sec)
                self.timerLabel.text = totalTimeString
                recorder.updateMeters()
                
                let dataPoint =  recorder.averagePower(forChannel: 0)
                print(dataPoint)
                print("dataPoint")
                var dataPointGauge = dataPoint// / 3
                dataPointGauge = dataPointGauge + 65//abs(dataPointGauge) + abs(dataPointGauge)
//                if dataPoint > 0 {
//                    dataPointGauge = dataPoint / 3
//                } else {
//                    dataPointGauge = dataPoint * 4
//                }
                DispatchQueue.main.async {
                    print(dataPointGauge)
                    print("dataPointGauge")
//                    let currentAmplitude = 1 - pow(10, recorder.averagePower(forChannel: 0) / 20)
//                    if dataPointGauge > Float(-64.9) {
//                        dataPointGauge = Float(-65.0)
//                    } else if dataPointGauge < Float(-150.9) {
//                        dataPointGauge = Float(-130.0)
//                    }
//                    print(dataPointGauge)
//                    print("dataPointGauge")
//                    if dataPointGauge > -1 {
//                        print(dataPointGauge)
//                        print("dataPointGauge")
//                    } else {
//                        print("ander aing \(dataPointGauge)")
                    self.gaugeView.gaugeValue = CGFloat(abs(dataPointGauge))
//                    }
                
                    let y = Float(round(1000 * abs(dataPointGauge)) / 1000)
                    self.gaugeValueLabel.text = "\(y) db"
                    
                    //                self.decibleValueLabel.text = "\(dataPoint) dB"
//                    self.waveformView.add(samples: [currentAmplitude, currentAmplitude,currentAmplitude])
                    self.setData(count: abs(dataPointGauge) / 2)
                }
            }
        }
    }
    
    func resetValues(){
//        self.waveformView.reset()
        self.values.removeAll()
        self.date = ""
        self.recordFileNameLabel.text = ""
//        self.waveformView.removeFromSuperview()
        self.lineChartView.clear()
        self.timerLabel.text = "00:00"
    }
    
    func finishAudioRecording(success: Bool)
    {
        self.currentState = .ready
        if success
        {
            audioRecorder?.stop()
            audioRecorder = nil
            meterTimer?.invalidate()
            auditPlot.isHidden = true
            if let decoded  = UserDefaults.standard.data(forKey: "recordedData"){
                var decodedRecordingData = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [RecordingModel]
                decodedRecordingData.append(RecordingModel(fileName: self.recordFileNameLabel.text!, date: self.date))
                let userDefaults = UserDefaults.standard
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: decodedRecordingData)
                userDefaults.set(encodedData, forKey: "recordedData")
            }else{
                let recordingData = [RecordingModel(fileName: self.recordFileNameLabel.text!, date: self.date)]
                let userDefaults = UserDefaults.standard
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: recordingData )
                userDefaults.set(encodedData, forKey: "recordedData")
            }
    
            DispatchQueue.main.async {
                self.resetValues()
                self.gaugeView.gaugeValue = CGFloat()
                self.gaugeValueLabel.text = "0.0 db"
                self.audioVisualizationView.reset()
                self.currentState = .ready
                self.showAlert(title: "", msg: "Recording saved successfully")
            }
            print("recorded successfully.")
        }
        else
        {
            self.showAlert(title: "", msg: "Recording failed.")
        }
    }
}


extension HomeViewController: EZMicrophoneDelegate, EZRecorderDelegate{
    func microphone(_ microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32) {
            
            self.auditPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            self.auditPlot.setNeedsDisplay()
        
        //        DispatchQueue.main.async {
        //            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
        //            if let dataPoint = buffer[0]?.pointee{
        //                self.setData(count: dataPoint)
        //            }
        //        }
    }
}


extension HomeViewController: AVAudioRecorderDelegate{
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool)
    {
        if !flag
        {
            finishAudioRecording(success: false)
        }
    }
}


//float power = 0;
//for (int i = 0; i < 441; i++) {
//  float normalized = (float)s[i] / 32768.0f;
//  power = power + (normalized * normalized);
//}
