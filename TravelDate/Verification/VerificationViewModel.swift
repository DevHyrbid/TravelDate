//
//  VerificationViewModel.swift
//  TravelDate
//
//  Created by Dev CodingZone on 23/04/26.
//

import Foundation

// MARK: - Request Extension for Verification Parameters
// Add these properties to your existing `request` singleton / model object.
// If `request` is a shared object/class, extend it or add these properties directly.

extension RequestManager {

    // Verification upload fields
    // var selfie: String = ""
    // var front: String = ""
    // var back: String = ""

    /// POST /user/verify-profile (or equivalent endpoint)
    func verifyProfileAPI(completion: @escaping (_ message: String?, _ errorCode: Int) -> Void) {

        let params: [String: Any] = [
            "selfie": self.selfie,
            "front": self.front,
            "back": self.back
        ]

        APIManager.shared.postRequest(
            endpoint: APIEndpoints.verifyProfile,
            parameters: params
        ) { response, error in

            if let error = error {
                completion(error.localizedDescription, 0)
                return
            }

            guard let response = response else {
                completion("No response from server.", 0)
                return
            }

            let code = response["code"] as? Int ?? 0
            let msg  = response["message"] as? String ?? "Something went wrong."

            completion(msg, code)
        }
    }
}

// MARK: - API Endpoints Extension
// Add this to your existing APIEndpoints file / enum
/*
extension APIEndpoints {
    static let verifyProfile = "user/verify-profile"
}
*/
