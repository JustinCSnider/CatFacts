//
//  BreedListViewController.swift
//  CatFacts
//
//  Created by Justin Snider on 10/14/21.
//

import UIKit
import Network

class BreedListViewController: UIViewController {
    
    // MARK: - Properties
    
    var networkMonitor: NWPathMonitor = NWPathMonitor()
    
    var currentPage: Int = 1
    var nextPage: Int?
    
    var breedsList: [String] = [] {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    // MARK: UI
    
    lazy var refreshControl = UIRefreshControl()
    
    // MARK: - IBOutlets
    
    @IBOutlet var badNetworkConnectionView: UIView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Overrides

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupNetworkMonitor()
        
        getBreeds(fromPage: currentPage, { currentPage, nextPage, breedsCompletion in
            do {
                self.breedsList.append(contentsOf: try breedsCompletion())
                self.currentPage = currentPage ?? self.currentPage
                self.nextPage = nextPage
            } catch {
                self.showAlert(title: "Error Loading Breeds", message: "Please try again")
            }
        })
    }
    
    // MARK: - Functions
    
    @objc private func refreshBreeds() {
        titleLabel.text = "Loading Breeds..."
        getBreeds(fromPage: currentPage, { currentPage, nextPage, breedsCompletion  in
            DispatchQueue.main.async {
                self.refreshControl.endRefreshing()
                self.titleLabel.text = "Cat Breed List"
            }
            do {
                self.breedsList.append(contentsOf: try breedsCompletion())
                self.currentPage = currentPage ?? self.currentPage
                self.nextPage = nextPage
            } catch {
                print("\(error.localizedDescription)")
                self.showAlert(title: "Error Loading Breeds", message: "Please try again")
            }
        })
    }
    
    private func getBreeds(fromPage page: Int, _ completion: @escaping (_ currentPage: Int? , _ nextPage: Int? , _ breedsCompletion: () throws -> [String]) -> Void) {
        guard let url = URL(string: "https://catfact.ninja/breeds?page=\(page)") else {
            completion(nil, nil) { throw NetworkError.invalidURL }
            return
        }
        NetworkController.performNetworkRequest(for: url, httpMethod: "GET", contentType: "application/json") { data, error in
            guard let data = data, error == nil else {
                completion(nil, nil) { throw error ?? NetworkError.dataUnavailable }
                return
            }
            do {
                let jsonObj = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let breedsList = jsonObj?["data"] as? [[String: Any]], let currentPage = jsonObj?["current_page"] as? Int else {
                    completion(nil, nil) { throw NetworkError.dataUnavailable }
                    return
                }
                
                let nextPage = jsonObj?["next_page_url"] as? String != nil ? currentPage + 1 : nil
                
                completion(currentPage, nextPage) {
                    var breeds: [String] = []
                    for breed in breedsList {
                        guard let breed = breed["breed"] as? String else { continue }
                        breeds.append(breed)
                    }
                    
                    return breeds
                }
            } catch {
                completion(nil, nil) { throw error }
            }
            
            
        }
    }
    
    // MARK: - Setup Functions
    
    func setupViews() {
        // add refresh control to table view
        refreshControl.addTarget(self, action: #selector(self.refreshBreeds), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(badNetworkConnectionView)
        NSLayoutConstraint.activate([
            badNetworkConnectionView.topAnchor.constraint(equalTo: topView.bottomAnchor),
            badNetworkConnectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            badNetworkConnectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
            badNetworkConnectionView.leftAnchor.constraint(equalTo: view.leftAnchor)
        ])
    }
    
    func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { path in
            let pathIsSatisfied = path.status == .satisfied
            DispatchQueue.main.async {
                self.badNetworkConnectionView.isHidden = pathIsSatisfied
                self.tableView.isHidden = !pathIsSatisfied
            }
        }

        let queue = DispatchQueue(label: "networkMonitor")
        networkMonitor.start(queue: queue)
    }

}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension BreedListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return breedsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "BreedCell", for: indexPath) as! BreedTableViewCell
        
        let breed = breedsList[indexPath.row]
        
        cell.titleLabel.text = breed
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == breedsList.count - 1, let nextPage = nextPage {
            titleLabel.text = "Loading Breeds..."
            getBreeds(fromPage: nextPage, { currentPage, nextPage, breedsCompletion in
                DispatchQueue.main.async {
                    self.titleLabel.text = "Cat Breed List"
                }
                do {
                    self.breedsList.append(contentsOf: try breedsCompletion())
                    self.currentPage = currentPage ?? self.currentPage
                    self.nextPage = nextPage
                } catch {
                    self.showAlert(title: "Error Loading Breeds", message: "Please try again")
                }
            })
        }
    }
}
