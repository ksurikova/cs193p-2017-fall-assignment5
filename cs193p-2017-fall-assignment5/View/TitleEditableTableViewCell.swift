//
//  TitleEditableTableViewCell.swift
//  cs193p-2017-fall-assignment5
//
//  Created by Ksenia Surikova on 17.09.2021.
//

import UIKit

class TitleEditableTableViewCell: UITableViewCell, UITextFieldDelegate {
    // This will hold the handler closure which the view controller provides
    var resignationHandler: (() -> Void)?

    // this will hold single selection block
    var singleTapHandle: (() -> Void)?

    @IBOutlet weak var textField: UITextField! { didSet {
        textField.delegate = self
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(singleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        addGestureRecognizer(singleTap)
        singleTap.require(toFail: doubleTap)
        textField.isEnabled = false
    }}

    @objc private func doubleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        activateTitleEditing()
    }

    @objc private func singleTap(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended else { return }
        if let callback = self.singleTapHandle {
            callback()
        }
    }

    func activateTitleEditing() {
        textField.isEnabled = true
        textField.becomeFirstResponder()
    }

    // MARK: UITextFieldDelegate
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignationHandler?()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.isEnabled = false
        textField.resignFirstResponder()
        return true
    }
}
