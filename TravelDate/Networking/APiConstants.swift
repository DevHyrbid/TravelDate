//
//  APiConstants.swift
//  TravelDate
//
//  Created by Dev CodingZone on 21/04/26.
//
import UIKit
class APiConstant : NSObject {
//    http://85.31.234.205:9800/api/v1/users/social-login
    static let port  = 9800
    static let base = "85.31.234.205:9800/"
    static let baseUrl = "http://85.31.234.205:\(port)/api/v1/"
    static let baseUrlImg = baseUrl + "uploads/"
    static let loginAPi = baseUrl + "users/login"
    static let registerAPi = baseUrl + "users/create"
    static let forgotPassword = baseUrl + "auth/forgot-password"
    static let checkEmail = baseUrl + "auth/check-email"
    static let socialLogin = baseUrl + "users/social-login"
    static let changePassword = baseUrl + "auth/change-password"
    static let updateUser = baseUrl + "auth/updateUser"
    static let uploadMedia = baseUrl + "users/upload"
    static let logout = baseUrl + "auth/logout"
    static let delete = baseUrl + "auth/delete"
    static let profile = baseUrl + "auth/profile"
}
