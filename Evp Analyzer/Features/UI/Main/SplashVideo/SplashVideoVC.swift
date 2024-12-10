//
//  SplashVideoVC.swift
//  Evp Analyzer
//
//  Created by meet sharma on 02/12/23.
//

import UIKit
import AVFoundation
import AVKit

class SplashVideoVC: UIViewController {
    
    @IBOutlet weak var videoVw: UIView!
    
    var player: AVPlayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playVideo()
        
    }
    func playVideo() {
        
        if let videoURL = Bundle.main.url(forResource: "splash", withExtension: "mp4") {
            
            player = AVPlayer(url: videoURL)
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = videoVw.bounds
//            playerLayer.videoGravity = AVLayerVideoGravity.resize
            videoVw.layer.addSublayer(playerLayer)
            NotificationCenter.default.addObserver(self,selector:#selector(playerDidFinishPlaying),name: .AVPlayerItemDidPlayToEndTime,object: player?.currentItem)
            player?.play()
   
        }
    }
    @objc func playerDidFinishPlaying() {
        player?.pause()
           NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainVideoVC") as! MainVideoVC
        self.navigationController?.pushViewController(vc, animated: false)
       }
    
    @IBAction func actionSkip(_ sender: UIButton) {
        player?.pause()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
     let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainVideoVC") as! MainVideoVC
     self.navigationController?.pushViewController(vc, animated: false)
    }
    
    
}
