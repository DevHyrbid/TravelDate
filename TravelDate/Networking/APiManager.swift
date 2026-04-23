//
//  Untitled.swift
//  TravelDate
//
//  Created by Dev CodingZone on 20/04/26.
//

import Foundation
import UIKit
import Alamofire
import ObjectMapper

class NetworkManger {
    
    // MARK: - URLSession Request
    class func sendRequestUrlSession(
        url: String,
        params: [String: Any]?,
        method: String,
        success: (([String: Any], Bool) -> Void)!,
        faliure: ((String, Int) -> Void)!
    ) {
        AppLoader.show(text: "")
        
        let url = URL(string: url)!
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.allHTTPHeaderFields = getJSONHeaderWithAccessToken()
        
        if let params = params, !params.isEmpty {
            request.httpBody = try? JSONSerialization.data(withJSONObject: params)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { AppLoader.hide() }
            
            guard let dataJson = data else {
                faliure("json error", 500)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: dataJson, options: .allowFragments)
                print(json as? [String: Any] ?? [:])
                success(json as? [String: Any] ?? [:], true)
            } catch {
                print(error)
                faliure("json error", 500)
            }
        }
        task.resume()
    }
    
    
    // MARK: - Multipart Form Data Upload
    class func sendMultipartFormData(
        url: URL,
        parameters: [String: String],
        fileData: Data,
        fileName: String,
        completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void
    ) {
        AppLoader.show(text: "Uploading…")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append(fileData)
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { AppLoader.hide() }
            
            guard let dataJson = data else { return }
            do {
                let json = try JSONSerialization.jsonObject(with: dataJson, options: .allowFragments)
                print(json)
            } catch {
                print(error)
            }
        }
        task.resume()
    }
    
    
    // MARK: - Multipart Upload (Alamofire)
    class func uploadTo(
        isImg: Bool,
        imgVw: Data?,
        urlPath: String,
        paramName: String,
        param: [String: Any],
        fileType: String,
        success: (([String: Any]?, Bool) -> Void)!,
        faliure: ((Int) -> Void)!
    ) {
        guard NetworkReachabilityManager()!.isReachable else {
            faliure(Constants.APIResponseCodes.statusCodeInternetNotAvailable)
            return
        }
        
        AppLoader.show(text: "Uploading…")
        
        let token = UserDefaults.standard.value(forKey: "UserToken") as? String ?? "Nil"
        let headers: HTTPHeaders = ["Authorization": "Bearer \(token)"]
        
        let requestURL: URLConvertible = urlPath
        print(urlPath, "-________------------", headers)
        
        AF.upload(
            multipartFormData: { formData in
                if isImg, let imageData = imgVw {
                    formData.append(imageData, withName: paramName, fileName: "\(Date().timeIntervalSince1970).jpg", mimeType: "image/jpg")
                }
                for (key, value) in param {
                    formData.append("\(value)".data(using: .utf8)!, withName: key)
                }
            },
            to: requestURL,
            method: .post,
            headers: headers
        ).responseJSON { uploadResult in
            defer { AppLoader.hide() }
            
            print(paramName)
            switch uploadResult.result {
            case .failure(let error):
                print(error)
                faliure(401)
            case .success(_):
                if uploadResult.response?.statusCode == 200 || uploadResult.response?.statusCode == 201 {
                    if let response = uploadResult.value as? [String: Any] {
                        success(response, true)
                    } else {
                        success(nil, true)
                    }
                } else {
                    faliure(uploadResult.response?.statusCode ?? 500)
                }
            }
            print("resp is \(uploadResult)")
        }
    }
    
    
    // MARK: - Alamofire Request
    class func sendRequestAF(
        urlPath: String,
        type: HTTPMethod,
        parms: [String: Any]?,
        success: ((_ responseObject: [String: Any], _ suces: Bool) -> Void)!,
        faliure: ((_ errMsg: String, _ errCode: Int) -> Void)!
    ) {
        guard NetworkReachabilityManager()!.isReachable else {
            faliure(Constants.Validation.internetAppearOffline, Constants.APIResponseCodes.statusCodeInternetNotAvailable)
            return
        }
        
        let skipLoader =
        urlPath.contains("auth/profile") ||
        urlPath.contains("type=video") ||
        urlPath.contains("category") || urlPath.contains("video/progress") || urlPath.contains("favourite") || urlPath.contains("like") || urlPath.contains("video/training/day") || urlPath.contains("video/weekly-progress")
        
        if !skipLoader {
            AppLoader.show(text: "")
        }
        
        var request = URLRequest(url: URL(string: urlPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!)
        request.httpMethod = type.rawValue
        let header = getJSONHeaderWithAccessToken()
        request.allHTTPHeaderFields = header
        
        if let parms = parms, !parms.isEmpty {
            let postString = self.getPostString(params: parms)
            request.httpBody = postString.data(using: .utf8)
        }
        
        print("APIURL-----------------", urlPath)
        print("PARAMS---------------------", parms ?? [:])
        print("header---------------------", header)
        
        AF.request(request).responseJSON { response in
            defer { AppLoader.hide() }
            
            if response.response?.statusCode == 401 {
                print(response)
                SessionManager.shared.handleSessionExpired()
                
                faliure("Invalid Response", response.response?.statusCode ?? Constants.APIResponseCodes.statusCodeInternalServerError)
                return
            }
            
            switch response.result {
            case .success:
                if let responseObj = response.value as? [String: Any] {
                    success(responseObj, true)
                } else {
                    faliure("Invalid Response", response.response?.statusCode ?? 500)
                }
            case .failure(let error):
                faliure(error.localizedDescription, Constants.APIResponseCodes.statusCodeInternalServerError)
                print(error)
            }
        }
    }
    
    
    // MARK: - PUT Request
    class func sendPutRequest(_ type:String,
        urlString: String,
        parameters: [String: Any],
        completion: @escaping (Result<[String: Any], Error>) -> Void
    ) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        if !urlString.contains("favourite") || !urlString.contains("like") {
            AppLoader.show(text: "")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = type//"PUT"
        let token = UserDefaults.standard.string(forKey: "UserToken") ?? ""
        
        var headers: [String: String] = ["Content-Type": "application/json"]
        if !token.isEmpty {
            headers["Authorization"] = "Bearer \(token)"
        }
        print(headers,request.url,request,"KJHSJSJSJSJ")
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            AppLoader.hide()
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            defer { AppLoader.hide() }
            
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "No Data", code: -2)))
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print(jsonObject)
                    completion(.success(jsonObject))
                } else {
                    completion(.failure(NSError(domain: "Invalid JSON format", code: -3)))
                    print("Invalid JSON format")
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    // MARK: - Helper
    static var sessionManager: Session = {
        let sesionManager = Session.default
        return sesionManager
    }()
    
    class func getPostString(params: [String: Any]) -> String {
        var data = [String]()
        for (key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.joined(separator: "&")
    }
    
    static func getJSONHeaderWithAccessToken() -> [String: String] {
        let token = UserDefaults.standard.string(forKey: "UserToken") ?? ""
        var headers = [String: String]()
        if !token.isEmpty {
            headers["Authorization"] = "Bearer \(token)"
        }
        return headers
    }
}



class SessionManager {

    static let shared = SessionManager()
    private init() {}

    var isShowingAlert = false

    func handleSessionExpired() {
        DispatchQueue.main.async {

            // Prevent multiple alerts
            if self.isShowingAlert { return }
            self.isShowingAlert = true

            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootVC = window.rootViewController else {
                return
            }

            let alert = UIAlertController(
                title: "Session Expired",
                message: "Your session has expired. Please login again.",
                preferredStyle: .alert
            )

            let okAction = UIAlertAction(title: "Login", style: .default) { _ in
                self.isShowingAlert = false

                // Clear user data
                User.resetCurrentUser()

                // Navigate to login
                let loginVC = ViewController()
                let nav = UINavigationController(rootViewController: loginVC)
                nav.setNavigationBarHidden(true, animated: false)

                window.rootViewController = nav
                window.makeKeyAndVisible()
            }

            alert.addAction(okAction)

            rootVC.present(alert, animated: true)
        }
    }
}

import UIKit

final class AppLoader {

    private static var overlayView: UIView?
    private static var isShowing = false

    /// Show Loader
    static func show(text: String? = nil) {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
              !isShowing else { return }

        let overlay = UIView(frame: window.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.4)

        // Container
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        // Loader
        let activity = UIActivityIndicatorView(style: .large)
        activity.startAnimating()
        activity.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(activity)

        var constraints = [
            activity.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            activity.topAnchor.constraint(equalTo: container.topAnchor, constant: 20)
        ]

        // Optional Label
        var label: UILabel?
        if let text = text, !text.isEmpty {
            label = UILabel()
            label?.text = text
            label?.font = UIFont.systemFont(ofSize: 14)
            label?.textAlignment = .center
            label?.numberOfLines = 0
            label?.translatesAutoresizingMaskIntoConstraints = false

            if let label = label {
                container.addSubview(label)

                constraints += [
                    label.topAnchor.constraint(equalTo: activity.bottomAnchor, constant: 12),
                    label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                    label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                    label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
                ]
            }
        } else {
            constraints.append(
                activity.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20)
            )
        }

        overlay.addSubview(container)

        constraints += [
            container.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ]

        NSLayoutConstraint.activate(constraints)

        window.addSubview(overlay)

        overlayView = overlay
        isShowing = true
    }

    /// Hide Loader
    static func hide() {
        guard isShowing else { return }

        overlayView?.removeFromSuperview()
        overlayView = nil
        isShowing = false
    }
}
