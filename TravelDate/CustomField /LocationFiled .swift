//
//  LocationFiled .swift
//  TravelDate
//
//  Created by Dev CodingZone on 27/04/26.
//

import UIKit
import MapKit

// MARK: - Reusable Location Search View
class LocationSearchView: UIView {

   

    private let tableView: UITableView = {
        let tv = UITableView()
        tv.isHidden = true
        tv.layer.cornerRadius = 10
        tv.clipsToBounds = true
        return tv
    }()

    // MARK: - MapKit
    private let completer = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []

    // MARK: - Callback
    var onLocationSelected: ((String, CLLocationCoordinate2D) -> Void)?

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    weak var attachedTextField: UITextField?
    private func setup() {
        addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 200)
        ])

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        completer.delegate = self

    }
    
    func attach(to textField: UITextField) {
        self.attachedTextField = textField
        
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.addTarget(self, action: #selector(beginEditing), for: .editingDidBegin)
    }
    
    

    @objc private func textChanged() {
        completer.queryFragment = attachedTextField?.text ?? ""
    }

    @objc private func beginEditing() {
        self.isHidden = false
        self.superview?.bringSubviewToFront(self)
    }
}

// MARK: - TableView
extension LocationSearchView: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let completion = results[indexPath.row]

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
            guard let item = response?.mapItems.first else { return }

            let placemark = item.placemark
            let coordinate = placemark.coordinate

            let address = [
                placemark.name,
//                placemark.locality,
//                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }.joined(separator: ", ")

            DispatchQueue.main.async {
                self?.attachedTextField?.text = address
                self?.tableView.isHidden = true
                self?.onLocationSelected?(address, coordinate)
            }
        }
    }
}

// MARK: - Completer
extension LocationSearchView: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
        tableView.reloadData()
        tableView.isHidden = results.isEmpty
    }
}

// MARK: - Usage in ViewController
/*
let locationView = LocationSearchView()

locationView.onLocationSelected = { address, coordinate in
    print("Selected:", address)
    print("Lat:", coordinate.latitude, "Lng:", coordinate.longitude)
}

view.addSubview(locationView)
locationView.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 250)
*/
