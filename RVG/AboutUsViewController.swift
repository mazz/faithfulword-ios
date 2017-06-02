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
        
        let text : String = NSLocalizedString("The Faithful Audio Project\n\nThe KJV RVG, hosted by the Faithful Audio Team. Funded in part by FWBC, with representation thereof by Brother Domonique Davis.\n\n This application is the beginning of a much greater global project. We currently support the Audio of the KJV New Testament and RVG New Testament. We are continuing to record other language's textus receptus Bibles, or KJV equivalents. This application will also someday house the texts of each New Testament, with the function to read several languages on the same page!\n\nThe current reader of the RVG New Testament available in this application is Collin Schneide, who is also the editor of the RVG new Testament as well as the KJV New Testament. This application is produced in accordance with the copyright on the RVG Bible.\n\nWe are always looking for likeminded believers who speak foreign languages, and can code Mobile Applications.\n\n\n\nThe KJV RVG Vision\n\nThis application is full of promise, and we hope that you enjoy what is just the beginning! We look forward to seeing this work grow more and more! Already we are reaching out to get the gospel across international boundries in any language that has a faithful Bible, but even more so someday to reach out with hard preaching. Applications are the future of technology. Someday each church will have it's own application, and this work will be just the beginning. We hope to incorporate spin-off's of FWBC preaching sections, Verity Baptist preaching sections, FWBC Hymns sections, and the like, all in one convenient place.\n\nNot only this, but we are sharpening the Sword of the Lord to see faithful New Testaments in languages all over the world. The Lord has opened the door to us to begin working with revisions in many languages, and we hope to see these versions brought into harmony with the King James Bible in English. We will edify the brethren all over the world, and give them the tools to reach the world in their language with our work. These versions once completed will be put into print.\n\nPlease contact us for more information, and check out our Youtube channels for free downloadable copies of the Audio.\n\nKJV Audio\nhttps://www.youtube.com/c/AUDIOKJV\nRVG Audio:\nhttps://www.youtube.com/c/CollinSchneide\n \nFor the glory of God and his Word Jesus Christ!\nThe Faithful Audio Team:\n\nCollin Schneide, Team Lead, RVG Reader\nDomonique Davis, KJV reader\nSean Jolley, RVG  Reader\nLuis Mendez,  RVG Editor\nJorge Ramos, 1602 Purificada Reader and Editor\nFerdinand Perez, 1865 Spanish Reader/Editor\nConrad Rutkowski, Gdansk Rutkowski Revisor, Reader and Editor\nRenato Trevisan, Almeida Corregida Fiel Reader and Editor\nPastor Joe Major, David Martin 1744 Reader and Editor\nValerian Mayega, Ostervald Reader and Editor\nInderpreet Anand, Hindi 1874 Kanhurkar Reader/ Editor\nJaiarshdeep Singh Bedi, Old Punjabi Bedi Revisor/ Reader/ Editor\nRichard Long, Android Coding\nMatthew Buhr, Apple Coding\nMichael Hanna, Coding Team Lead\nJonathan McCallister, Android Coder\nBlake Rinkin, Administrative Assistant\nShane Freeman, Administrative Assistant\nDr. Humberto Gomez, Translator RVG\nPrashant Kanhurkar,  Hindi 1874 Revisor\nSean McCrary, German Schlachter Revisor\nEstefano Leone, Graphics Designer\nTim Xing, Chinese Union Version Revisor\nNgar Ip, Chinese Revision Reader/ Editor\nPastor Steve Kambalazaza, Chechiwa Revision Team Leader (Team offline)\nHunor Kasco, Hungarian Karolia Gaspar Revision Team Leader (Team offline)\nPastor Edward Boquiren, Tagalog Ang Bagong Tipan Isinalin sa Filipino Audio", comment: "")
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
