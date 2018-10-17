//
//  PreViewController.swift
//  ARStories
//
//  Created by Antony Raphel on 05/10/17.
//

import UIKit
import AVFoundation
import AVKit
import CoreMedia

class PreViewController: UIViewController, SegmentedProgressBarDelegate {

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var userProfileImage: UIImageView!
    @IBOutlet weak var lblUserName: UILabel!
    
    var pageIndex : Int = 0
    var items: [UserDetails] = []
    var item: [Content] = []
    var SPB: SegmentedProgressBar!
    var player: AVPlayer!
    let loader = ImageLoader()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        userProfileImage.layer.cornerRadius = self.userProfileImage.frame.size.height / 2;
        userProfileImage.imageFromServerURL(items[pageIndex].imageUrl)
        lblUserName.text = items[pageIndex].name
        item = items[pageIndex].content
        
        SPB = SegmentedProgressBar(numberOfSegments: item.count, duration: 5)
        if #available(iOS 11.0, *) {
            SPB.frame = CGRect(x: 18, y: UIApplication.shared.statusBarFrame.height + 5, width: view.frame.width - 35, height: 3)
        } else {
            // Fallback on earlier versions
            SPB.frame = CGRect(x: 18, y: 15, width: view.frame.width - 35, height: 3)
        }
        
        SPB.delegate = self
        SPB.topColor = UIColor.white
        SPB.bottomColor = UIColor.white.withAlphaComponent(0.25)
        SPB.padding = 2
//         SPB.isPaused = true
        SPB.currentAnimationIndex = 0
        SPB.duration = getDuration(at: 0)
        view.addSubview(SPB)
        view.bringSubview(toFront: SPB)
        
        let tapGestureImage = UITapGestureRecognizer(target: self, action: #selector(tapOn(_:)))
        tapGestureImage.numberOfTapsRequired = 1
        tapGestureImage.numberOfTouchesRequired = 1
        imagePreview.addGestureRecognizer(tapGestureImage)
        
        let longGestureImage = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longGestureImage.cancelsTouchesInView = false
        longGestureImage.minimumPressDuration = 0.1
        imagePreview.addGestureRecognizer(longGestureImage)
        
        
        let tapGestureVideo = UITapGestureRecognizer(target: self, action: #selector(tapOn(_:)))
        tapGestureVideo.numberOfTapsRequired = 1
        tapGestureVideo.numberOfTouchesRequired = 1
        videoView.addGestureRecognizer(tapGestureVideo)
        
        let longGestureVideo = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        longGestureVideo.cancelsTouchesInView = false
        longGestureVideo.minimumPressDuration = 0.1
        videoView.addGestureRecognizer(longGestureVideo)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        UIView.animate(withDuration: 0.8) {
            self.view.transform = .identity
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.SPB.startAnimation()
            self.playVideoOrLoadImage(index: 0)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DispatchQueue.main.async {
            self.SPB.currentAnimationIndex = 0
            self.SPB.cancel()
            self.SPB.isPaused = true
            self.resetPlayer()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - SegmentedProgressBarDelegate
    //1
    func segmentedProgressBarChangedIndex(index: Int) {
        playVideoOrLoadImage(index: index)
    }
    
    //2
    func segmentedProgressBarFinished() {
        if pageIndex == (self.items.count - 1) {
            self.dismiss(animated: true, completion: nil)
        }
        else {
            _ = ContentViewControllerVC.goNextPage(fowardTo: pageIndex + 1)
        }
    }
     //3
    func segmentedProgressBarBack() {
        if pageIndex == 0{
            self.dismiss(animated: true, completion: nil)
        }
        else {
            _ = ContentViewControllerVC.goPreviousPage(backwardTo: pageIndex - 1)
        }
    }
    
    @objc func tapOn(_ sender: UITapGestureRecognizer) {
        if let location = sender.location(in: self.imagePreview) as? CGPoint {
            let xLocation = location.x
            if xLocation < self.imagePreview.frame.width/3.0 {
                SPB.back()
            }else{
                SPB.skip()
            }
        }
        
    }
    
      @objc func longPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            if self.SPB != nil {
                self.SPB.isPaused = true
                if self.player != nil {
                   self.player.pause()
                }
            }
        }else if gestureRecognizer.state == .ended {
            if self.SPB != nil {
                self.SPB.isPaused = false
                  if self.player != nil {
                    self.player.play()
                }
            }
        }
        
    }
    
    //MARK: - Play or show image
    func playVideoOrLoadImage(index: NSInteger) {
         self.SPB.isPaused = true
        if item[index].type == "image" {
            self.SPB.duration = 5
            self.imagePreview.isHidden = false
            self.videoView.isHidden = true
//             self.imagePreview.imageFromServerURL(item[index].url)
               self.loader.loadImageWith(from: item[index].url) { (success, image) in
                self.SPB.isPaused = false
                self.imagePreview.image = image
            }
        } else {
            self.imagePreview.isHidden = true
            self.videoView.isHidden = false
            
            resetPlayer()
            guard let url = NSURL(string: item[index].url) as URL? else {return}
            self.player = AVPlayer(url: url)
            
            let videoLayer = AVPlayerLayer(player: self.player)
            videoLayer.frame = view.bounds
            videoLayer.videoGravity = .resizeAspect
            self.videoView.layer.addSublayer(videoLayer)
            
            let asset = AVAsset(url: url)
            let duration = asset.duration
            let durationTime = CMTimeGetSeconds(duration)
            
            self.SPB.duration = durationTime
             self.SPB.isPaused = false
            self.player.play()
        }
    }
    
    // MARK: Private func
    private func getDuration(at index: Int) -> TimeInterval {
        var retVal: TimeInterval = 5.0
        if item[index].type == "image" {
            retVal = 5.0
        } else {
            guard let url = NSURL(string: item[index].url) as URL? else { return retVal }
            let asset = AVAsset(url: url)
            let duration = asset.duration
            retVal = CMTimeGetSeconds(duration)
        }
        return retVal
    }
    
    private func resetPlayer() {
        if player != nil {
            player.pause()
            player.replaceCurrentItem(with: nil)
            player = nil
        }
    }
    
    //MARK: - Button actions
    @IBAction func close(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
        resetPlayer()
    }
}
