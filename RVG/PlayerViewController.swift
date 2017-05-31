//
//  PlayerViewController.swift
//  RVG
//

import UIKit
import AVFoundation
import MediaPlayer
import MBProgressHUD

class PlayerViewController: BaseClass, AVAudioPlayerDelegate
{
    var isPlay : Bool? = false
    var isSeek : Bool? = true
    @IBOutlet weak var lblTimeTotal: UILabel!
    @IBOutlet weak var lblTimePending: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var constraint11: NSLayoutConstraint!
    @IBOutlet weak var constraint43: NSLayoutConstraint!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var btnPlayPuause: UIButton!
    var player : AVPlayer!
    var playerItem : AVPlayerItem!
    var isWhile : Bool? = true
    var isTotalTime : Bool? = true
    var currentSongIndex : String?
    var isrepete : Bool? = false
    
//    var activeDownloads = [String: Download]()
//
//    
//    lazy var downloadsSession: URLSession = {
//        let configuration = URLSessionConfiguration.background(withIdentifier: "bgSessionConfiguration")
//        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
//        return session
//    }()
//    
//    // Called when the Download button for a track is tapped
//    func startDownload(track: String) {
//        
//            let url =  URL(string: track)
//            // 1
//            let download = Download(url: track)
//            // 2
//            download.downloadTask = downloadsSession.downloadTask(with: url!)
//            // 3
//            download.downloadTask!.resume()
//            // 4
//            download.isDownloading = true
//            // 5
//            activeDownloads[download.url] = download
//    }
    var isPause : Bool? = false
    var index = Int(0)
    var objSongsModel : [ModelSongClass]?
    
    var media : [Media]?
    
    static var shareInstance : PlayerViewController? = nil
    @IBOutlet var barRightBtn: UIBarButtonItem!
    @IBOutlet var barLeftBtn: UIBarButtonItem!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do{
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers )
            try AVAudioSession.sharedInstance().setActive(true)
           //   try AVAudioSession.sharedInstance().setActive(true)
        }
        catch{
            
        }
        
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(self.audioSessionInterrupted), name: NSNotification.Name.AVAudioSessionInterruption, object: nil)
        
        center.addObserver(self, selector: #selector(self.audioSessionInterrupted2), name: NSNotification.Name.AVAudioSessionRouteChange, object: nil)
        
        
        center.addObserver(self, selector: #selector(self.audioSessionInterrupted3), name: NSNotification.Name.AVAudioSessionMediaServicesWereLost, object: nil)

        

        
        UIApplication.shared.beginBackgroundTask { 
            
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        PlayerViewController.shareInstance=self
        self.navigationItem.leftBarButtonItem=barLeftBtn
        self.navigationItem.rightBarButtonItem=barRightBtn
//_ = self.downloadsSession
//        startDownload(track: "http://35.164.20.225/media/tracks/tracks_all/abd6a368-7c09-4ee4-a9a6-186fca2d25bb/c56a0c78-4a0f-4dcc-b253-7c197650e_yryWWEq.mp3")
        if UIScreen.main.bounds.height == 480{
            NSLayoutConstraint.activate([constraint43])
            NSLayoutConstraint.deactivate([constraint11])
        }else{
            NSLayoutConstraint.activate([constraint11])
            NSLayoutConstraint.deactivate([constraint43])
        }
    }
    
    func audioSessionInterrupted3(sender:Notification){
        let info = sender.userInfo
        print(info)
        print(sender)
    }
    func audioSessionInterrupted2(sender:Notification){
        let info = sender.userInfo
        if isPause==true{
            return
        }
        print(info)
        print(sender)
        if player != nil && isPlay == true{
            player.play()
         //   btnPlayPuause.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
        }else if player != nil && isPlay == false{
            player.pause()
          //  btnPlayPuause.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
        }
    }
    func audioSessionInterrupted(sender:Notification){
        
    let info = sender.userInfo
        let value = (info?["AVAudioSessionInterruptionTypeKey"]) as? Int
        if let val = value{
            if val == 0{
                isPause=false
                if player != nil && isPlay == true{
                    player.play()
                }else if player != nil && isPlay == false{
                    player.pause()
                }
            }else{
                isPause=true
            }
        }
    }
    
    @IBAction func btnPlayPause(_ sender: UIButton) {
        if sender.titleLabel?.text == "0"{
            sender.setImage(#imageLiteral(resourceName: "player_play_180"), for: .normal)
            sender.setTitle("1", for: .normal)
            self.isWhile = true
            setTime()
            isPlay = true
            player.play()
            
        }else{
            sender.setTitle("0", for: .normal)
            sender.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
            self.isWhile = false
            isPlay = false
            player.pause()
        }
    }
    
    @IBAction func btnMute(_ sender: UIButton) {
        if sender.titleLabel?.text == "0"{
            sender.setTitle("1", for: .normal)
            player.volume=0.0
            sender.setImage(#imageLiteral(resourceName: "speaker-2"), for: .normal)
        }else{
            sender.setTitle("0", for: .normal)
            player.volume=1.0
            sender.setImage(#imageLiteral(resourceName: "speaker"), for: .normal)
        }
    }
    @IBAction func btnRepete(_ sender: UIButton) {
        if sender.titleLabel?.text == "0"{
            sender.setTitle("1", for: .normal)
            sender.setImage(#imageLiteral(resourceName: "repeat-2"), for: .normal)
            isrepete=true
        }else{
            isrepete=false
            sender.setTitle("0", for: .normal)
            sender.setImage(#imageLiteral(resourceName: "repeat"), for: .normal)
        }
    }
    @IBAction func btnPrevious() {
        if index>0{
            isPlay = false
            self.player.pause()
            lblTimePending.text = "0.00"
            seekSlider.value=0
            self.removeObserver()
            self.player=nil
            self.playerItem=nil
            self.isWhile = false
            index=index-1
            configureView((media?[index].url)!)
            currentSongIndex=media?[index].url
                lblName.text=media?[index].localizedName
        }
    }
    @IBAction func btnNext() {
        if index<((media?.count)!-1){
            isPlay = false
            self.player.pause()
            lblTimePending.text = "0.00"
            seekSlider.value=0
            self.removeObserver()
            self.player=nil
            self.playerItem=nil
            self.isWhile = false
            index=index+1
            configureView((media?[index].url)!)
            currentSongIndex = media?[index].url
                lblName.text=media?[index].localizedName
        }
    }
    @IBAction func beginSlider(_ sender: UISlider) {
        isSeek=false
    }
    @IBAction func seekSlider(_ sender: UISlider) {
        isSeek=true
        let time = CMTimeMakeWithSeconds(Float64(sender.value), 100)
        player.seek(to: time)
    }
    
//    @IBAction func volumeSlider(_ sender: UISlider) {
//        let volumeView = MPVolumeView()
//        if let view = volumeView.subviews.first as? UISlider
//        {
//            view.value = sender.value   // set b/w 0 t0 1.0
//        }
       // player.volume=sender.value//
//    }
    
    func removeObserver(){
        playerItem.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
            lblName.text=media?[index].localizedName
        
        if let str = currentSongIndex{
            if str != media?[index].url {
                removeObserver()
                configureView((media?[index].url)!)
                currentSongIndex = media?[index].url
            }else{
                
            }
        }else{
            configureView((media?[index].url)!)
            currentSongIndex=media?[index].url
        }
        
    }
    
    
    
    func configureView(_ url:String) {
//        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: false)
//        loadingNotification.mode = MBProgressHUDMode.indeterminate
//        loadingNotification.graceTime = 5
//        loadingNotification.minShowTime = 0
        self.showIndicator()

        self.isWhile = true
         playerItem = AVPlayerItem( url:NSURL( string:url ) as! URL )
        self.player = AVPlayer(playerItem:playerItem)
        playerItem.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)

        player.playImmediately(atRate: 1.0)
        player.automaticallyWaitsToMinimizeStalling = false
        player.play()
        isPlay = true
        isTotalTime=true

        

        
        
        
    }
    
    func nextTrackCommandSelector(){
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        if object is AVPlayerItem {
            if (object as? AVPlayerItem) != nil{
                if (player.currentItem!.isPlaybackLikelyToKeepUp) {

//                    MBProgressHUD.hide(for: self.view, animated: false)
                    self.HideIndicator()

                    if self.isWhile == true{
                        setTime()
                        isPlay = true
                        player.play()
                        btnPlayPuause.setTitle("1", for: .normal)
                        btnPlayPuause.setImage(#imageLiteral(resourceName: "player_play_180"), for: .normal)
                    }
                }
                else {

//                    let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: false)
//                    loadingNotification.mode = MBProgressHUDMode.indeterminate
//                    loadingNotification.graceTime = 5
//                    loadingNotification.minShowTime = 0

                    self.showIndicator()

                    btnPlayPuause.setTitle("0", for: .normal)
                    btnPlayPuause.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
                    isPlay = false
                    player.pause()
                    DispatchQueue.main.asyncAfter(deadline: .now()+7.5){

//                        MBProgressHUD.hide(for: self.view, animated: false)
                        self.HideIndicator()

                        self.setTime()
                        self.isPlay = true
                        self.player.play()
                        self.btnPlayPuause.setTitle("1", for: .normal)
                        self.btnPlayPuause.setImage(#imageLiteral(resourceName: "player_play_180"), for: .normal)
                    }
                }
            }
        }
    }
    
    func convertSecondsToMunits(time:Float) -> String{
        var i = Float(0)
        var newTime = Float(0)
        while (time>=i+60){
            newTime = newTime+1
            i = i+60
        }
        let seconds = time - (newTime*60)
        let minuites = Int(newTime)
        let sec = Int(seconds)
        if sec>9{
            return (String(format:"%d.%d",minuites, sec))
        }else{
            return (String(format:"%d.0%d",minuites, sec))
        }
    }
    
    func setTime(){
        // FIXME: app enters this function sometimes while no
        // longer playing. before running this code
        // check if self.player is not nil
        
        DispatchQueue.global().async {
            while self.isWhile! {
             //   print("run")
                if self.playerItem != nil && self.player != nil{
                if CMTimeGetSeconds(self.playerItem.duration) > 0 {
                    if self.isTotalTime == true{
                        self.isTotalTime = false
                        DispatchQueue.main.async {
                            let time = Float(CMTimeGetSeconds(self.playerItem.duration))
                            self.lblTimeTotal.text = self.convertSecondsToMunits(time: time)
                            self.seekSlider.maximumValue=Float(CMTimeGetSeconds(self.playerItem.duration))
                        }
                    }
                    DispatchQueue.main.async {
                        if CMTimeGetSeconds(self.player.currentTime()) < CMTimeGetSeconds(self.playerItem.duration){
                            if self.isSeek == true{
                                self.seekSlider.value = Float(CMTimeGetSeconds(self.player.currentTime()))
                            }
                            let time = Float(CMTimeGetSeconds(self.player.currentTime()))
                            self.lblTimePending.text = self.convertSecondsToMunits(time: time)
                        }else if self.isrepete == true{
                            let time = CMTimeMakeWithSeconds(0.0, 100)
                            self.lblTimeTotal.text = "0.00"
                            self.player.seek(to: time)
                            let tim = Float(CMTimeGetSeconds(self.playerItem.duration))
                            self.lblTimeTotal.text = self.convertSecondsToMunits(time: tim)
                            self.player.play()
                            self.isPlay = true
                        }else{
                            if self.index<((self.media?.count)!-1){
                                let time = CMTimeMakeWithSeconds(0.0, 100)
                                self.player.seek(to: time)
                                self.isPlay = false
                                self.player.pause()
                                self.removeObserver()
                                self.player=nil
                                self.playerItem=nil
                                self.index=self.index+1
                                self.isWhile = false
                                self.configureView((self.media?[self.index].url)!)
                                self.currentSongIndex=self.media?[self.index].url
                                    self.lblName.text=self.media?[self.index].localizedName
                            }else{
                                let time = CMTimeMakeWithSeconds(0.0, 100)
                                self.player.seek(to: time)
                                self.btnPlayPuause.setTitle("0", for: .normal)
                                self.btnPlayPuause.setImage(#imageLiteral(resourceName: "player_ic180"), for: .normal)
                                self.lblTimeTotal.text = "0.00"
                                self.isPlay = false
                                self.player.pause()
                                self.isWhile = false
                                let tim = Float(CMTimeGetSeconds(self.playerItem.duration))
                                self.lblTimeTotal.text = self.convertSecondsToMunits(time: tim)
                            }
                        }
                    }
                }
                
                sleep(1)
            }
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnLeftAction(_ sender: AnyObject) {
        var array = self.navigationController?.viewControllers
        array?.removeLast()
        array?.insert(self, at: 0)
        self.navigationController?.viewControllers = array!
    }

    @IBAction func btnRightAction(_ sender: AnyObject) {
        var str : String!
        var yes : String!
//        if language == "english" {
            str = NSLocalizedString("Do you want to close the player?", comment: "")
            yes = NSLocalizedString("Yes", comment: "")
//        }
//        else {
//            yes = "Sí"
//            str = "¿Quieres cerrar el reproductor?"
//        }
        self.showTwoButtonAlertWithLeftAction(title: str, buttonTitleLeft: yes, buttonTitleRight: "No") { (nil) in
            self.isWhile = false
            self.isPlay = false
            self.player.pause()
            self.removeObserver()
            self.player=nil
            self.playerItem=nil
            PlayerViewController.shareInstance=nil
            NotificationCenter.default.removeObserver(self)
          _ = self.navigationController?.popViewController(animated: true)
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//// MARK: - NSURLSessionDownloadDelegate
//
//extension playerVc: URLSessionDownloadDelegate {
//
//    
//    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
//    {
//        print(location)
//    }
//    
//    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
//    {
//        print(downloadTask)
//    }
//    
//        
////        // 1
////        if let downloadUrl = downloadTask.originalRequest?.URL?.absoluteString,
////            download = activeDownloads[downloadUrl] {
////            // 2
////            download.progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
////            // 3
////            let totalSize = NSByteCountFormatter.stringFromByteCount(totalBytesExpectedToWrite, countStyle: NSByteCountFormatterCountStyle.Binary)
////            // 4
////            if let trackIndex = trackIndexForDownloadTask(downloadTask), let trackCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: trackIndex, inSection: 0)) as? TrackCell {
////                dispatch_async(dispatch_get_main_queue(), {
////                    trackCell.progressView.progress = download.progress
////                    trackCell.progressLabel.text =  String(format: "%.1f%% of %@",  download.progress * 100, totalSize)
////                })
////            }
////        }
//    
//}
//
