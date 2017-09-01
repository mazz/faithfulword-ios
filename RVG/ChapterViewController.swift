//
//  SongsViewController.swift
//  RVG
//

import UIKit
import MBProgressHUD
import Moya

class ChapterViewController: BaseClass {
    @IBOutlet var songsBarRightButton: UIBarButtonItem!
    
    var bookId : String? = nil
    var media : [Playable] = []

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("Chapters", comment: "")
        let provider = MoyaProvider<KJVRVGService>()

        let errorClosure = { (error: Swift.Error) -> Void in
            self.showSingleButtonAlertWithoutAction(title: NSLocalizedString("There was a problem loading the chapters.", comment: ""))
            print("error: \(error)")
            
            DispatchQueue.main.async {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        provider.request(.booksChapterMedia(bid: self.bookId!, languageId: Device.preferredLanguageIdentifier())) {
            result in
            print("booksChapterMedia: \(result)")
            switch result {
            case let .success(moyaResponse):
                do {
                    try moyaResponse.filterSuccessfulStatusAndRedirectCodes()
                    let data = moyaResponse.data
                    var parsedObject: MediaChapterResponse
                    
                    let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments])
                    if let jsonObject = json as? [String:Any] {
                        parsedObject = MediaChapterResponse(JSON: jsonObject)!
                        print(parsedObject)
                        self.media = parsedObject.media!
                        DispatchQueue.main.async {
                            MBProgressHUD.hide(for: self.view, animated: true)
                            self.tableView.reloadData()
                        }
                        
                    }
                }
                catch {
                    errorClosure(error)
                }
                
            case let .failure(error):
                // this means there was a network failure - either the request
                // wasn't sent (connectivity), or no response was received (server
                // timed out).  If the server responds with a 4xx or 5xx error, that
                // will be sent as a ".success"-ful response.
                errorClosure(error)
            }
        }
        
        tableView.register(UINib(nibName: "ChapterTableViewCell", bundle: nil), forCellReuseIdentifier: "ChapterTableViewCellID")

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if (PlaybackService.sharedInstance().player != nil) {
            self.navigationItem.rightBarButtonItem = self.songsBarRightButton
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }
    
    @IBAction func showPlayer(_ sender: AnyObject) {
        PlaybackService.sharedInstance().avoidRestartOnLoad = true
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
        }
    }

}

extension ChapterViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.media.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChapterTableViewCellID") as? ChapterTableViewCell
        cell?.selectionStyle = .none
        cell?.songLabel?.text = self.media[indexPath.row].localizedName!
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let viewController = UIStoryboard(name:"Main", bundle:nil).instantiateViewController(withIdentifier: "PlayerContainerViewController") as? PlayerContainerViewController {
            
//            let media = tableRows.map({$0.url})
            
            PlaybackService.sharedInstance().disposePlayback()
            PlaybackService.sharedInstance().media = media
            PlaybackService.sharedInstance().mediaIndex = indexPath.row
//            PlaybackService.sharedInstance().playbackModeDelegate = self
            
            viewController.modalTransitionStyle = .crossDissolve
            self.present(viewController, animated: true, completion: { _ in })
            
            //            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
