//
//  RandomCatFactViewController.swift
//  CatFacts
//
//  Created by Justin Snider on 10/14/21.
//

import UIKit
import Network

class RandomCatFactViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var randomFactLabel: UILabel!
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        getRandomFact { factCompletion in
            do {
                let fact = try factCompletion()
                DispatchQueue.main.async {
                    self.randomFactLabel.text = fact
                }
            } catch {
                self.showAlert(title: "Error Loading Fact", message: "Please try again")
            }
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func newFactButtonTapped(_ sender: UIButton) {
        self.titleLabel.text = "Loading Fact..."
        getRandomFact { factCompletion in
            DispatchQueue.main.async {
                self.titleLabel.text = "Random Cat Fact"
            }
            do {
                let fact = try factCompletion()
                DispatchQueue.main.async {
                    self.randomFactLabel.text = fact
                }
            } catch {
                self.showAlert(title: "Error Loading Fact", message: "Please try again")
            }
        }
    }
    
    // MARK: - Functions
    
    private func getRandomFact(_ completion: @escaping (_ factCompletion: () throws -> String) -> Void) {
        guard let url = URL(string: "https://catfact.ninja/fact") else {
            completion { throw NetworkError.invalidURL }
            return
        }
        
        NetworkController.performNetworkRequest(for: url, httpMethod: "GET", contentType: "application/json") { data, error in
            guard let data = data, error == nil else {
                completion { throw error ?? NetworkError.dataUnavailable }
                return
            }
            
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let fact = jsonObj?["fact"] as? String else {
                    completion { throw NetworkError.dataUnavailable }
                    return
                }
                
                completion {
                    return fact
                }
            } catch {
                completion { throw error }
            }
        }
    }

}
