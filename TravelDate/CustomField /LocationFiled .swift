
//
//  LocationSearchView.swift
//
//  Trip-based city/country location search using MapKit
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

    private enum QueryType {
        case city
        case country
        case cityAndCountry
    }

    private struct ParsedQuery {
        let type: QueryType
        let city: String
        let country: String
    }

    // MARK: - Views

    private let tableView: UITableView = {
        let tableView = UITableView(
            frame: .zero,
            style: .plain
        )

        tableView.isHidden = true
        tableView.layer.cornerRadius = 10
        tableView.clipsToBounds = true
        tableView.rowHeight = 64

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

    // MARK: - Query State

    private var currentQueryType: QueryType = .city

    // MARK: - Callback

    var onLocationSelected: (
        (String, CLLocationCoordinate2D) -> Void
    )?

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
            tableView.topAnchor.constraint(
                equalTo: topAnchor
            ),

            tableView.leadingAnchor.constraint(
                equalTo: leadingAnchor
            ),

            tableView.trailingAnchor.constraint(
                equalTo: trailingAnchor
            ),

            tableView.heightAnchor.constraint(
                equalToConstant: 256
            )
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

        let query =
            attachedTextField?.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

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

        let parsedQuery = parseQuery(query)

        currentQueryType = parsedQuery.type

        let workItem = DispatchWorkItem { [weak self] in

            self?.searchLocations(
                query: query,
                parsedQuery: parsedQuery,
                generation: generation
            )
        }

        searchWorkItem = workItem

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.45,
            execute: workItem
        )
    }

    // MARK: - Begin Editing

    @objc private func beginEditing() {

        isHidden = false

        superview?.bringSubviewToFront(self)

        let query =
            attachedTextField?.text?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ) ?? ""

        guard query.count >= 2 else {
            return
        }

        let parsedQuery = parseQuery(query)

        currentQueryType = parsedQuery.type

        searchLocations(
            query: query,
            parsedQuery: parsedQuery,
            generation: searchGeneration
        )
    }

    // MARK: - Parse Query

    private func parseQuery(
        _ query: String
    ) -> ParsedQuery {

        let parts = query
            .split(
                separator: ",",
                omittingEmptySubsequences: true
            )
            .map {
                $0.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
            }
            .filter {
                !$0.isEmpty
            }

        // ---------------------------------------------------------
        // City + Country
        //
        // Example:
        // Montreal, Canada
        // ---------------------------------------------------------

        if parts.count >= 2 {

            return ParsedQuery(
                type: .cityAndCountry,
                city: normalize(parts[0]),
                country: normalize(parts[1])
            )
        }

        let value = normalize(
            parts.first ?? ""
        )

        // A single word initially behaves as a city search.
        //
        // MapKit's returned placemarks are then used to determine
        // whether the search term is actually a country.
        //
        // This prevents unrelated locality results such as Dural
        // appearing for Montreal.
        return ParsedQuery(
            type: .city,
            city: value,
            country: ""
        )
    }

    // MARK: - Search Locations

    private func searchLocations(
        query: String,
        parsedQuery: ParsedQuery,
        generation: Int
    ) {

        guard generation == searchGeneration else {
            return
        }

        let request = MKLocalSearch.Request()

        request.naturalLanguageQuery = query

        // ---------------------------------------------------------
        // WORLDWIDE SEARCH
        // ---------------------------------------------------------
        //
        // Do NOT assign a region.
        //
        // This keeps this picker worldwide instead of prioritizing
        // the user's current location.
        //
        // ---------------------------------------------------------

        // Locality only.
        request.addressFilter = MKAddressFilter(
            including: .locality
        )

        // No restaurants, airports, landmarks, stores, etc.
        request.pointOfInterestFilter = .excludingAll

        // Address/locality results only.
        request.resultTypes = [.address]

        let search = MKLocalSearch(
            request: request
        )

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

                    guard generation ==
                            self.searchGeneration
                    else {
                        return
                    }

                    self.results.removeAll()

                    self.tableView.reloadData()

                    self.tableView.isHidden = true
                }

                return
            }

            let mapItems =
                response?.mapItems ?? []

            // -----------------------------------------------------
            // FIRST PASS
            //
            // Extract valid city + country pairs.
            // -----------------------------------------------------

            var candidates: [CityResult] = []

            var seen = Set<String>()

            for mapItem in mapItems {

                let placemark =
                    mapItem.placemark

                guard let city =
                        placemark.locality?
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                      !city.isEmpty
                else {
                    continue
                }

                guard let country =
                        placemark.country?
                            .trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ),
                      !country.isEmpty
                else {
                    continue
                }

                guard CLLocationCoordinate2DIsValid(
                    placemark.coordinate
                ) else {
                    continue
                }

                let normalizedCity =
                    self.normalize(city)

                let normalizedCountry =
                    self.normalize(country)

                let key =
                    "\(normalizedCity)|\(normalizedCountry)"

                guard !seen.contains(key) else {
                    continue
                }

                seen.insert(key)

                candidates.append(
                    CityResult(
                        city: city,
                        country: country,
                        coordinate: placemark.coordinate
                    )
                )
            }

            // -----------------------------------------------------
            // DETERMINE WHETHER A SINGLE-WORD QUERY IS A COUNTRY
            // -----------------------------------------------------
            //
            // Example:
            //
            // Canada
            //
            // MapKit may return Canadian cities with:
            //
            // country = Canada
            //
            // In that case we switch to country mode.
            // -----------------------------------------------------

            let finalType: QueryType

            if parsedQuery.type == .city {

                let countryMatches =
                    candidates.filter {

                        self.normalize(
                            $0.country
                        ) == parsedQuery.city
                    }

                if !countryMatches.isEmpty {

                    finalType = .country

                } else {

                    finalType = .city
                }

            } else {

                finalType = parsedQuery.type
            }

            self.currentQueryType = finalType

            // -----------------------------------------------------
            // FINAL FILTER
            // -----------------------------------------------------

            let filteredResults: [CityResult]

            switch finalType {

            // -----------------------------------------------------
            // CITY SEARCH
            //
            // Montreal
            //
            // ONLY Montreal.
            // Dural is rejected.
            // -----------------------------------------------------

            case .city:

                filteredResults =
                    candidates.filter {

                        self.cityMatches(
                            city: $0.city,
                            query: parsedQuery.city
                        )
                    }

            // -----------------------------------------------------
            // COUNTRY SEARCH
            //
            // Canada
            //
            // Return cities whose country is Canada.
            // -----------------------------------------------------

            case .country:

                let countryName =
                    parsedQuery.type == .city
                    ? parsedQuery.city
                    : parsedQuery.country

                filteredResults =
                    candidates.filter {

                        self.countryMatches(
                            country: $0.country,
                            query: countryName
                        )
                    }

            // -----------------------------------------------------
            // CITY + COUNTRY
            //
            // Montreal, Canada
            //
            // BOTH must match.
            // -----------------------------------------------------

            case .cityAndCountry:

                filteredResults =
                    candidates.filter {

                        self.normalize(
                            $0.city
                        ) == parsedQuery.city
                        &&
                        self.normalize(
                            $0.country
                        ) == parsedQuery.country
                    }
            }

            // -----------------------------------------------------
            // SORT
            // -----------------------------------------------------

            let sortedResults =
                self.sortResults(
                    filteredResults,
                    type: finalType,
                    query: parsedQuery
                )

            // Maximum 8 rows.
            let limitedResults =
                Array(
                    sortedResults.prefix(8)
                )

            DispatchQueue.main.async {

                guard generation ==
                        self.searchGeneration
                else {
                    return
                }

                self.results = limitedResults

                self.tableView.reloadData()

                self.tableView.isHidden =
                    limitedResults.isEmpty
            }
        }
    }

    // MARK: - City Matching

    private func cityMatches(
        city: String,
        query: String
    ) -> Bool {

        let normalizedCity =
            normalize(city)

        let normalizedQuery =
            normalize(query)

        // Exact match is preferred.
        if normalizedCity == normalizedQuery {
            return true
        }

        // Allow normal prefix typing:
        //
        // Mon
        // Montreal
        //
        // But do NOT allow arbitrary fuzzy matches that can produce
        // unrelated cities.
        return normalizedCity.hasPrefix(
            normalizedQuery
        )
    }

    // MARK: - Country Matching

    private func countryMatches(
        country: String,
        query: String
    ) -> Bool {

        let normalizedCountry =
            normalize(country)

        let normalizedQuery =
            normalize(query)

        return normalizedCountry ==
            normalizedQuery
    }

    // MARK: - Sorting

    private func sortResults(
        _ results: [CityResult],
        type: QueryType,
        query: ParsedQuery
    ) -> [CityResult] {

        switch type {

        case .city:

            return results.sorted {

                let firstExact =
                    normalize($0.city) ==
                    query.city

                let secondExact =
                    normalize($1.city) ==
                    query.city

                if firstExact != secondExact {
                    return firstExact
                }

                return normalize($0.city) <
                    normalize($1.city)
            }

        case .country:

            return results.sorted {

                normalize($0.city) <
                    normalize($1.city)
            }

        case .cityAndCountry:

            return results
        }
    }

    // MARK: - Normalization

    private func normalize(
        _ value: String
    ) -> String {

        return value
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )
    }

    // MARK: - Hide Results

    func hideResults() {

        searchWorkItem?.cancel()

        activeSearch?.cancel()

        tableView.isHidden = true
    }

    // MARK: - Clear

    private func clearResults() {

        searchWorkItem?.cancel()

        activeSearch?.cancel()

        results.removeAll()

        tableView.reloadData()

        tableView.isHidden = true
    }

    // MARK: - Selection

    private func selectLocation(
        _ result: CityResult
    ) {

        // ---------------------------------------------------------
        // IMPORTANT
        //
        // UI displays only the city.
        //
        // Internally we still return:
        //
        // Montreal, Canada
        //
        // to the trip controller.
        // ---------------------------------------------------------

        let fullLocation =
            "\(result.city), \(result.country)"

        // What the user sees in the text field.
        attachedTextField?.text =
            result.city

        tableView.isHidden = true

        results.removeAll()

        // What the trip logic receives.
        onLocationSelected?(
            fullLocation,
            result.coordinate
        )
    }
}

// MARK: - UITableViewDelegate / UITableViewDataSource

extension LocationSearchView:
    UITableViewDelegate,
    UITableViewDataSource {

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

        let result =
            results[indexPath.row]

        let cell =
            tableView.dequeueReusableCell(
                withIdentifier: "LocationCell",
                for: indexPath
            )

        var configuration =
            cell.defaultContentConfiguration()

        // ---------------------------------------------------------
        // CITY SEARCH
        //
        // Show ONLY city.
        //
        // Montreal
        //
        // ---------------------------------------------------------

        if currentQueryType == .city {

            configuration.text =
                result.city

            configuration.secondaryText =
                nil
        }

        // ---------------------------------------------------------
        // COUNTRY SEARCH
        //
        // Show city + country.
        //
        // Montreal
        // Canada
        //
        // ---------------------------------------------------------

        else {

            configuration.text =
                result.city

            configuration.secondaryText =
                result.country
        }

        cell.contentConfiguration =
            configuration

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        tableView.deselectRow(
            at: indexPath,
            animated: true
        )

        guard results.indices.contains(
            indexPath.row
        ) else {
            return
        }

        selectLocation(
            results[indexPath.row]
        )
    }
}


