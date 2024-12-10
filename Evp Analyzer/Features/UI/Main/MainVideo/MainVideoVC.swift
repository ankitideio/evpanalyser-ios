//
//  MainVideoVC.swift
//  Evp Analyzer
//
//  Created by meet sharma on 02/12/23.
//

import UIKit
import AVFoundation

class MainVideoVC: UIViewController {
    
    @IBOutlet weak var vwBlank: UIView!
    @IBOutlet weak var videoVw: UIView!
    var player: AVPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()

       
    }
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now()+1.0){
            self.vwBlank.isHidden = true
            self.playVideo()
        }
    }
    func playVideo() {
        
        if let videoURL = Bundle.main.url(forResource: "evphunter", withExtension: "mp4") {
            
            player = AVPlayer(url: videoURL)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = videoVw.bounds
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
       
            videoVw.layer.addSublayer(playerLayer)
            NotificationCenter.default.addObserver(self,selector:#selector(playerDidFinishPlaying),name: .AVPlayerItemDidPlayToEndTime,object: player?.currentItem)
            player?.play()
   
        }
    }
    @objc func playerDidFinishPlaying() {
          player?.pause()
           NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        SceneDelegate().initializeTabBar()
       }

    @IBAction func actionSkip(_ sender: UIButton) {
        player?.pause()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
     SceneDelegate().initializeTabBar()
    }
}
