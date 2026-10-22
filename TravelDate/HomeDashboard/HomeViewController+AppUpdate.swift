//
//  HomeViewController+AppUpdate.swift
//  TravelDate
//
//  Created by Dev CodingZone on 05/10/26.
//

import UIKit

final class AppUpdateManager {

    static let shared = AppUpdateManager()

    private init() {}

    func checkForUpdate(completion: ((Bool) -> Void)? = nil) {
        guard let appID = Bundle.main.object(forInfoDictionaryKey: "APP_STORE_ID") as? String,
              !appID.isEmpty else {
            completion?(false)
            return
        }

        let country = Locale.current.region?.identifier ?? "US"
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)&country=\(country)"

        guard let url = URL(string: urlString) else {
            completion?(false)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let results = json["results"] as? [[String: Any]],
                let appInfo = results.first,
                let appStoreVersion = appInfo["version"] as? String,
                let currentVersion = Bundle.main.object(
                    forInfoDictionaryKey: "CFBundleShortVersionString"
                ) as? String
            else {
                DispatchQueue.main.async {
                    completion?(false)
                }
                return
            }

            let updateAvailable = self.isNewerVersion(
                appStoreVersion,
                than: currentVersion
            )

            DispatchQueue.main.async {
                completion?(updateAvailable)
            }
        }.resume()
    }

    private func isNewerVersion(_ storeVersion: String, than currentVersion: String) -> Bool {
        let store = storeVersion.split(separator: ".").compactMap { Int($0) }
        let current = currentVersion.split(separator: ".").compactMap { Int($0) }

        let count = max(store.count, current.count)

        for index in 0..<count {
            let storeValue = index < store.count ? store[index] : 0
            let currentValue = index < current.count ? current[index] : 0

            if storeValue > currentValue {
                return true
            }

            if storeValue < currentValue {
                return false
            }
        }

        return false
    }

    func openAppStore() {
        guard
            let appID = Bundle.main.object(forInfoDictionaryKey: "APP_STORE_ID") as? String,
            let url = URL(string: "https://apps.apple.com/app/id\(appID)")
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}
