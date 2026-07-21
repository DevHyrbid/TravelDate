//
//  CountryHelper.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/07/26.
//
//
//  Country.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/07/26.
//

//
//  CountryListVC.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/07/26.
//

import UIKit

final class CountryListVC: UIViewController {

    // MARK: - Callback
    var onSelect: ((Country) -> Void)?

    // MARK: - UI
    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Data
    private let allCountries = CountryData.all.sorted { $0.name < $1.name }
    private var filtered: [Country] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Select Country"
        view.backgroundColor = .systemBackground

        filtered = allCountries

        setupNavBar()
        setupUI()
    }

    private func setupNavBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func setupUI() {

        searchBar.placeholder = "Search country or code"
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false

        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(CountryCell.self, forCellReuseIdentifier: CountryCell.reuseId)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(searchBar)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([

            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource / Delegate
extension CountryListVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        52
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: CountryCell.reuseId,
            for: indexPath
        ) as! CountryCell

        cell.configure(with: filtered[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = filtered[indexPath.row]
        onSelect?(country)
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension CountryListVC: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {

        if searchText.trimmingCharacters(in: .whitespaces).isEmpty {
            filtered = allCountries
        } else {
            let query = searchText.lowercased()
            filtered = allCountries.filter {
                $0.name.lowercased().contains(query) || $0.dialCode.contains(query)
            }
        }

        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - Cell
final class CountryCell: UITableViewCell {

    static let reuseId = "CountryCell"

    private let flagLabel = UILabel()
    private let nameLabel = UILabel()
    private let codeLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCell()
    }

    private func setupCell() {

        flagLabel.font = .systemFont(ofSize: 22)

        nameLabel.font = .systemFont(ofSize: 15, weight: .regular)
        nameLabel.textColor = .label

        codeLabel.font = .systemFont(ofSize: 15, weight: .medium)
        codeLabel.textColor = .secondaryLabel
        codeLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [flagLabel, nameLabel, codeLabel])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with country: Country) {
        flagLabel.text = country.flag
        nameLabel.text = country.name
        codeLabel.text = country.dialCode
    }
}

import Foundation

struct Country {
    let name: String
    let isoCode: String
    let dialCode: String

    var flag: String { isoCode.flagEmoji }
}

extension String {

    /// Converts a 2-letter ISO country code (e.g. "IN") into its flag emoji.
    var flagEmoji: String {
        let base: UInt32 = 127397
        var flag = ""
        for scalar in uppercased().unicodeScalars {
            if let unicodeScalar = UnicodeScalar(base + scalar.value) {
                flag.unicodeScalars.append(unicodeScalar)
            }
        }
        return flag
    }
}

enum CountryData {

    static let all: [Country] = raw.map {
        Country(name: $0.0, isoCode: $0.1, dialCode: $0.2)
    }

    static var `default`: Country {
        all.first(where: { $0.isoCode == "CA" }) ?? all[0]
    }

    private static let raw: [(String, String, String)] = [
        ("Afghanistan", "AF", "+93"),
        ("Albania", "AL", "+355"),
        ("Algeria", "DZ", "+213"),
        ("Andorra", "AD", "+376"),
        ("Angola", "AO", "+244"),
        ("Argentina", "AR", "+54"),
        ("Armenia", "AM", "+374"),
        ("Australia", "AU", "+61"),
        ("Austria", "AT", "+43"),
        ("Azerbaijan", "AZ", "+994"),
        ("Bahamas", "BS", "+1"),
        ("Bahrain", "BH", "+973"),
        ("Bangladesh", "BD", "+880"),
        ("Belarus", "BY", "+375"),
        ("Belgium", "BE", "+32"),
        ("Belize", "BZ", "+501"),
        ("Bhutan", "BT", "+975"),
        ("Bolivia", "BO", "+591"),
        ("Bosnia and Herzegovina", "BA", "+387"),
        ("Botswana", "BW", "+267"),
        ("Brazil", "BR", "+55"),
        ("Brunei", "BN", "+673"),
        ("Bulgaria", "BG", "+359"),
        ("Cambodia", "KH", "+855"),
        ("Cameroon", "CM", "+237"),
        ("Canada", "CA", "+1"),
        ("Chile", "CL", "+56"),
        ("China", "CN", "+86"),
        ("Colombia", "CO", "+57"),
        ("Costa Rica", "CR", "+506"),
        ("Croatia", "HR", "+385"),
        ("Cuba", "CU", "+53"),
        ("Cyprus", "CY", "+357"),
        ("Czech Republic", "CZ", "+420"),
        ("Denmark", "DK", "+45"),
        ("Dominican Republic", "DO", "+1"),
        ("Ecuador", "EC", "+593"),
        ("Egypt", "EG", "+20"),
        ("El Salvador", "SV", "+503"),
        ("Estonia", "EE", "+372"),
        ("Ethiopia", "ET", "+251"),
        ("Fiji", "FJ", "+679"),
        ("Finland", "FI", "+358"),
        ("France", "FR", "+33"),
        ("Georgia", "GE", "+995"),
        ("Germany", "DE", "+49"),
        ("Ghana", "GH", "+233"),
        ("Greece", "GR", "+30"),
        ("Guatemala", "GT", "+502"),
        ("Honduras", "HN", "+504"),
        ("Hong Kong", "HK", "+852"),
        ("Hungary", "HU", "+36"),
        ("Iceland", "IS", "+354"),
        ("India", "IN", "+91"),
        ("Indonesia", "ID", "+62"),
        ("Iran", "IR", "+98"),
        ("Iraq", "IQ", "+964"),
        ("Ireland", "IE", "+353"),
        ("Israel", "IL", "+972"),
        ("Italy", "IT", "+39"),
        ("Jamaica", "JM", "+1"),
        ("Japan", "JP", "+81"),
        ("Jordan", "JO", "+962"),
        ("Kazakhstan", "KZ", "+7"),
        ("Kenya", "KE", "+254"),
        ("Kuwait", "KW", "+965"),
        ("Kyrgyzstan", "KG", "+996"),
        ("Laos", "LA", "+856"),
        ("Latvia", "LV", "+371"),
        ("Lebanon", "LB", "+961"),
        ("Libya", "LY", "+218"),
        ("Liechtenstein", "LI", "+423"),
        ("Lithuania", "LT", "+370"),
        ("Luxembourg", "LU", "+352"),
        ("Macau", "MO", "+853"),
        ("Malaysia", "MY", "+60"),
        ("Maldives", "MV", "+960"),
        ("Malta", "MT", "+356"),
        ("Mauritius", "MU", "+230"),
        ("Mexico", "MX", "+52"),
        ("Moldova", "MD", "+373"),
        ("Monaco", "MC", "+377"),
        ("Mongolia", "MN", "+976"),
        ("Montenegro", "ME", "+382"),
        ("Morocco", "MA", "+212"),
        ("Myanmar", "MM", "+95"),
        ("Nepal", "NP", "+977"),
        ("Netherlands", "NL", "+31"),
        ("New Zealand", "NZ", "+64"),
        ("Nicaragua", "NI", "+505"),
        ("Nigeria", "NG", "+234"),
        ("North Macedonia", "MK", "+389"),
        ("Norway", "NO", "+47"),
        ("Oman", "OM", "+968"),
        ("Pakistan", "PK", "+92"),
        ("Panama", "PA", "+507"),
        ("Papua New Guinea", "PG", "+675"),
        ("Paraguay", "PY", "+595"),
        ("Peru", "PE", "+51"),
        ("Philippines", "PH", "+63"),
        ("Poland", "PL", "+48"),
        ("Portugal", "PT", "+351"),
        ("Qatar", "QA", "+974"),
        ("Romania", "RO", "+40"),
        ("Russia", "RU", "+7"),
        ("Rwanda", "RW", "+250"),
        ("Saudi Arabia", "SA", "+966"),
        ("Senegal", "SN", "+221"),
        ("Serbia", "RS", "+381"),
        ("Singapore", "SG", "+65"),
        ("Slovakia", "SK", "+421"),
        ("Slovenia", "SI", "+386"),
        ("South Africa", "ZA", "+27"),
        ("South Korea", "KR", "+82"),
        ("Spain", "ES", "+34"),
        ("Sri Lanka", "LK", "+94"),
        ("Sudan", "SD", "+249"),
        ("Sweden", "SE", "+46"),
        ("Switzerland", "CH", "+41"),
        ("Syria", "SY", "+963"),
        ("Taiwan", "TW", "+886"),
        ("Tajikistan", "TJ", "+992"),
        ("Tanzania", "TZ", "+255"),
        ("Thailand", "TH", "+66"),
        ("Tunisia", "TN", "+216"),
        ("Turkey", "TR", "+90"),
        ("Turkmenistan", "TM", "+993"),
        ("Uganda", "UG", "+256"),
        ("Ukraine", "UA", "+380"),
        ("United Arab Emirates", "AE", "+971"),
        ("United Kingdom", "GB", "+44"),
        ("United States", "US", "+1"),
        ("Uruguay", "UY", "+598"),
        ("Uzbekistan", "UZ", "+998"),
        ("Venezuela", "VE", "+58"),
        ("Vietnam", "VN", "+84"),
        ("Yemen", "YE", "+967"),
        ("Zambia", "ZM", "+260"),
        ("Zimbabwe", "ZW", "+263")
    ]
}

//
//  PhoneNumberField.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/07/26.
//
//  Attaches a tappable "🇮🇳 +91 ▾" selector as the leftView of a phone
//  UITextField. Tapping opens CountryListVC; selecting a country updates
//  the button and is reflected in `fullNumber`.
//

import UIKit

final class PhoneNumberField {

    // MARK: - Public
    private(set) var selectedCountry: Country
    var onCountryChanged: ((Country) -> Void)?

    /// Dial code + trimmed entered number, e.g. "+919876543210"
    var fullNumber: String {
        let number = (textField?.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return selectedCountry.dialCode + number
    }

    // MARK: - Private
    private weak var textField: UITextField?
    private weak var presentingVC: UIViewController?

    private let codeButton = UIButton(type: .system)
    private let separator = UIView()
    private let containerView = UIView()

    
    var countryISOCode: String {
        selectedCountry.isoCode
    }

    var countryDialCode: String {
        selectedCountry.dialCode.replacingOccurrences(of: "+", with: "")
    }
    
    // MARK: - Init
    init(
        textField: UITextField,
        presentingVC: UIViewController,
        defaultCountry: Country = CountryData.default
    ) {
        self.textField = textField
        self.presentingVC = presentingVC
        self.selectedCountry = defaultCountry
        setup()
    }

    // MARK: - Setup
    private func setup() {

        guard let textField = textField else { return }

        textField.keyboardType = .phonePad

        let height = textField.frame.height > 0 ? textField.frame.height : 44
        containerView.frame = CGRect(x: 0, y: 0, width: 96, height: height)

        codeButton.contentHorizontalAlignment = .left
        codeButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        codeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        codeButton.titleLabel?.minimumScaleFactor = 0.8
        codeButton.addTarget(self, action: #selector(openPicker), for: .touchUpInside)

        separator.backgroundColor = UIColor.separator

        containerView.addSubview(codeButton)
        containerView.addSubview(separator)

        codeButton.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            codeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            codeButton.trailingAnchor.constraint(equalTo: separator.leadingAnchor, constant: -8),
            codeButton.topAnchor.constraint(equalTo: containerView.topAnchor),
            codeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),

            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -4),
            separator.widthAnchor.constraint(equalToConstant: 1),
            separator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            separator.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -10)
        ])

        updateButtonTitle()

        textField.leftView = containerView
        textField.leftViewMode = .always
    }

    private func updateButtonTitle() {
        codeButton.setTitle(
            "\(selectedCountry.flag) \(selectedCountry.dialCode) ▾",
            for: .normal
        )
    }

    // MARK: - Actions
    @objc private func openPicker() {

        textField?.resignFirstResponder()

        let listVC = CountryListVC()

        listVC.onSelect = { [weak self] country in
            guard let self = self else { return }
            self.selectedCountry = country
            self.updateButtonTitle()
            self.onCountryChanged?(country)
        }

        let nav = UINavigationController(rootViewController: listVC)
        presentingVC?.present(nav, animated: true)
    }

    /// Programmatically set the country (e.g. restoring a saved user).
    func setCountry(isoCode: String) {
        guard let country = CountryData.all.first(where: { $0.isoCode == isoCode }) else { return }
        selectedCountry = country
        updateButtonTitle()
    }
}
