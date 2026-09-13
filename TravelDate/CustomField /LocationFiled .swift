//
//  LocationSearchView.swift
//
//  City-only location search using MapKit
//

import UIKit
import MapKit

final class LocationSearchView: UIView {

    // MARK: - Models

    private struct CityResult {
        let city: String
        let country: String
        let coordinate: CLLocationCoordinate2D
    }

    // MARK: - Views

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.isHidden = true
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        tableView.rowHeight = 72
        tableView.separatorInset = UIEdgeInsets(
            top: 0,
            left: 16,
            bottom: 0,
            right: 16
        )
        return tableView
    }()

    // MARK: - Search

    private var results: [CityResult] = []

    private var searchWorkItem: DispatchWorkItem?
    private var activeSearch: MKLocalSearch?
    private var searchGeneration = 0

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

    deinit {
        searchWorkItem?.cancel()
        activeSearch?.cancel()
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

        searchWorkItem?.cancel()
        activeSearch?.cancel()

        results.removeAll()
        tableView.reloadData()
        tableView.isHidden = true

        searchGeneration += 1
        let generation = searchGeneration

        guard query.count >= 2 else {
            return
        }

        // Debounce typing so we don't fire a MapKit search for every keystroke.
        let workItem = DispatchWorkItem { [weak self] in
            self?.searchCities(
                query: query,
                generation: generation
            )
        }

        searchWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.45,
            execute: workItem
        )
    }

    @objc private func beginEditing() {
        isHidden = false
        superview?.bringSubviewToFront(self)

        let query = attachedTextField?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if query.count >= 2 {
            searchCities(
                query: query,
                generation: searchGeneration
            )
        }
    }

    // MARK: - City Search

    private func searchCities(
        query: String,
        generation: Int
    ) {
        guard generation == searchGeneration else {
            return
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        // Worldwide search.
        // We intentionally do NOT set a region.
        request.addressFilter = MKAddressFilter(
            including: .locality
        )

        // Do not return businesses / restaurants / landmarks.
        request.pointOfInterestFilter = .excludingAll

        // Address/locality results only.
        request.resultTypes = [.address]

        let search = MKLocalSearch(request: request)
        activeSearch = search

        search.start { [weak self] response, error in
            guard let self = self else {
                return
            }

            guard generation == self.searchGeneration else {
                return
            }

            guard error == nil else {
                DispatchQueue.main.async {
                    guard generation == self.searchGeneration else {
                        return
                    }

                    self.results.removeAll()
                    self.tableView.reloadData()
                    self.tableView.isHidden = true
                }
                return
            }

            let mapItems = response?.mapItems ?? []

            var cityResults: [CityResult] = []
            var seen = Set<String>()

            for mapItem in mapItems {
                let placemark = mapItem.placemark

                guard let locality = placemark.locality?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                      !locality.isEmpty else {
                    continue
                }

                let country = placemark.country?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                let key = "\(locality)|\(country)"
                    .folding(
                        options: [.diacriticInsensitive, .caseInsensitive],
                        locale: .current
                    )

                guard !seen.contains(key) else {
                    continue
                }

                guard CLLocationCoordinate2DIsValid(
                    placemark.coordinate
                ) else {
                    continue
                }

                seen.insert(key)

                cityResults.append(
                    CityResult(
                        city: locality,
                        country: country,
                        coordinate: placemark.coordinate
                    )
                )

                if cityResults.count == 8 {
                    break
                }
            }

            // MapKit normally returns the most relevant locality first.
            // Keep that relevance order, but prefer an exact city-name match
            // when one is present.
            let normalizedQuery = self.normalize(query)

            let exactMatches = cityResults.filter {
                self.normalize($0.city) == normalizedQuery
            }

            let otherMatches = cityResults.filter {
                self.normalize($0.city) != normalizedQuery
            }

            let orderedResults = exactMatches + otherMatches

            DispatchQueue.main.async {
                guard generation == self.searchGeneration else {
                    return
                }

                self.results = orderedResults
                self.tableView.reloadData()
                self.tableView.isHidden = orderedResults.isEmpty
            }
        }
    }

    // MARK: - Normalization

    private func normalize(_ value: String) -> String {
        value
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Clear

    func hideResults() {
        searchWorkItem?.cancel()
        activeSearch?.cancel()
        tableView.isHidden = true
    }

    private func clearResults() {
        searchWorkItem?.cancel()
        activeSearch?.cancel()

        results.removeAll()
        tableView.reloadData()
        tableView.isHidden = true
    }

    // MARK: - Selection

    private func selectLocation(_ result: CityResult) {
        let name: String

        if result.country.isEmpty {
            name = result.city
        } else {
            name = "\(result.city), \(result.country)"
        }

        attachedTextField?.text = name

        tableView.isHidden = true
        results.removeAll()

        onLocationSelected?(name, result.coordinate)
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

        let result = results[indexPath.row]

        let cell = tableView.dequeueReusableCell(
            withIdentifier: "LocationCell",
            for: indexPath
        )

        var configuration = cell.defaultContentConfiguration()

        configuration.text = result.city

        if !result.country.isEmpty {
            configuration.secondaryText = result.country
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

        let result = results[indexPath.row]
        selectLocation(result)
    }
}

