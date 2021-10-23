//
//  UIViewController+Alert.swift
//  CatFacts
//
//  Created by Justin Snider on 10/14/21.
//

import Foundation
import UIKit

extension UIViewController {
    func showAlert(title: String, message: String, actionText: String = "Dismiss", completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            if let completion = completion {
                alert.addAction(UIAlertAction(title: actionText, style: UIAlertAction.Style.default, handler: { (action) in
                    completion()
                }))
            } else {
                alert.addAction(UIAlertAction(title: actionText, style: UIAlertAction.Style.default, handler: nil))
            }
            
            self?.present(alert, animated: true, completion: nil)
        }
    }
}
