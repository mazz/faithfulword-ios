//
//  PrivacyPolicy.swift
//  RVG
//

import UIKit

class PrivacyPolicy: BaseClass{
    
    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.isScrollEnabled = false
        
        self.navigationController?.isNavigationBarHidden=false
        
        self.title = NSLocalizedString("Privacy Policy", comment: "")
        
        let text : String = NSLocalizedString("Use of Information\nPlease be aware that any information shared through the option “Contact Us” is handled solely at the discretion of the owner of the application. This application is produced in according with the Copyright of the RVG. This copyright outlines the free distribution of the literature barring the profiting off of the venture, and has the expressed consent of Dr. Gomez. Any electronic property produced by this application is freely given. In addition, all files may be freely downloaded for distribution from our youtube channels listed in the about us section.\n\nHere is a link to the license for use of the RVG text: http://www.reinavaleragomez.com/sites/default/files/image/RVG-License.pdf\n\nLikewise, our source code is freely available for anyone who is willing to use it for the Kingdom of God. We grant permission to use our source code for the base of a church application involving biblically correct preaching, and sound doctrine. Contact us for a copy of our source code to create a free app for your church preaching, or the music produced by your church.\n\nFor the glory of God and his Word Jesus Christ!\nThe Faithful AudioTeam\n\nMailing Address\n\np.o box 9114\nBeaufort, Sc 29904\ninfo@kjvrvg.com", comment: "")
        
        self.textView.text = text

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.isNavigationBarHidden=false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.textView.isScrollEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationController?.isNavigationBarHidden=true
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
