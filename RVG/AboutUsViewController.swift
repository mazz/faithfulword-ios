//
//  AboutUsViewController.swift
//  RVG
//

import UIKit

class AboutUsViewController: BaseClass {

    @IBOutlet weak var textView: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.isScrollEnabled = false

        self.navigationController?.isNavigationBarHidden=false
        self.title = NSLocalizedString("About Us", comment: "")
        
        let text : String = NSLocalizedString("The Reina Valera Gomez 2010 Audio Bible, This application is available in Spanish and English interfaces.\r\nThis application is the first application available for the Reina Valera Gomez 2010. This application is the beginning of a much greater project. Currently we support the New Testament in Audio, however as we continue to record the Old Testament and eventually  re-record the New Testament we will support both with a Native Speaker. Currently the native speakers helping to see this application come \r\ntogether are Sean Jolley, Israel Flores and Dr. Humberto Gómez. This application will also someday house the full text of the RVG Bible as well as the Full Text of the King James Bible, with the function to read both Bibles on the same page! We also look forward to the day of supporting the New Testament in Audio for the KJV read by Dominique Davis and someday the Old Testament of the KJV. This application is full of promise, and we hope that you enjoy what is just the beginning! The current reader of this application is Collin Schneide, who is also the editor of this New Testament and the coming Native Speakers Testaments. This application is produced in accordance with the copyright on the RVG Bible. Please visit our website at www.kjvrvg.com for more information, and free downloads of the Audio in this application!\r\n\r\nFor the glory of God and his Word Jesus Christ!\r\nThe KJV RVG Team\r\n\r\nPsalm 119:99 I have more understanding than all my teachers: for thy testimonies are my meditation.", comment: "")
        self.textView.text = text

        // Do any additional setup after loading the view.
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
