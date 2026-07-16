//
//  LocationFiled .swift
//  TravelDate
//
//  Created by Dev CodingZone on 27/04/26.
//  Fixed: results filtered to cities only (no POIs / businesses / street addresses)
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

    // Words that indicate a street-level address rather than a city, filtered out below
    private let streetKeywords = [
        "street", "st.", " st ", "avenue", "ave.", " ave ", "road", " rd ", "rd.",
        "boulevard", "blvd", "drive", " dr ", "dr.", "lane", " ln ", "way",
        "court", " ct ", "circle", "highway", " hwy", "place", " pl ",
        "suite", "floor", "apt", "unit"
    ]

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

        // MARK: - Cities-only filtering
        // Excludes businesses, airports, landmarks, and other points of interest
        completer.pointOfInterestFilter = .excludingAll
        // Restricts to address-level results (no free-text query suggestions)
        completer.resultTypes = .address
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

    // Heuristic filter: keeps city/region-level completions, drops street addresses
    private func isCityLevelResult(_ completion: MKLocalSearchCompletion) -> Bool {
        let title = completion.title.lowercased()

        // Street addresses almost always start with a house/building number
        if let firstChar = title.first, firstChar.isNumber {
            return false
        }

        // Drop anything containing a street-type keyword
        for keyword in streetKeywords {
            if title.contains(keyword) {
                return false
            }
        }

        return true
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

            // Reject the pick if it isn't actually a locality (extra safety net
            // beyond the completer-level filtering above)
            guard placemark.locality != nil || placemark.administrativeArea != nil else { return }

            let coordinate = placemark.coordinate

            let address = [
                placemark.locality ?? placemark.name,
                placemark.administrativeArea,
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
        results = completer.results.filter { isCityLevelResult($0) }
        tableView.reloadData()
        tableView.isHidden = results.isEmpty
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
        tableView.reloadData()
        tableView.isHidden = true
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
