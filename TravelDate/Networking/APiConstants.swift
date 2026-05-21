//
//  APiConstants.swift
//  TravelDate
//
//  Created by Dev CodingZone on 21/04/26.
//
import UIKit
class APiConstant : NSObject {
    
    static let port  = 9800
    static let base = "http://187.124.251.134:\(port)"
    static let baseUrl = "http://187.124.251.134:\(port)/api/v1/"
    //"http://187.124.251.134:\(port)/api/v1/"
    static let baseUrlImg = baseUrl + "uploads/"
    static let loginAPi = baseUrl + "users/login"
    static let registerAPi = baseUrl + "users/create"
    static let forgotPassword = baseUrl + "auth/forgot-password"
    static let checkEmail = baseUrl + "auth/check-email"
    static let createGroup = baseUrl + "group"
    static let myGroup = baseUrl + "group/my-groups?limit=100&page=1&type="
    static let savedGroup = baseUrl + "group/saved?limit=100&page=1"
    static let saveGroup = baseUrl + "group/save/"
    static let users = baseUrl + "users/all-users?limit=100&page="
    static let allGroups = baseUrl + "group?limit=100&page=1"
    static let socialLogin = baseUrl + "users/social-login"
    static let changePassword = baseUrl + "users/change-password"
    static let updateUser = baseUrl + "users/profile"
    static let uploadMedia = baseUrl + "upload/images"
    static let logout = baseUrl + "auth/logout"
    static let delete = baseUrl + "auth/delete"
    static let profile = baseUrl + "users/profile"
    static let joinGroup = baseUrl + "group/join/"
    static let inviteUser = baseUrl + "group/invite"
    static let swipe = baseUrl + "group/swipe/"
    static let matchedGroup = baseUrl + "group/my-matches?limit=100&page=1"
    static let roomChats = baseUrl + "chat/rooms"
    
}


