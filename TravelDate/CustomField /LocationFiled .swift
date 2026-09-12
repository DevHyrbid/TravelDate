//
//  LocationFiled.swift
//  TravelDate
//
//  City / area location search using MapKit
//

import UIKit
import MapKit

final class LocationSearchView: UIView {

    // MARK: - Views

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.isHidden = true
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        tableView.rowHeight = 72
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        return tableView
    }()

    // MARK: - MapKit

    private let completer = MKLocalSearchCompleter()
    private var results: [MKLocalSearchCompletion] = []

    // MARK: - Callback

    var onLocationSelected: ((String, CLLocationCoordinate2D) -> Void)?

    weak var attachedTextField: UITextField?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup

    private func setup() {
        addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tableView.heightAnchor.constraint(equalToConstant: 220)
        ])

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: "LocationCell"
        )

        completer.delegate = self

        // Do not show businesses / restaurants / landmarks.
        completer.pointOfInterestFilter = .excludingAll

        // Address results give us city, area and administrative information.
        completer.resultTypes = [.address]
    }

    // MARK: - Attach

    func attach(to textField: UITextField) {
        attachedTextField = textField

        textField.addTarget(
            self,
            action: #selector(textChanged),
            for: .editingChanged
        )

        textField.addTarget(
            self,
            action: #selector(beginEditing),
            for: .editingDidBegin
        )
    }

    // MARK: - Text Changed

    @objc private func textChanged() {
        let query = attachedTextField?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !query.isEmpty else {
            clearResults()
            return
        }

        completer.queryFragment = query
    }

    @objc private func beginEditing() {
        isHidden = false
        superview?.bringSubviewToFront(self)

        let query = attachedTextField?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !query.isEmpty {
            completer.queryFragment = query
        }
    }

    // MARK: - Clear

    func hideResults() {
        tableView.isHidden = true
    }

    private func clearResults() {
        results.removeAll()
        tableView.reloadData()
        tableView.isHidden = true
    }

    // MARK: - Result Filtering

    private func isValidResult(
        _ completion: MKLocalSearchCompletion
    ) -> Bool {

        let title = completion.title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return false
        }

        let lowercasedTitle = title.lowercased()

        // Street addresses usually start with a house number.
        if title.first?.isNumber == true {
            return false
        }

        // Avoid obvious street-level results.
        let streetKeywords = [
            "street",
            "st.",
            " avenue",
            " ave.",
            " avenue",
            " road",
            " rd.",
            " boulevard",
            " blvd",
            " drive",
            " dr.",
            " lane",
            " ln.",
            " court",
            " ct.",
            " highway",
            " hwy",
            " place",
            " pl.",
            " suite",
            " floor",
            " apartment",
            " apt.",
            " unit"
        ]

        for keyword in streetKeywords {
            if lowercasedTitle.contains(keyword) {
                return false
            }
        }

        return true
    }

    // MARK: - Display Name

    /// Creates a short, user-friendly destination name.
    ///
    /// Examples:
    /// Chandigarh -> Chandigarh
    /// Manali -> Manali
    /// Bandra -> Bandra
    /// Sector 17 -> Sector 17, Chandigarh
    private func displayName(
        completion: MKLocalSearchCompletion,
        placemark: MKPlacemark
    ) -> String {

        let title = completion.title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let locality = placemark.locality?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let subLocality = placemark.subLocality?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // If MapKit found an actual area + city, this is the best format.
        if let subLocality = subLocality,
           !subLocality.isEmpty,
           let locality = locality,
           !locality.isEmpty,
           subLocality.caseInsensitiveCompare(locality) != .orderedSame {

            // If the completion itself is already the city,
            // don't add the area unnecessarily.
            if title.caseInsensitiveCompare(locality) == .orderedSame {
                return locality
            }

            return "\(subLocality), \(locality)"
        }

        // Usually the cleanest value for a travel destination.
        if !title.isEmpty {
            return title
        }

        if let locality = locality, !locality.isEmpty {
            return locality
        }

        if let name = placemark.name,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return completion.subtitle
    }

    // MARK: - Search Selection

    private func selectLocation(
        _ completion: MKLocalSearchCompletion
    ) {

        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
            guard let self = self else { return }

            guard error == nil,
                  let mapItem = response?.mapItems.first else {
                return
            }

            let placemark = mapItem.placemark

            // Require a usable city / area / region.
            guard placemark.locality != nil ||
                  placemark.subLocality != nil ||
                  placemark.administrativeArea != nil else {
                return
            }

            let coordinate = placemark.coordinate

            guard CLLocationCoordinate2DIsValid(coordinate) else {
                return
            }

            let name = self.displayName(
                completion: completion,
                placemark: placemark
            )

            DispatchQueue.main.async {
                self.attachedTextField?.text = name
                self.tableView.isHidden = true
                self.results.removeAll()
                self.completer.queryFragment = ""

                self.onLocationSelected?(name, coordinate)
            }
        }
    }
}

// MARK: - UITableViewDelegate / UITableViewDataSource

extension LocationSearchView: UITableViewDelegate, UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return results.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let completion = results[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LocationCell",
            for: indexPath
        )

        var configuration = cell.defaultContentConfiguration()

        configuration.text = completion.title

        if !completion.subtitle.isEmpty {
            configuration.secondaryText = completion.subtitle
        }

        cell.contentConfiguration = configuration

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard results.indices.contains(indexPath.row) else {
            return
        }

        let completion = results[indexPath.row]

        selectLocation(completion)
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension LocationSearchView: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(
        _ completer: MKLocalSearchCompleter
    ) {

        var uniqueResults: [MKLocalSearchCompletion] = []
        var seen = Set<String>()

        for result in completer.results {

            guard isValidResult(result) else {
                continue
            }

            let key = (
                result.title + "|" + result.subtitle
            ).lowercased()

            guard !seen.contains(key) else {
                continue
            }

            seen.insert(key)
            uniqueResults.append(result)

            // Keep the dropdown compact.
            if uniqueResults.count == 8 {
                break
            }
        }

        results = uniqueResults

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.tableView.reloadData()
            self.tableView.isHidden = self.results.isEmpty
        }
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        print("Location search error:", error.localizedDescription)

        DispatchQueue.main.async { [weak self] in
            self?.clearResults()
        }
    }
}

