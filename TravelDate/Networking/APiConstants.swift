//
//  APiConstants.swift
//  TravelDate
//
//  Created by Dev CodingZone on 21/04/26.
//
import UIKit
class APiConstant : NSObject {
    
    static let port  = 9800
    static let base = "https://api.tripsapp.io"
    static let baseUrl = "https://api.tripsapp.io/api/v1/"
    //"http://187.124.251.134:\(port)/api/v1/"
    static let baseUrlImg = baseUrl + "uploads/"
    static let loginAPi = baseUrl + "users/login"
    static let registerAPi = baseUrl + "users/create"
    static let forgotPassword = baseUrl + "auth/forgot-password"
    static let checkEmail = baseUrl + "auth/check-email"
    static let createGroup = baseUrl + "groups"
    static let myGroup = baseUrl + "groups/my-groups"
    static let pastGroups = baseUrl + "groups/past-trips"
    
    
    static let savedGroup = baseUrl + "groups/saved"
    static let saveGroup = baseUrl + "groups/"
    static let users = baseUrl + "users/all-users?limit=100&page="
    static let allGroups = baseUrl + "group?limit=100&page=1"
    static let socialLogin = baseUrl + "users/social-login"
    static let changePassword = baseUrl + "users/change-password"
    static let updateUser = baseUrl + "users/profile"
    static let uploadMedia = baseUrl + "upload/images"
    static let logout = baseUrl + "auth/logout"
    static let delete = baseUrl + "auth/delete"
    static let profile = baseUrl + "users/profile"
    static let joinGroup = baseUrl + "groups/join/"
    static let inviteUser = baseUrl + "group/invite"
    static let swipe = baseUrl + "group-swipe"
    static let swipeFeed = baseUrl + "group-discovery/feed"
    static let matchedGroup = baseUrl + "groups/my-groups"
    static let roomChats = baseUrl + "api-chat/rooms"
    static let newmatches = baseUrl + "group-match/my-matches"
    static let notification = baseUrl + "notifications?page=1&limit=20"
    
    static let chatInbox = baseUrl + "chat/inbox?"
    static let chatDirect = baseUrl + "chat/direct"
    
    static let dashboardAPi = baseUrl + "groups/dashboard"
    static let historyTrips = baseUrl + "groups/my-trips"
    static let leaveChat = baseUrl + "chat/"
    
    static let reportGroup = baseUrl + "report/group"
    static let blockURl = baseUrl + "user/block"
    static let unblockURl = baseUrl + "user/unblock"
    
    static let bulkDeleteNotifications = baseUrl + "notifications/bulk-delete"
}


