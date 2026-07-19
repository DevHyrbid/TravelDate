//
//  FirebaseManager.swift
//  TravelDate
//
//  Created by Dev CodingZone on 19/07/26.
//

import FirebaseAuth

class FirebaseManager {

    static let shared = FirebaseManager()

    private init() {}

    var verificationID: String?

    // Send OTP
    func sendOTP(phone: String,
                 completion: @escaping (Bool, String) -> Void) {

        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil) { verificationID, error in

            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            self.verificationID = verificationID
            completion(true, "OTP Sent")
        }
    }

    // Verify OTP
    func verifyOTP(code: String,
                   completion: @escaping (Bool, String) -> Void) {

        guard let verificationID = verificationID else {
            completion(false, "Verification ID Missing")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )

        Auth.auth().signIn(with: credential) { _, error in

            if let error = error {
                completion(false, error.localizedDescription)
                return
            }

            completion(true, "Phone Verified")
        }
    }
}
