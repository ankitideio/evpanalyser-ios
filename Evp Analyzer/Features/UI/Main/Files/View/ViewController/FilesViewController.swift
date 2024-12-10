//
//  FilesViewController.swift
//  Evp Analyzer
//
//  Created by Rameez Hasan on 07/06/2022.
//

import UIKit
import EZAudio

class FilesViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordingCountLabel: UILabel!
    
    var recordingData = [RecordingModel]()
    var selectedFile = ""
    var player: EZAudioPlayer?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        let session = AVAudioSession.sharedInstance()
        try! session.overrideOutputAudioPort(.speaker)
        
        let nibName = UINib(nibName: "FilesListingTableViewCell", bundle:nil)
        self.tableView.register(nibName, forCellReuseIdentifier: "FilesListingTableViewCell")
        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        for (i,_) in self.recordingData.enumerated(){
            if let cell = tableView.cellForRow(at: IndexPath(row: i, section: 0)) as? FilesListingTableViewCell{
                cell.moreMenuView.isHidden = true
                if cell.currentState == .playing {
                    do {
                        try cell.pausePlaying()
                       
                        cell.currentState = .paused
    //                    self.waveView.pause()
                        cell.audioPlayer?.delegate = nil
                        
                        cell.audioPlayer?.pause()
                        
                        print("pause audio----")
                    } catch {
    //                    self.showAlert(with: error)
                    }
                }
                        
                        print("pause audio----")
                   
            }
            
        }
     
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.player = EZAudioPlayer(delegate: self)
        if let decoded  = UserDefaults.standard.data(forKey: "recordedData"){
            let decodedRecordingData = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [RecordingModel]
            self.recordingData = decodedRecordingData
            for i in 0..<self.recordingData.count {
                self.recordingData[i].url = self.getAudioUrl(name: self.recordingData[i].fileName)
            }
            self.recordingCountLabel.text = self.recordingData.count == 1 ? "\(self.recordingData.count) recording" : "\(self.recordingData.count) recordings"
        }
        
        self.tableView.reloadData()
    }
    
    
    //MARK: - Functions
    
    func shareAudio(name: String){
        
        let audioURL = getDocumentsDirectory().appendingPathComponent(name.appending(".m4a"))

        let activityVC = UIActivityViewController(activityItems: [audioURL],applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getAudioUrl(name: String) -> URL {
        let path = getDocumentsDirectory().appendingPathComponent(name.appending(".m4a"))
        return path
    }
    
    func deleteRecording(name: String, index: Int){
        let path = getDocumentsDirectory().appendingPathComponent(name.appending(".m4a"))
        let manager = FileManager.default
        
        if manager.fileExists(atPath: path.path) {
            
            do {
                try manager.removeItem(at: path)
                self.recordingData.remove(at: index)
                
                let userDefaults = UserDefaults.standard
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.recordingData)
                userDefaults.set(encodedData, forKey: "recordedData")
                
                self.recordingCountLabel.text = self.recordingData.count == 1 ? "\(self.recordingData.count) recording" : "\(self.recordingData.count) recordings"

                
                self.tableView.reloadData()
            } catch {
                print(error.localizedDescription)
            }
        } else {
            print("File is not exist.")
        }
    }
}


extension FilesViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.recordingData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilesListingTableViewCell", for: indexPath) as! FilesListingTableViewCell
        
//        cell.filenameLabel.text = self.recordingData[indexPath.row].fileName
//        cell.dateLabel.text = self.recordingData[indexPath.row].date
      
            cell.bindData(model: self.recordingData[indexPath.row])
            cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedFile = self.recordingData[indexPath.row].fileName
        let audioURL = getDocumentsDirectory().appendingPathComponent("\(self.recordingData[indexPath.row].fileName).m4a")
        
        self.tabBarController?.selectedIndex = 1
        NotificationCenter.default.post(name: Notification.Name(rawValue: "playAudio"), object: nil, userInfo: nil)
    }
}

extension FilesViewController: FilesListingTableViewCellDelegate{
    func deleteButtonTapped(_ cell: FilesListingTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            cell.moreMenuView.isHidden = true
            let recording = self.recordingData[indexPath.row]
            self.deleteRecording(name: recording.fileName,index: indexPath.row)
        }
        self.tableView.reloadData()
    }
    
    func shareButtonTapped(_ cell: FilesListingTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            cell.moreMenuView.isHidden = true
            let recording = self.recordingData[indexPath.row]
            self.shareAudio(name: recording.fileName)
        }
    }
}

extension FilesViewController: EZAudioPlayerDelegate{
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, in audioFile: EZAudioFile!) {
        print("abc")
    }
}

extension FilesListingTableViewCell: EZAudioPlayerDelegate{
    
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, playedAudio buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>?>!, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32, in audioFile: EZAudioFile!) {
       
        DispatchQueue.main.async {
            
            self.audioPlot.updateBuffer(buffer[0], withBufferSize: bufferSize)
            self.audioPlot.setNeedsDisplay()
            
        }
    }
    func audioPlayer(_ audioPlayer: EZAudioPlayer!, reachedEndOf audioFile: EZAudioFile!) {
        self.audioPlayer?.pause()
      
    }
}
