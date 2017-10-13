//
//  CurrencyField.swift
//  RVG
//
//  Created by maz on 2017-05-05.
//  Copyright © 2017 KJVRVG. All rights reserved.
//

import UIKit

class CurrencyField: UITextField {
    
    var string: String { return text ?? "" }
    open var amount: Double { return Double(string.digits.integer)/pow(10, Double(Formatter.currency.maximumFractionDigits))
//        .divided(by: pow(10, Double(Formatter.currency.maximumFractionDigits)))
    }
    
    private var lastValue: String = ""

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        keyboardType = .numberPad
        textAlignment = .center
        editingChanged()
    }
    
    @objc func editingChanged() {
        guard amount <= 2147483647 else {
            text = lastValue
            return
        }
        text = Formatter.currency.string(for: amount)
        lastValue = text!
        print(amount)
    }
    
    func currencyFormatter() -> NumberFormatter {
        return Formatter.currency
    }
}

private extension NumberFormatter {
    convenience init(numberStyle: Style) {
        self.init()
        self.numberStyle = numberStyle
    }
}

private extension Formatter {
    static let currency = NumberFormatter(numberStyle: .currency)
}

private extension String {
    var digits: [Int] { return characters.flatMap{ Int(String($0)) } }
}

private extension BidirectionalCollection where Iterator.Element == Int {
    var string: String { return map(String.init).joined() }
    var integer: Int { return Int(string) ?? 0 }
}
