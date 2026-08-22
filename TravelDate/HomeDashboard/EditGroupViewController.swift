
// EditGroupViewController.swift
// TravelDate

import UIKit
import MapKit

// MARK: - GroupModel
struct GroupModel {
    let id: String
    let title: String
    let description: String
    let destination: String
    let startDate: String
    let endDate: String
    let travelStyle: String
    let maxMembers: Int
    let coverImagePath: String
    let minAge: Int
    let maxAge: Int
    let preferredGender: String
    let activityInterests: [String]
    let latitude: Double?
    let longitude: Double?
    let memberCount: Int

    static func from(_ dict: [String: Any]) -> GroupModel? {
        guard let id    = dict["id"]    as? String,
              let title = dict["title"] as? String else { return nil }

        let prefs     = dict["preferences"] as? [String: Any] ?? [:]
        let interests = prefs["activityInterests"] as? [String] ?? []
        let members   = dict["members"] as? [[String: Any]] ?? []

        // latitude/longitude can come as String or Double from backend
        let lat: Double?
        let lng: Double?
        if let s = dict["latitude"] as? String { lat = Double(s) }
        else { lat = dict["latitude"] as? Double }
        if let s = dict["longitude"] as? String { lng = Double(s) }
        else { lng = dict["longitude"] as? Double }

        return GroupModel(
            id:                id,
            title:             title,
            description:       dict["description"]       as? String ?? "",
            destination:       dict["destination"]       as? String ?? "",
            startDate:         dict["startDate"]         as? String ?? "",
            endDate:           dict["endDate"]           as? String ?? "",
            travelStyle:       dict["travelStyle"]       as? String ?? "",
            maxMembers:        dict["maxMembers"]        as? Int    ?? 4,
            coverImagePath:    dict["coverImage"]        as? String ?? "",
            minAge:            prefs["minAge"]           as? Int    ?? 18,
            maxAge:            prefs["maxAge"]           as? Int    ?? 35,
            preferredGender:   prefs["preferredGender"]  as? String ?? "ANY",
            activityInterests: interests,
            latitude:          lat,
            longitude:         lng,
            memberCount:       members.count
        )
    }
}

// MARK: - EditGroupViewController
class EditGroupViewController: CreateGroupViewController {

    var groupModel: GroupModel!
    private var didPickNewImage = false
    private var datesLocked     = false

    private let localStyles = ["Partygoer", "Adventure traveler",
                                "Cultural traveler", "Leisure traveler"]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideHeaderAndButton()
        prefillAll()
    }

    // MARK: - Header + Button Override
    private func overrideHeaderAndButton() {
        for sub in view.subviews {
            if let lbl = sub as? UILabel, lbl.text == "Create a Group" {
                lbl.text = "Edit Group"
            }
            if let btn = sub as? UIButton,
               btn.title(for: .normal) == "Continue" {
                btn.setTitle("Save Changes", for: .normal)
                btn.removeTarget(nil, action: nil, for: .allEvents)
                btn.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
            }
        }
        setupEditHeader()
    }

    private func setupEditHeader() {
        let backBtn = UIButton(type: .system)
        backBtn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backBtn.tintColor          = .white
        backBtn.backgroundColor    = UIColor.white.withAlphaComponent(0.1)
        backBtn.layer.cornerRadius = 18
        backBtn.addTarget(self, action: #selector(handleBack), for: .touchUpInside)

        let titleLbl = UILabel()
        titleLbl.text      = "Edit Group"
        titleLbl.textColor = .white
        titleLbl.setFont(.medium, size: 18.0)

        [backBtn, titleLbl].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backBtn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backBtn.widthAnchor.constraint(equalToConstant: 36),
            backBtn.heightAnchor.constraint(equalToConstant: 36),
            titleLbl.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    

    // MARK: - Prefill
    private func prefillAll() {
        guard let m = groupModel else { return }

        groupNameField.text = m.title
        destinationTF.text  = m.destination

        let apiFormatter = DateFormatter()
        apiFormatter.dateFormat = "yyyy-MM-dd"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "dd MMM yyyy"

        if !m.startDate.isEmpty {
            let dateOnly = String(m.startDate.prefix(10))
            if let d = apiFormatter.date(from: dateOnly) {
                startDate                = dateOnly
                startDateLabel.text      = displayFormatter.string(from: d)
                startDateLabel.textColor = .white
            }
        }
        if !m.endDate.isEmpty {
            let dateOnly = String(m.endDate.prefix(10))
            if let d = apiFormatter.date(from: dateOnly) {
                endDate                = dateOnly
                endDateLabel.text      = displayFormatter.string(from: d)
                endDateLabel.textColor = .white
            }
        }

        if m.memberCount >= 2 {
            datesLocked = true
            applyDateLock()
        }

        groupSize      = m.maxMembers
        sizeLabel.text = "\(groupSize) travelers"

        minAge           = m.minAge
        maxAge           = m.maxAge
        minAgeLabel.text = "\(minAge)"
        maxAgeLabel.text = "\(maxAge)"

        let serverStyles = Set(
            ([m.travelStyle] + m.activityInterests).map { $0.lowercased() }
        )
        selectedStyles = Set(
            localStyles.enumerated()
                .filter { serverStyles.contains($0.element.lowercased()) }
                .map    { $0.offset }
        )
        refreshStyleRows()

        addEditBadgeToCard()
        loadCoverImage(from: m.coverImagePath)

        if let lat = m.latitude, let lng = m.longitude {
            request.latitude  = lat
            request.longitude = lng
        }
    }

    // MARK: - Date Lock
    private func applyDateLock() {
        lockDateBox(containing: startDateLabel)
        lockDateBox(containing: endDateLabel)
    }

    private func lockDateBox(containing label: UILabel) {
        guard let box = label.superview else { return }
        box.gestureRecognizers?.forEach { box.removeGestureRecognizer($0) }
        box.isUserInteractionEnabled = false
        box.alpha = 0.45

        let lockIcon = UIImageView(image: UIImage(systemName: "lock.fill"))
        lockIcon.tintColor   = .appGrayText
        lockIcon.contentMode = .scaleAspectFit
        lockIcon.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(lockIcon)
        NSLayoutConstraint.activate([
            lockIcon.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -14),
            lockIcon.centerYAnchor.constraint(equalTo: box.centerYAnchor),
            lockIcon.widthAnchor.constraint(equalToConstant: 16),
            lockIcon.heightAnchor.constraint(equalToConstant: 16),
        ])
        box.subviews.compactMap { $0 as? UIImageView }
            .filter { $0 != lockIcon }
            .forEach { $0.isHidden = true }
    }

    // MARK: - Cover Badge
    private func addEditBadgeToCard() {
        guard let card = formCard.viewWithTag(999) else { return }

        let badge = UIView()
        badge.backgroundColor    = .appOrange
        badge.layer.cornerRadius = 14
        badge.translatesAutoresizingMaskIntoConstraints = false
        badge.tag = 2001

        let pencil = UIImageView(image: UIImage(systemName: "pencil"))
        pencil.tintColor   = .white
        pencil.contentMode = .scaleAspectFit
        pencil.translatesAutoresizingMaskIntoConstraints = false
        badge.addSubview(pencil)
        card.addSubview(badge)
        card.bringSubviewToFront(badge)

        NSLayoutConstraint.activate([
            badge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            badge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            badge.widthAnchor.constraint(equalToConstant: 28),
            badge.heightAnchor.constraint(equalToConstant: 28),
            pencil.centerXAnchor.constraint(equalTo: badge.centerXAnchor),
            pencil.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            pencil.widthAnchor.constraint(equalToConstant: 14),
            pencil.heightAnchor.constraint(equalToConstant: 14),
        ])
    }

    // MARK: - Style Rows
    private func refreshStyleRows() {
        for (i, row) in styleRows.enumerated() {
            let on    = selectedStyles.contains(i)
            let label = row.subviews.compactMap { $0 as? UILabel }.first
            let img   = row.subviews.compactMap { $0 as? UIImageView }.first

            row.layer.borderColor = on ? UIColor.appOrange.cgColor : UIColor.appBorder.cgColor
            row.layer.borderWidth = on ? 1.5 : 1
            label?.textColor      = on ? .appOrange : .appGrayText
            img?.image            = UIImage(systemName: on ? "largecircle.fill.circle" : "circle")
            img?.tintColor        = on ? .appOrange : .appGrayText
        }
    }

    // MARK: - Cover Image Load
    private func loadCoverImage(from path: String) {
        guard !path.isEmpty else { return }
        let base      = "https://api.tripsapp.io"
        let urlString = path.hasPrefix("https") ? path : base + path
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.selectedImage   = img
                self.didPickNewImage = true
                self.updateCoverThumbnail(img)
            }
        }.resume()
    }

    private func updateCoverThumbnail(_ img: UIImage) {
        guard let card = formCard.viewWithTag(999) else { return }

        card.layer.sublayers?
            .filter { $0 is CAShapeLayer }
            .forEach { $0.removeFromSuperlayer() }

        if let existing = card.viewWithTag(1002) as? UIImageView {
            existing.image = img
        } else {
            let iv = UIImageView(image: img)
            iv.tag               = 1002
            iv.contentMode       = .scaleAspectFill
            iv.clipsToBounds     = true
            iv.layer.cornerRadius = 20
            iv.translatesAutoresizingMaskIntoConstraints = false
            card.insertSubview(iv, at: 0)

            NSLayoutConstraint.activate([
                iv.topAnchor.constraint(equalTo: card.topAnchor),
                iv.leadingAnchor.constraint(equalTo: card.leadingAnchor),
                iv.trailingAnchor.constraint(equalTo: card.trailingAnchor),
                iv.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            ])
            card.subviews.compactMap { $0 as? UIStackView }.first?.isHidden = true
        }

        if let badge = card.viewWithTag(2001) {
            card.bringSubviewToFront(badge)
        }
    }

    
    

    // MARK: - Save (PATCH)
    @objc private func handleSave() {
        guard selectedImage != nil else {
            showAlert("Please select a cover photo"); return
        }
        guard let title = groupNameField.text, !title.isEmpty else {
            showAlert("Enter group title"); return
        }
        guard let dest = destinationTF.text, !dest.isEmpty else {
            showAlert("Enter destination"); return
        }
        guard let m = groupModel else { return }

        AppLoader.show()

        func patch(imageName: String) {
            self.callPatchAPI(
                groupId:           m.id,
                title:             title,
                description:       title,
                destination:       dest,
                startDate:         self.startDate,
                endDate:           self.endDate,
                travelStyle:       self.localStyles.first ?? "",
                maxMembers:        self.groupSize,
                coverImage:        imageName,
                minAge:            self.minAge,
                maxAge:            self.maxAge,
                preferredGender:   "ANY",
                activityInterests: Array(self.selectedStyles).map { self.localStyles[$0] },
                latitude:          self.request.latitude ?? m.latitude ?? 0.0,
                longitude:         self.request.longitude ?? m.longitude ?? 0.0
            )
        }

        if didPickNewImage,
           let img  = selectedImage,
           let data = img.jpegData(compressionQuality: 0.7) {
            uploadImg(true,data) { imageName in
                patch(imageName: imageName ?? m.coverImagePath)
            }
        } else {
            patch(imageName: m.coverImagePath)
        }
    }

    // MARK: - PATCH API
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
        let urlString = "https://api.tripsapp.io/api/v1/groups/\(groupId)"
        guard let url = URL(string: urlString) else { AppLoader.hide(); return }

        let apiFmt = DateFormatter()
        apiFmt.dateFormat = "yyyy-MM-dd"
        let isoFmt = DateFormatter()
        isoFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

        func toISO(_ s: String) -> String {
            guard let d = apiFmt.date(from: s) else { return s }
            return isoFmt.string(from: d)
        }

        let body: [String: Any] = [
            "title":             title,
            "description":       description,
            "destination":       destination,
            "startDate":         toISO(startDate),
            "endDate":           toISO(endDate),
            "travelStyle":       travelStyle,
            "maxMembers":        maxMembers,
            "coverImage":        coverImage,
            "minAge":            minAge,
            "maxAge":            maxAge,
            "preferredGender":   preferredGender,
            "activityInterests": activityInterests,
            "latitude":          latitude,
            "longitude":         longitude
        ]

        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(
            "Bearer \(UserDefaults.standard.string(forKey: "UserToken") ?? "")",
            forHTTPHeaderField: "Authorization"
        )
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            DispatchQueue.main.async {
                AppLoader.hide()
                guard let self else { return }

                if let error = error {
                    self.showAlert(error.localizedDescription)
                    return
                }

                // Debug — remove after confirming
                if let data,
                   let raw = String(data: data, encoding: .utf8) {
                    print("PATCH response →", raw)
                }

                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else {
                    self.showAlert("Invalid response from server")
                    return
                }

                // Backend sends code as Int OR String — handle both
                let code = (json["code"] as? Int)
                        ?? Int(json["code"] as? String ?? "")
                        ?? 0

                guard code == 200 else {
                    let msg = json["message"] as? String ?? "Failed to update group"
                    self.showAlert(msg)
                    return
                }

                self.navigationController?.popViewController(animated: true)
            }
        }.resume()
    }
}

