//
//  DonateViewController.swift
//  RVG
//
//  Created by maz on 2017-05-02.
//  Copyright © 2017 Charanbir Sandhu. All rights reserved.
//

import UIKit


///
/// ********  this file's target membership has been removed! Will not be part of compilation!! ******** ///
///



class DonateViewController: UIViewController, PayPalPaymentDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var donationTextField: CurrencyField!
    @IBOutlet weak var donateButton: UIButton!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var successMessageLabel: UILabel!
    @IBOutlet weak var successView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    
    let currencyFormatter = NumberFormatter()
    
    var environment:String = PayPalEnvironmentProduction {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnect(withEnvironment: newEnvironment)
            }
        }
    }
    
    var resultText = "" // empty
    var payPalConfig = PayPalConfiguration() // default
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.text = NSLocalizedString("Donate to KJVRVG", comment: "")
        self.title = NSLocalizedString("Donate", comment: "")
        self.donateButton.setTitle(NSLocalizedString("Donate via PayPal", comment: ""), for: .normal)
//        self.navigationController?.isNavigationBarHidden=false
        
        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
        
        logoImageView.layer.cornerRadius = logoImageView.frame.size.height / 2
        logoImageView.layer.masksToBounds = true
        logoImageView.layer.borderWidth = 0

        _setupDonateButton()
        _setupSuccessView()
        _setupDonationTextField()
}

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PayPalMobile.preconnect(withEnvironment: environment)
        
    }
    
    func _setupDonateButton() {
        donateButton.isEnabled = false
        donateButton.addTarget(self, action: #selector(self.donate(_:)), for: .touchUpInside)
    }

    func _setupSuccessView() {
        successMessageLabel.text = NSLocalizedString("Your donation was successful.\nThank you!", comment: "")
        successView.isHidden = true
    }

    func _setupDonationTextField() {
        
        currencyFormatter.numberStyle = .currency
//        donationTextField.currencyFormatter().minimum = NSNumber(value: 1)
//        donationTextField.currencyFormatter().maximum = NSNumber(value: 100000)
        
        donationTextField.delegate = self
        donationTextField.font = UIFont (name: "HelveticaNeue-Light", size: 17)
        donationTextField.text = "0"
        donationTextField.didMoveToSuperview()
//        donationTextField.textAlignment = .center
//        donationTextField.keyboardType = .numbersAndPunctuation
        donationTextField.becomeFirstResponder()
        
    }
    
    @IBAction func donate(_ sender: AnyObject) {
        print("donate!")
        // Remove our last completed payment, just for demo purposes.
        resultText = ""

        print("donationTextField.amount: \(donationTextField.amount)")
        
        if donationTextField.amount > 0.0 {
            let item1 = PayPalItem(name: "KJVRVG Donation", withQuantity: 1, withPrice: NSDecimalNumber(string: String(donationTextField.amount)), withCurrency: "USD", withSku: "KJVRVG-0001")
            
            let items = [item1]
            let subtotal = PayPalItem.totalPrice(forItems: items)
            let total = subtotal
            
            let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: "KJVRVG Donation", intent: .sale)
            payment.items = items
            
            if (payment.processable) {
                payPalConfig.acceptCreditCards = true

                let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
                present(paymentViewController!, animated: true, completion: nil)
            }
            else {
                // This particular payment will always be processable. If, for
                // example, the amount was negative or the shortDescription was
                // empty, this payment wouldn't be processable, and you'd want
                // to handle that here.
                print("Payment not processalbe: \(payment)")
            }
        }
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        if let currencyField = textField as? CurrencyField {
            print("textFieldDidEndEditing: \(currencyField)")
            print("currencyField.amount: \(currencyField.amount)")
            if currencyField.amount > 0.0 {
                donateButton.isEnabled = true
            } else {
                donateButton.isEnabled = false
            }
        }
    }

    // PayPalPaymentDelegate
    
    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        print("PayPal Payment Cancelled")
        resultText = ""
        successView.isHidden = true
        paymentViewController.dismiss(animated: true, completion: nil)
    }
    
    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        print("PayPal Payment Success !")
        paymentViewController.dismiss(animated: true, completion: { () -> Void in
            // send completed confirmaion to your server
            print("Here is your proof of payment:\n\n\(completedPayment.confirmation)\n\nSend this to your server for confirmation and fulfillment.")

            self.resultText = completedPayment.description
            self.showSuccess()
        })
    }

    func showSuccess() {
        successView.isHidden = false
        successView.alpha = 1.0
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.5)
        UIView.setAnimationDelay(2.0)
        successView.alpha = 0.0
        UIView.commitAnimations()
    }

}
