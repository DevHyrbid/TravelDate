
// EditGroupViewController.swift
// TravelDate
//
// Drop-in edit mode — reuses CreateGroupViewController layout,
// pre-fills every field from the group model, calls PATCH on save.

import UIKit
import MapKit

// MARK: - Group Model (parse from your API response dict)
struct GroupModel {
    let id: String
    let title: String
    let description: String
    let destination: String
    let startDate: String          // "2026-06-12T00:00:00.000Z"
    let endDate: String
    let travelStyle: String
    let maxMembers: Int
    let coverImagePath: String     // "/uploads/xxx.jpg"
    let minAge: Int
    let maxAge: Int
    let preferredGender: String
    let activityInterests: [String]
    let latitude: Double?
    let longitude: Double?

    // Parse from the dict your list screen already has
    static func from(_ dict: [String: Any]) -> GroupModel? {
        guard let id    = dict["id"]    as? String,
              let title = dict["title"] as? String else { return nil }

        let prefs     = dict["preferences"] as? [String: Any] ?? [:]
        let interests = prefs["activityInterests"] as? [String] ?? []

        return GroupModel(
            id:               id,
            title:            title,
            description:      dict["description"]    as? String ?? "",
            destination:      dict["destination"]    as? String ?? "",
            startDate:        dict["startDate"]      as? String ?? "",
            endDate:          dict["endDate"]        as? String ?? "",
            travelStyle:      dict["travelStyle"]    as? String ?? "",
            maxMembers:       dict["maxMembers"]     as? Int    ?? 4,
            coverImagePath:   dict["coverImage"]     as? String ?? "",
            minAge:           prefs["minAge"]        as? Int    ?? 18,
            maxAge:           prefs["maxAge"]        as? Int    ?? 35,
            preferredGender:  prefs["preferredGender"] as? String ?? "ANY",
            activityInterests: interests,
            latitude:         Double(dict["latitude"]  as? String ?? ""),
            longitude:        Double(dict["longitude"] as? String ?? "")
        )
    }
}

// MARK: - EditGroupViewController
class EditGroupViewController: CreateGroupViewController {

    // MARK: - Input
    var groupModel: GroupModel!          // set before pushing

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        prefillAll()
        updateHeaderTitle("Edit Group")
        updateContinueTitle("Save Changes")
    }

    // MARK: - Pre-fill every field
    private func prefillAll() {
        guard let m = groupModel else { return }

        // -- Title
        groupNameField.text = m.title

        // -- Destination
        destinationTF.text = m.destination

        // -- Dates  (stored as ISO: "2026-06-12T00:00:00.000Z")
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        let display = DateFormatter()
        display.dateFormat = "dd MMM yyyy"

        let api = DateFormatter()
        api.dateFormat = "yyyy-MM-dd"

        if !m.startDate.isEmpty {
            // strip time component so api formatter can parse it
            let dateOnly = String(m.startDate.prefix(10))   // "2026-06-12"
            if let d = api.date(from: dateOnly) {
                startDate = dateOnly
                startDateLabel.text      = display.string(from: d)
                startDateLabel.textColor = .white
            }
        }
        if !m.endDate.isEmpty {
            let dateOnly = String(m.endDate.prefix(10))
            if let d = api.date(from: dateOnly) {
                endDate = dateOnly
                endDateLabel.text      = display.string(from: d)
                endDateLabel.textColor = .white
            }
        }

        // -- Group size
        groupSize = m.maxMembers
        sizeLabel.text = "\(groupSize) travelers"

        // -- Age
        minAge = m.minAge
        maxAge = m.maxAge
        minAgeLabel.text = "\(minAge)"
        maxAgeLabel.text = "\(maxAge)"

        // -- Travel styles  (multi-select against the fixed styles array)
        let serverStyles = Set(
            ([m.travelStyle] + m.activityInterests).map { $0.lowercased() }
        )
        let localStyles = ["Partygoers", "Adventure travelers",
                           "Cultural travelers", "Leisure travelers"]

        selectedStyles = Set(
            localStyles.enumerated()
                .filter { serverStyles.contains($0.element.lowercased()) }
                .map    { $0.offset }
        )
        refreshStyleRows()

        // -- Cover image (async load)
        loadCoverImage(from: m.coverImagePath)

        // -- Location coords into request
        if let lat = m.latitude, let lng = m.longitude {
            request.latitude  = lat
            request.longitude = lng
        }
    }

    // MARK: - Refresh style-row UI to match selectedStyles
    private func refreshStyleRows() {
        for (i, row) in styleRows.enumerated() {
            let on    = selectedStyles.contains(i)
            let label = row.subviews.compactMap { $0 as? UILabel }.first
            let img   = row.subviews.compactMap { $0 as? UIImageView }.first

            row.layer.borderColor = on ? UIColor.appOrange.cgColor
                                       : UIColor.appBorder.cgColor
            row.layer.borderWidth = on ? 1.5 : 1
            label?.textColor      = on ? .appOrange : .appGrayText
            img?.image            = UIImage(systemName: on
                ? "largecircle.fill.circle" : "circle")
            img?.tintColor        = on ? .appOrange : .appGrayText
        }
    }

    // MARK: - Load remote cover image
    private func loadCoverImage(from path: String) {
        guard !path.isEmpty else { return }

        // Build full URL — adjust base URL to match your server
        let base = "http://187.124.251.134:9800"
        let urlString = path.hasPrefix("http") ? path : base + path
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.selectedImage = img          // keeps validation happy
                self.updateCoverThumbnail(img)
            }
        }.resume()
    }

    private func updateCoverThumbnail(_ img: UIImage) {
        guard let card = formCard.viewWithTag(999) else { return }

        // Remove dashed border sublayer (no longer needed once image is set)
        card.layer.sublayers?
            .filter { $0 is CAShapeLayer }
            .forEach { $0.removeFromSuperlayer() }

        // Find or create full-bleed image view inside the card
        if let existing = card.viewWithTag(1002) as? UIImageView {
            existing.image = img
            return
        }

        let iv = UIImageView(image: img)
        iv.tag           = 1002
        iv.contentMode   = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 20
        iv.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iv)

        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: card.topAnchor),
            iv.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            iv.bottomAnchor.constraint(equalTo: card.bottomAnchor),
        ])

        // Hide the placeholder stack
        card.subviews
            .compactMap { $0 as? UIStackView }
            .first?
            .isHidden = true
    }

    // MARK: - Header / button title tweaks
    private func updateHeaderTitle(_ text: String) {
        view.subviews
            .compactMap { $0 as? UILabel }
            .first(where: { $0.text == "Create a Group" })?
            .text = text
    }

    private func updateContinueTitle(_ text: String) {
        view.subviews
            .compactMap { $0 as? UIButton }
            .first(where: { $0.titleLabel?.text == "Continue" })?
            .setTitle(text, for: .normal)
    }

    // MARK: - Override continueTapped → PATCH
 /*   @objc  func continueTapped() {
        guard let image = selectedImage else {
            showAlert(message: "Please select a cover photo"); return
        }
        guard let title = groupNameField.text, !title.isEmpty else {
            showAlert(message: "Enter group title"); return
        }
        guard let dest = destinationTF.text, !dest.isEmpty else {
            showAlert(message: "Enter destination"); return
        }

        AppLoader.show()

        // Only re-upload if user picked a NEW image (not the prefilled remote one)
        let needsUpload = image != selectedImage   // always false here,
        // so check by comparing path instead:
        let originalPath = groupModel.coverImagePath

        func patchGroup(imageName: String) {
            guard let m = groupModel else { return }
            callPatchAPI(
                groupId:    m.id,
                title:      title,
                description: title,
                destination: dest,
                startDate:  startDate,
                endDate:    endDate,
                travelStyle: styles.first ?? "",
                maxMembers: groupSize,
                coverImage: imageName,
                minAge:     minAge,
                maxAge:     maxAge,
                preferredGender: "ANY",
                activityInterests: Array(selectedStyles).map { styles[$0] },
                latitude:   request.latitude ?? 0.0,
                longitude:  request.longitude ?? 0.0
            )
        }

        if image == selectedImage && !originalPath.isEmpty {
            // Image unchanged — reuse server path
            patchGroup(imageName: originalPath)
        } else {
            // User picked a new photo
            guard let data = image.jpegData(compressionQuality: 0.7) else {
                AppLoader.hide(); return
            }
            uploadImg(data) { imageName in
                patchGroup(imageName: imageName ?? "")
            }
        }
    }
*/
    // MARK: - PATCH API call
    private func callPatchAPI(
        groupId: String,
        title: String,
        description: String,
        destination: String,
        startDate: String,
        endDate: String,
        travelStyle: String,
        maxMembers: Int,
        coverImage: String,
        minAge: Int,
        maxAge: Int,
        preferredGender: String,
        activityInterests: [String],
        latitude: Double,
        longitude: Double
    ) {
        let urlString = "http://187.124.251.134:9800/api/v1/groups/\(groupId)"
        guard let url = URL(string: urlString) else { AppLoader.hide(); return }

        // Format dates back to ISO for the API
        let api = DateFormatter()
        api.dateFormat = "yyyy-MM-dd"
        let iso = DateFormatter()
        iso.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        func toISO(_ s: String) -> String {
            guard let d = api.date(from: s) else { return s }
            return iso.string(from: d)
        }

        let body: [String: Any] = [
            "title":              title,
            "description":        description,
            "destination":        destination,
            "startDate":          toISO(startDate),
            "endDate":            toISO(endDate),
            "travelStyle":        travelStyle,
            "maxMembers":         maxMembers,
            "coverImage":         coverImage,
            "minAge":             minAge,
            "maxAge":             maxAge,
            "preferredGender":    preferredGender,
            "activityInterests":  activityInterests,
            "latitude":           latitude,
            "longitude":          longitude
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(UserDefaults.standard.string(forKey: "authToken") ?? "")",
                     forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            DispatchQueue.main.async {
                AppLoader.hide()
                guard let self else { return }

                if let error = error {
                    self.showAlert(message: error.localizedDescription)
                    return
                }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let code = json["code"] as? Int, code == 200 else {
                    self.showAlert(message: "Failed to update group")
                    return
                }

                // Pop back to the previous screen
                self.navigationController?.popViewController(animated: true)
            }
        }.resume()
    }
}
