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
        
        let text : String = NSLocalizedString("The Reina Valera Gomez 2010 Audio Bible\r\n\r\nAvailable in Spanish and English interfaces\r\n\r\nEase of use: Listen to the RVG 2010 Audio Bible without having to download the massive library of files; each chapter at your finger tips.\r\n\r\nExtras: Get to know the producers, our vision, and what we're doing\r\n\r\nContact us: Get in touch with our Team if you have any great ideas you'd like to share with us, or feedback about our application!\r\n\r\nShare: Tell all your friends about the first every Audio Bible available for the Reina Valera Gomez, the most superior Spanish translation available.\r\n\r\nMusic Player: Play, pause, repeat your favorite tracks, and browse through our library of all the books of the New Testament.\r\n\r\nBonus Track: Do you know for sure if you died today you would go to heaven? Listen to our bonus track and find out how you can know for sure!\r\n\r\nPlease be aware that any information shared through the option \"Contact Us\" is handled solely at the discretion of the owner of the application. This application is produced in according with the Copyright of the RVG which outlines the free distribution of the literature barring the profiting off of the venture, and has the expressed consent of Dr. Gomez. Any electronic property produced by this application is freely given, and may be freely distributed from our website www.kjvrvg.com, subsection Downloads, subsection RVG in Audio.\r\n\r\nFor the glory of God and his Word Jesus Christ!\r\nThe KJV RVG Team", comment: "")
        
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
