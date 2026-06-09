import Foundation
import ObjectMapper
import UIKit
import Alamofire


class User : Mappable {
    var day : String?
    var name : String?
    var userName : String?
    var lastName : String?
    var password : String?
    var cnfmPwd : String?
    var email : String?
    var deviceType : String?
    var deviceToken : String?
    var dob : String?
    var isSubscribed : Int?
    var subscriptionPlanName : String?
    var userId : String?
    var _id : String?
    var id : String?
    var audioURL : String?
    var subscriptionPlanId : String?
    var  image : String?
    var  gender : String?
    var  age : String?
    var  experienceLevel : String?
    var  socialId : String?
    var  socialType : String?
    var createdAt : String?
    var page : Int?
    var isBlockedByAdmin : String?
    var receiptData: String?
    var limit : Int?
    
    
    var oldPassword : String?
    var newPassword : String?
    
    var current_password :  String?
    var new_password :  String?
    var subject :  String?
    var message : String?
    
    var title :  String?
    var description : String?
    var notificationOn : Int?
    
    var profile_image :  String?
    var social_type :  String?
    var social_id :  String?
    
    
    
    var coverImage : String?
    
    var destination : String?
    var startDate : String?
    var endDate  : String?
    var maxGroupSize  : Int?
    var travelStyle : [String]?
    var travelStyleSingle : String?
    var activityInterests : [String]?
    var isActive : Bool?
    
    var joinCode  : String?
    
    
    var dateOfBirth: String?
    
    
    
    var location: Location?
    var locationString: String?
    
    var airport: String?
    var shortBio: String?
    
    var loungeAccess: Bool?
    var preferedLounge: String?
    var whichLounge: String?
    var travelFrequency: String?
    
    var profileImage: String?
    var images: [String]?
    
    var isEmailVerified: Bool?
    var isVisible: Bool?
    
    var userType: String?
    var isDeleted: Bool?
    var isCompleted: Bool?
    
    
    var isPushNotification: Bool?
    
    
    
    var accountSource: String?
    
    var isFriendship: Bool?
    var profileStatus: String?
    
    var isBlockByAdmin: Bool?
    var isOnline: Bool?
    var lastSeen: String?
    
    
    var updatedAt: String?
    
    var isInvited: Bool?
    
    var  short_bio : String?
    var travelStyles : [String]?
    var is_push_notification : Int?
    
    var groupId : String?
    var swipedId : String?
    var action : String?
    
    var latitude :  Double?
    var longitude : Double?
    var location_string :  String?
    var minAge : Int?
    var maxAge : Int?
    
    
    
    
    var maxMembers : Int?
    var preferredGender : String?
    
    var targetUserId : String?
    
    var arr : [String]?
    var arrStr : String?
    
    
    
    
   
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        
        
        
        targetUserId <- map["targetUserId"]
        swipedId <- map["swipedId"]
        maxMembers  <- map["maxMembers"]
        preferredGender  <- map["preferredGender"]
        
        minAge <- map["minAge"]
        maxAge <- map["maxAge"]
        action <- map["action"]
        latitude <- map["latitude"]
        longitude <- map["longitude"]
        location_string <- map["location_string"]
        groupId <- map["groupId"]
        short_bio <- map["short_bio"]
        travelStyles <- map["travelStyles"]
        is_push_notification <- map["is_push_notification"]
        userName <- map["userName"]
        isInvited <-       map["isInvited"]
        id                <- map["id"]
        name              <- map["name"]
        email             <- map["email"]
        password          <- map["password"]
        
        dateOfBirth       <- map["date_of_birth"]
        age               <- map["age"]
        gender            <- map["gender"]
        
        location          <- map["location"]
        locationString    <- map["location_string"]
        
        airport           <- map["airport"]
        shortBio          <- map["short_bio"]
        
        loungeAccess      <- map["loungeAccess"]
        preferedLounge    <- map["preferedLounge"]
        whichLounge       <- map["whichLounge"]
        travelFrequency   <- map["travelFrequency"]
        
        profileImage      <- map["profile_image"]
        images            <- map["images"]
        
        isEmailVerified   <- map["isEmailVerified"]
        isVisible         <- map["is_visible"]
        
        userType          <- map["user_type"]
        isDeleted         <- map["is_deleted"]
        isCompleted       <- map["is_completed"]
        
        
        
        isPushNotification <- map["is_push_notification"]
        
        socialType        <- map["social_type"]
        socialId          <- map["social_id"]
        
        accountSource     <- map["account_source"]
        
        isFriendship      <- map["is_friendship"]
        profileStatus     <- map["profile_status"]
        
        isBlockByAdmin    <- map["isBlockByAdmin"]
        isOnline          <- map["isOnline"]
        lastSeen          <- map["lastSeen"]
        
        createdAt         <- map["createdAt"]
        updatedAt         <- map["updatedAt"]
        
        
        joinCode <- map["joinCode"]
        current_password <- map["current_password"]
        new_password <- map["new_password"]
        coverImage <- map["coverImage"]
        
        destination <- map["destination"]
        startDate <- map["startDate"]
        endDate <- map["endDate"]
        maxGroupSize <- map["maxGroupSize"]
        travelStyle <- map["travelStyle"]
        travelStyleSingle <- map["travelStyle"]
        isActive <- map["isActive"]
        
        
        
        
        
        
        
        profile_image  <- map["profile_image"]
        social_type  <- map["social_type"]
        social_id  <- map["social_id"]
        
        
        receiptData <- map["receiptData"]
        day <- map["day"]
        
        subscriptionPlanId <- map["subscriptionPlanId"]
        subscriptionPlanName <- map["subscriptionPlanName"]
        notificationOn <- map["notificationOn"]
        isBlockedByAdmin <- map["isBlockedByAdmin"]
        isSubscribed <- map["isSubscribed"]
        description <- map["description"]
        title <- map["title"]
        subject <-  map["subject"]
        message <-  map["message"]
        oldPassword <- map["oldPassword"]
        newPassword <- map["newPassword"]
        
        limit <- map["limit"]
        page <- map["page"]
        createdAt <- map["createdAt"]
        image <- map["image"]
        gender <- map["gender"]
        age <- map["age"]
        experienceLevel <- map["experienceLevel"]
        socialId <- map["socialId"]
        socialType <- map["socialType"]
        
        
        
        userId <- map["userId"]
        _id <- map["_id"]
        id <- map["id"]
        audioURL <- map["audioURL"]
        dob <- map["date_of_birth"]
        name <- map["name"]
        password <- map["password"]
        email <- map["email"]
        deviceType <- map["device_type"]
        deviceToken <- map["device_token"]
        
    }
    
    
    class var curentUser:User? {
        set {
            if newValue == nil {
                UserDefaults.standard.removeObject(forKey: "currentUser")
                currentUserExists = false
            }  else {
                
                UserDefaults.standard.set(newValue?.toJSON(), forKey:"currentUser")
                currentUserExists = true
            }
            UserDefaults.standard.synchronize()
        }
        get {
            let dictUser = UserDefaults.standard.dictionary(forKey:"currentUser")
            if dictUser != nil {
                return Mapper<User>().map(JSON:(dictUser)!)!
            }
            return nil
        }
    }
    
    class var currentUserExists:Bool {
        set {}
        get {
            return UserDefaults.standard.dictionary(forKey:"currentUser") != nil
        }
    }
    
    class func new() -> User {
        let customer = Mapper<User>().map(JSON: [:])
        return customer!
    }
    
    class func logOutUser() {
        User.resetCurrentUser()
    }
    
    class func resetCurrentUser() {
        User.curentUser = nil
        UserDefaults.standard.removeObject(forKey: "currentUser")
        UserDefaults.standard.removeObject(forKey: "UserToken")
        UserDefaults.standard.synchronize()
    }
    
    func signUp(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        if self.name == "" {
            callBack(nil,Constants.Validation.name,400)
        } else if self.email == "" {
            callBack(nil,Constants.Validation.emailEmpty,400)
        } else if !(self.email!.isValidEmail()) {
            callBack(nil,Constants.Validation.emailInvalid,400)
        } else if self.password == ""{
            callBack(nil,Constants.Validation.password,400)
        }else {
            NetworkManger.sendRequestAF(urlPath: APiConstant.registerAPi, type: .post, parms: self.toJSON()) { responseObject, suces in
                
                print(responseObject)
                
                // ✅ 1. Correct key
                let statusCode = responseObject["code"] as? Int ?? 0
                
                guard statusCode == 201 else {
                    callBack(nil, responseObject["message"] as? String ?? "Something went wrong", statusCode)
                    return
                }
                
                // ✅ 2. Get data
                guard let data = responseObject["data"] as? [String: Any] else {
                    callBack(nil, "Invalid data format", 404)
                    return
                }
                
                // ✅ 3. Correct token key
                if let token = data["token"] as? String {
                    UserDefaults.standard.setValue(token, forKey: "UserToken")
                }
                
                // ✅ 4. Get user
                guard let userDict = data["user"] as? [String: Any] else {
                    callBack(nil, "User data missing", 404)
                    return
                }
                
                print(userDict, "USER")
                
                // ✅ 5. Map user
                User.curentUser = Mapper<User>().map(JSON: userDict)
                //            joinCode = 41hdhnf7;
                
                callBack(User.curentUser, responseObject["message"] as? String ?? "", 200)
                
                
                
            } faliure: { errMsg, errCode in
                callBack(nil,errMsg, errCode)
            }
        }
    }
    
    
    func loginAPi(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        if self.email == "" {
            callBack(nil,Constants.Validation.emailEmpty,400)
        } else if !(self.email!.isValidEmail()) {
            callBack(nil,Constants.Validation.emailInvalid,400)
        } else if self.password == ""{
            callBack(nil,Constants.Validation.password,400)
        } else {
            print(self.toJSON(),"PARAMS")
            NetworkManger.sendRequestUrlSession(url: APiConstant.loginAPi, params: self.toJSON(), method: "POST") { responseObject, suces in
                
                print(responseObject)
                
                // ✅ 1. Correct key
                let statusCode = responseObject["code"] as? Int ?? 0
                
                guard statusCode == 200 else {
                    callBack(nil, responseObject["message"] as? String ?? "Something went wrong", statusCode)
                    return
                }
                
                // ✅ 2. Get data
                guard let data = responseObject["data"] as? [String: Any] else {
                    callBack(nil, "Invalid data format", 404)
                    return
                }
                
                // ✅ 3. Correct token key
                if let token = data["token"] as? String {
                    UserDefaults.standard.setValue(token, forKey: "UserToken")
                }
                
                // ✅ 4. Get user
                guard let userDict = data["user"] as? [String: Any] else {
                    callBack(nil, "User data missing", 404)
                    return
                }
                
                print(userDict, "USER")
                
                // ✅ 5. Map user
                User.curentUser = Mapper<User>().map(JSON: userDict)
                
                callBack(User.curentUser, responseObject["message"] as? String ?? "", 200)
                
                
                
            } faliure: { errMsg, errCode in
                print(errMsg)
                callBack(nil,errMsg, errCode)
            }
        }
    }
    
    
    
    func socialLogin(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.socialLogin, type: .post, parms: self.toJSON()) { responseObject, suces in
            print(responseObject)
            if responseObject["code"] as? Int ?? 0 == 200 {
                if let data = responseObject["data"] as? [String :Any] {
                    print(data,"USER")
                    print(responseObject)
                    
                    // ✅ 1. Correct key
                    let statusCode = responseObject["code"] as? Int ?? 0
                    
                    guard statusCode == 200 else {
                        callBack(nil, responseObject["message"] as? String ?? "Something went wrong", statusCode)
                        return
                    }
                    
                    // ✅ 2. Get data
                    guard let data = responseObject["data"] as? [String: Any] else {
                        callBack(nil, "Invalid data format", 404)
                        return
                    }
                    
                    // ✅ 3. Correct token key
                    if let token = data["token"] as? String {
                        UserDefaults.standard.setValue(token, forKey: "UserToken")
                    }
                    
                    // ✅ 4. Get user
                    guard let userDict = data["user"] as? [String: Any] else {
                        callBack(nil, "User data missing", 404)
                        return
                    }
                    User.curentUser = Mapper<User>().map(JSON: userDict)
                    
                    callBack(User.curentUser,responseObject["message"] as? String ?? "",200)
                } else {
                    callBack(nil,responseObject["message"] as? String ?? "",404)
                }
            }else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    func getProfile(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.profile, type: .get, parms: [:]) { responseObject, suces in
            print(responseObject)
            if responseObject["statusCode"] as? Int ?? 0 == 200 {
                if let data = responseObject["data"] as? [String :Any] {
                    print(data,"USER")
                    User.curentUser = Mapper<User>().map(JSON: data)
                    callBack(User.curentUser,responseObject["message"] as? String ?? "",200)
                } else {
                    callBack(nil,responseObject["message"] as? String ?? "",404)
                }
            }else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    func directChat(callBack:((_ model:ChatRoomModel?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.chatDirect, type: .post, parms: self.toJSON()) { responseObject, suces in
            print(responseObject)
            if responseObject["code"] as? Int ?? 0 == 200 {
                let model = Mapper<ChatRoomModel>().map(JSON: responseObject["data"] as? [String:Any] ?? [:])
                
               callBack(model,responseObject["message"] as? String ?? "",200)
                
            }else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
    }
    
    func forgotPasswordAPi(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.forgotPassword, type: .post, parms: self.toJSON()) { responseObject, suces in
            print(responseObject)
            if responseObject["statusCode"] as? Int ?? 0 == 200 {
                
                callBack(responseObject["message"] as? String ?? "",200)
                
            }else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
    }
    
    func uploadImage(_ imgData:Data,callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        NetworkManger.uploadTo(
            isImg: true,
            imgVw: imgData,
            urlPath: APiConstant.uploadMedia,
            paramName: "files", // ✅ FIXED
            param: self.toJSON(),
            fileType: "image/jpeg" // ✅ FIXED
        ) { response, suc in
            
            print("UPLOAD RESPONSE:", response ?? [:])
            
            if let data = response?["data"] as? [String: Any],
               let filenames = data["filenames"] as? [String],
               let url = filenames.first {
                
                callBack(url, 200)
                
            } else {
                callBack("not found", 404)
            }
            
        } faliure: { code in
            callBack("error", code)
        }
        
    }
    
    
    func changePwd(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        if self.current_password == "" {
            callBack(Constants.Validation.password,400)
        } else if self.newPassword == ""{
            callBack(Constants.Validation.password,400)
        } else if self.current_password != self.new_password {
            callBack(Constants.Validation.passwordMatch,400)
        }
        else {
            NetworkManger.sendRequestAF(urlPath: APiConstant.changePassword, type: .post, parms: self.toJSON()) { responseObject, suces in
                print(responseObject)
                if responseObject["statusCode"] as? Int ?? 0 == 200 {
                    
                    callBack(responseObject["message"] as? String ?? "",200)
                    
                }else {
                    callBack(responseObject["message"] as? String ?? "",404)
                }
            } faliure: { errMsg, errCode in
                callBack(errMsg, errCode)
            }
        }
    }
    
    
    func checkEmailAPi(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.checkEmail, type: .post, parms: self.toJSON()) { responseObject, suces in
            print(responseObject)
            if let data = responseObject["exists"] as? Bool {
                print(data,"USER")
                callBack(responseObject["message"] as? String ?? "",200)
            } else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
            
            
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
        
    }
    
    
    func editProfileAPi(callBack: ((_ errMsg: String, _ errCode: Int) -> Void)!) {
        
        NetworkManger.sendRequestUrlSession(
            url: APiConstant.updateUser,
            params: self.toJSON(),
            method: "PATCH"
        ) { responseObject, suces in
            
            print("RESPONSE:", responseObject)
            
            let statusCode = responseObject["code"] as? Int ?? 0
            
            guard statusCode == 200 else {
                let message = responseObject["message"] as? String ?? "Something went wrong"
                callBack(message, statusCode)
                return
            }
            
            // ✅ data = USER OBJECT directly
            guard let userDict = responseObject["data"] as? [String: Any] else {
                callBack("Invalid data format", 404)
                return
            }
            
            print("USER:", userDict)
            
            // ✅ map directly
            User.curentUser = Mapper<User>().map(JSON: userDict)
            
            callBack("updated", 200)
            
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
    }
    
    
    
    func createGroupAPi(callBack:((_ code:String?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        print(self.toJSON(),"JSONofCreateGroup")
        NetworkManger.sendRequestUrlSession(url: APiConstant.createGroup, params: self.toJSON(), method: "POST") { responseObject, suces in
            print(responseObject)
            if  responseObject["code"] as? Int == 200 {
                print("USER",responseObject)
                let data = responseObject["data"] as? [String:Any] ?? [:]
                print("JOIN",data["id"] as? String ?? "")
                callBack(data["id"] as? String ?? "",responseObject["message"] as? String ?? "",200)
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
            
            
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    
    func  inviteGroupAPi(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: APiConstant.inviteUser, params: self.toJSON(), method: "POST") { responseObject, suces in
            print(self.toJSON(),"JSON")
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                callBack(responseObject["message"] as? String ?? "",200)
            } else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
        
    }
    
    
    func joinGroupAPi(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: "\(APiConstant.joinGroup)", params: self.toJSON(), method: "POST") { responseObject, suces in
            print(responseObject)
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                callBack(responseObject["message"] as? String ?? "",200)
            } else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
        
    }
    
    
    func getNotifications(callBack:((_ model:NotificationResponse?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: APiConstant.notification, params: [:], method: "GET") { responseObject, suces in
            print(responseObject)
            if  responseObject["code"] as? Int == 200 {
                if let response = Mapper<NotificationResponse>().map(JSONObject: responseObject) {
                    print(response.data?.notifications?.first?.message ?? "")
                    callBack(response,responseObject["message"] as? String ?? "",200)
                }
                
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    func getAllUsersAPi(callBack:((_ model:UsersResponse?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: "\(APiConstant.users)" + "1", params: [:], method: "GET") { responseObject, suces in
            print(responseObject)
            if  responseObject["code"] as? Int == 200 {
                let map = Mapper<UsersResponse>().map(JSON: responseObject)
                callBack(map,responseObject["message"] as? String ?? "",200)
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    //
    
    func getChatsInbox(_ type:Int?,callBack:(( _ res:ChatInboxModel?, _ errMsg:String,_ errCode:Int)->Void)!) {
        var url = ""
        if type == 0 { // CURRENT
            url  = APiConstant.chatInbox + "filter=mygroup"
        } else  if type == 1 {
            url  = APiConstant.chatInbox + "filter=match"
        }
        
        NetworkManger.sendRequestUrlSession(url: url , params: [:], method: "GET") { responseObject, suces in
            print(responseObject)
            
            
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                if let response = Mapper<ChatInboxModel>().map(JSON: responseObject) {
                    
                    callBack(response,responseObject["message"] as? String ?? "",200)
                }
                
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    func getDashBoardAPi(callBack:(( _ res:DashboardResponse?, _ errMsg:String,_ errCode:Int)->Void)!)  {
        
        
        NetworkManger.sendRequestUrlSession(url: APiConstant.dashboardAPi , params: [:], method: "GET") { responseObject, suces in
            print(responseObject)
            
            
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                if let response = Mapper<DashboardResponse>().map(JSON: responseObject) {
                    
                    callBack(response,responseObject["message"] as? String ?? "",200)
                }
                
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    
    func getGroups(_ type:Int?,callBack:(( _ res:GroupsResponse?, _ errMsg:String,_ errCode:Int)->Void)!) {
        var url = ""
        if type == 0 { // CURRENT
            url  = APiConstant.myGroup// + "current"
        } else  if type == 1 {
            url  = APiConstant.swipeFeed
        } else if type == 2 {
            url = APiConstant.matchedGroup
        } else if type == 3 { // Past
            url  = APiConstant.pastGroups// + "past"
        } else if type == 4 { // Past
            url  = APiConstant.savedGroup 
        }
        
        NetworkManger.sendRequestUrlSession(url: url , params: [:], method: "GET") { responseObject, suces in
            print(responseObject)
            
            
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                if let response = Mapper<GroupsResponse>().map(JSON: responseObject) {
                    
                    callBack(response,responseObject["message"] as? String ?? "",200)
                }
                
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    
    func  deleteGroupAPi(_ id:String?,callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: "\(APiConstant.createGroup)/\(id ?? "")", params: [:], method: "DELETE") { responseObject, suces in
            print(self.toJSON(),"JSON")
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                callBack(responseObject["message"] as? String ?? "",200)
            } else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
        
    }
    
    
    func  swipeAPi(callBack:(( _ type:String?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: "\(APiConstant.swipe)", params: self.toJSON(), method: "POST") { responseObject, suces in
            print(responseObject,"SWIPED")
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                callBack((responseObject["data"] as? [String:Any] ?? [:])["message"] as? String ?? "0" ,["message"] as? String ?? "",200)
            } else {
                callBack(nil,responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
    func  saveGroupAPi(_ id:String?,callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: "\(APiConstant.saveGroup)" + "\(id ?? "")/save", params: self.toJSON(), method: "POST") { responseObject, suces in
            
            if  responseObject["code"] as? Int == 200 {
                print("USER")
                callBack(responseObject["message"] as? String ?? "",200)
            } else {
                callBack(responseObject["message"] as? String ?? "",404)
            }
        } faliure: { errMsg, errCode in
            callBack(errMsg, errCode)
        }
        
    }
    
    func  getChatRooms(callBack:((_ chat:[ChatRoomModel]?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        NetworkManger.sendRequestUrlSession(url: APiConstant.roomChats , params: [:], method: "GET") { responseObject, success in
            print(APiConstant.roomChats,"JHEREEEE",responseObject)
            if let code = responseObject["code"] as? Int, code == 200 {
                
                print("API RESPONSE:", responseObject)
                
                if let dataArray = responseObject["data"] as? [[String: Any]] {
                    
                    let data = Mapper<ChatRoomModel>().mapArray(JSONObject: dataArray)
                    
                    print("PARSED API FOR :::::", data ?? [])
                    
                    callBack(data, "Success", 200)
                    
                } else {
                    
                    callBack(nil, "Data parsing failed", 404)
                }
                
            } else {
                
                let message = responseObject["message"] as? String ?? "Error"
                callBack(nil, message, 404)
            }
        } faliure: { errMsg, errCode in
            callBack(nil,errMsg, errCode)
        }
        
    }
    
}

class GroupsResponse: Mappable {
    var data: GroupsData?
    var dataGroup: [Group]?
    var success: Int?
    var message: String?
    var code: Int?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        data    <- map["data"]
        dataGroup <- map["data"]
        success <- map["success"]
        message <- map["message"]
        code    <- map["code"]
    }
}

class GroupsData: Mappable {
    var groups: [Group]?
    var pagination: Pagination?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        groups     <- map["groups"]
        pagination <- map["pagination"]
    }
}

class Group: Mappable {
    var roomId : String?
    var _id: String?
    var id: String?
//    var groupTitle: String?
    var title: String?
    var destination: String?
    var description: String?
    var coverImage: String?
    var startDate: String?
    var endDate: String?
    var maxGroupSize: Int?
    var travelStyle: [String]?
    var isActive: Bool?
    var joinCode: String?
    
    var members: [MemberGroup]?
    var userId: MemberGroup?
    var creator : MemberGroup?
    var createdAt : String?
    
    
    var isPublic : Bool?
    
    var updatedAt : String?
    var creatorId : String?
    
    var preferences : Preferences?
    
    
    
    var maxMembers : Int?
    
    
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        description <- map["description"]
        title <- map["title"]
        roomId <- map["roomId"]
        createdAt <- map["createdAt"]
        creator <- map["creator"]
        _id           <- map["id"]
        id           <- map["id"]
        
        destination   <- map["destination"]
        coverImage    <- map["coverImage"]
        startDate     <- map["startDate"]
        endDate       <- map["endDate"]
        maxGroupSize  <- map["maxGroupSize"]
        travelStyle   <- map["travelStyle"]
        isActive      <- map["isActive"]
        joinCode      <- map["joinCode"]
        
        members       <- map["members"]
        userId        <- map["userId"]
        
        
        
        
        
        maxMembers <- map["maxMembers"]
        
        creatorId <- map["creatorId"]
        joinCode <- map["joinCode"]
        
        preferences <- map["preferences"]
    }
}

class MemberGroup: Mappable {
    var _id: String?
    var id: String?
    var name: String?
    var email: String?
    var profileImage: String?
    var title :  String?
    var description : String?
    var notificationOn : Int?
    
    var profile_image :  String?
    var social_type :  String?
    var social_id :  String?
    
    
    
    var coverImage : String?
    
    var destination : String?
    var startDate : String?
    var endDate  : String?
    var maxGroupSize  : Int?
    var travelStyle : [String]?
    var isActive : Bool?
    
    var code  : String?
    
    
    var dateOfBirth: String?
    
    
    
    var location: Location?
    var locationString: String?
    
    var airport: String?
    var shortBio: String?
    
    var loungeAccess: Bool?
    var preferedLounge: String?
    var whichLounge: String?
    var travelFrequency: String?
    
    
    var images: [String]?
    
    var isEmailVerified: Bool?
    var isVisible: Bool?
    
    var userType: String?
    var isDeleted: Bool?
    var isCompleted: Bool?
    
    
    var isPushNotification: Bool?
    
    
    
    var accountSource: String?
    
    var isFriendship: Bool?
    var profileStatus: String?
    
    var isBlockByAdmin: Bool?
    var isOnline: Bool?
    var lastSeen: String?
    
    
    var updatedAt: String?
    
    var isInvited: Bool?
    
    var  short_bio : String?
    var travelStyles : [String]?
    var is_push_notification : Int?
    
    var groupId : String?
    var action : String?
    
    var latitude :  String?
    var longitude : String?
    var location_string :  String?
    var roomId : String?
    var userMembers : UserMembers?
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        userMembers <- map["user"]
        roomId <- map["roomId"]
        _id          <- map["id"]
        
        id          <- map["id"]
        name         <- map["name"]
        email        <- map["email"]
        profileImage <- map["profile_image"]
        
        
        location          <- map["location"]
        locationString    <- map["location_string"]
        
        airport           <- map["airport"]
        shortBio          <- map["short_bio"]
        
        loungeAccess      <- map["loungeAccess"]
        preferedLounge    <- map["preferedLounge"]
        whichLounge       <- map["whichLounge"]
        travelFrequency   <- map["travelFrequency"]
        
        profileImage      <- map["profile_image"]
        images            <- map["images"]
        
        isEmailVerified   <- map["isEmailVerified"]
        isVisible         <- map["is_visible"]
        
        userType          <- map["user_type"]
        isDeleted         <- map["is_deleted"]
        isCompleted       <- map["is_completed"]
        
        
        
        isPushNotification <- map["is_push_notification"]
        
        
        accountSource     <- map["account_source"]
        
        isFriendship      <- map["is_friendship"]
        profileStatus     <- map["profile_status"]
        
        isBlockByAdmin    <- map["isBlockByAdmin"]
        isOnline          <- map["isOnline"]
        lastSeen          <- map["lastSeen"]
        
        
        code <- map["code"]
        coverImage <- map["coverImage"]
        
        destination <- map["destination"]
        startDate <- map["startDate"]
        endDate <- map["endDate"]
        maxGroupSize <- map["maxGroupSize"]
        travelStyle <- map["travelStyles"]
        isActive <- map["isActive"]
        
        
        
        
        
        
        
        profile_image  <- map["profile_image"]
        social_type  <- map["social_type"]
        social_id  <- map["social_id"]
        
        
        
    }
}


struct UserMembers : Mappable {
    var id : String?
    var name : String?
    var profile_image : String?
    var shortbio : String?
    var locationstring : String?
    var travelStyles : [String]?
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        travelStyles <- map["travelStyles"]
        locationstring <- map["location_string"]
        shortbio <- map["short_bio"]
        id <- map["id"]
        name <- map["name"]
        profile_image <- map["profile_image"]
    }

}


class Pagination: Mappable {
    var page: Int?
    var limit: Int?
    var total: Int?
    var totalPages: Int?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        page        <- map["page"]
        limit       <- map["limit"]
        total       <- map["total"]
        totalPages  <- map["totalPages"]
    }
}




class UsersResponse: Mappable {
    var success: Bool?
    var code: Int?
    var message: String?
    var data: UsersData?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        success <- map["success"]
        code    <- map["code"]
        message <- map["message"]
        data    <- map["data"]
    }
}


class UsersData: Mappable {
    var users: [User]?
    var pagination: Pagination?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        users      <- map["users"]
        pagination <- map["pagination"]
    }
}



class Location: Mappable {
    var type: String?
    var coordinates: [Double]?
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        type        <- map["type"]
        coordinates <- map["coordinates"]
    }
}



import ObjectMapper

// MARK: - ChatRoomModel
class ChatRoomModel: Mappable {
    
    var id: String?
    var type: String?
    var groupName: String?
    var lastMessageId: String?
    var createdAt: String?
    var updatedAt: String?
    var groupId: String?
    var participants: [ParticipantModel]?
    var participantsUser : [UserMembers]?
    var lastMessage: LastMessageModel?
    var unreadCount: Int?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        type            <- map["type"]
        groupName       <- map["groupName"]
        lastMessageId   <- map["lastMessageId"]
        createdAt       <- map["createdAt"]
        updatedAt       <- map["updatedAt"]
        groupId         <- map["groupId"]
        participants    <- map["participants"]
        participantsUser <- map["participants"]
        lastMessage     <- map["lastMessage"]
        unreadCount     <- map["unreadCount"]
    }
}

// MARK: - ParticipantModel
class ParticipantModel: Mappable {
    
    var id: String?
    var name: String?
    var profileImage: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        name            <- map["name"]
        profileImage    <- map["profile_image"]
    }
}

// MARK: - LastMessageModel
class LastMessageModel: Mappable {
    
    var id: String?
    var roomId: String?
    var senderId: String?
    var content: String?
    var contentType: String?
    var clientId: String?
    var createdAt: String?
    var updatedAt: String?
    var sender: SenderModel?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        roomId          <- map["roomId"]
        senderId        <- map["senderId"]
        content         <- map["content"]
        contentType     <- map["contentType"]
        clientId        <- map["clientId"]
        createdAt       <- map["createdAt"]
        updatedAt       <- map["updatedAt"]
        sender          <- map["sender"]
    }
}

// MARK: - SenderModel
class SenderModel: Mappable {
    
    var id: String?
    var name: String?
    var profileImage: String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        id              <- map["id"]
        name            <- map["name"]
        profileImage    <- map["profile_image"]
    }
}



import ObjectMapper

// MARK: - Root Response
class NotificationResponse: Mappable {
    
    var data: NotificationData?
    var message: String?
    var success: Int?
    var code: Int?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        data        <- map["data"]
        message     <- map["message"]
        success     <- map["success"]
        code        <- map["code"]
    }
}

// MARK: - Data
class NotificationData: Mappable {
    
    var notifications: [NotificationItem]?
    var pagination: Pagination?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        notifications   <- map["notifications"]
        pagination      <- map["pagination"]
    }
}

// MARK: - Notification Item
class NotificationItem: Mappable {
    
    var id: String?
    var groupId: String?
    var recipientId: String?
    var senderId: String?
    
    var title: String?
    var message: String?
    var type: String?
    
    var isDeleted: Int?
    var isRead: Int?
    
    var createdAt: String?
    var updatedAt: String?
    
    var sender: Sender?
    var group: Group?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        id              <- map["id"]
        groupId         <- map["groupId"]
        recipientId     <- map["recipientId"]
        senderId        <- map["senderId"]
        
        title           <- map["title"]
        message         <- map["message"]
        type            <- map["type"]
        
        isDeleted       <- map["is_deleted"]
        isRead          <- map["is_read"]
        
        createdAt       <- map["createdAt"]
        updatedAt       <- map["updatedAt"]
        
        sender          <- map["sender"]
        group           <- map["group"]
    }
}

// MARK: - Sender
class Sender: Mappable {
    
    var name: String?
    var email: String?
    var profileImage: String?
    var isFriendship: Int?
    
    required init?(map: Map) { }
    
    func mapping(map: Map) {
        name            <- map["name"]
        email           <- map["email"]
        profileImage    <- map["profile_image"]
        isFriendship    <- map["is_friendship"]
    }
}
struct DataGroup : Mappable {
    var group : Group?
    var match : Match?
    var myGroup : MyGroup?
    var otherGroup : MyGroup?
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        match <- map["match"]
        myGroup <- map["myGroup"]
        otherGroup <- map["otherGroup"]
        group <- map["group"]
    }
    
}

struct MyGroup : Mappable {
    var id : String?
    var title : String?
    var description : String?
    var destination : String?
    var startDate : String?
    var endDate : String?
    var travelStyle : String?
    var maxMembers : Int?
    var coverImage : String?
    var isActive : Bool?
    var isPublic : Bool?
    var createdAt : String?
    var updatedAt : String?
    var creatorId : String?
    var joinCode : String?
    var members : [Members]?
    var preferences : Preferences?

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {

        id <- map["id"]
        title <- map["title"]
        description <- map["description"]
        destination <- map["destination"]
        startDate <- map["startDate"]
        endDate <- map["endDate"]
        travelStyle <- map["travelStyle"]
        maxMembers <- map["maxMembers"]
        coverImage <- map["coverImage"]
        isActive <- map["isActive"]
        isPublic <- map["isPublic"]
        createdAt <- map["createdAt"]
        updatedAt <- map["updatedAt"]
        creatorId <- map["creatorId"]
        joinCode <- map["joinCode"]
        members <- map["members"]
        preferences <- map["preferences"]
    }

}

struct Match : Mappable {
    var id : String?
    var group1Id : String?
    var group2Id : String?
    var score : Int?
    var matchedAt : String?
    var group1 : Group1?
    var group2 : Group1?

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {

        id <- map["id"]
        group1Id <- map["group1Id"]
        group2Id <- map["group2Id"]
        score <- map["score"]
        matchedAt <- map["matchedAt"]
        group1 <- map["group1"]
        group2 <- map["group2"]
    }

}


struct Group1 : Mappable {
    var id : String?
    var title : String?
    var description : String?
    var destination : String?
    var startDate : String?
    var endDate : String?
    var travelStyle : String?
    var maxMembers : Int?
    var coverImage : String?
    var isActive : Bool?
    var isPublic : Bool?
    var createdAt : String?
    var updatedAt : String?
    var creatorId : String?
    var joinCode : String?
    var members : [Members]?
    var preferences : Preferences?

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {

        id <- map["id"]
        title <- map["title"]
        description <- map["description"]
        destination <- map["destination"]
        startDate <- map["startDate"]
        endDate <- map["endDate"]
        travelStyle <- map["travelStyle"]
        maxMembers <- map["maxMembers"]
        coverImage <- map["coverImage"]
        isActive <- map["isActive"]
        isPublic <- map["isPublic"]
        createdAt <- map["createdAt"]
        updatedAt <- map["updatedAt"]
        creatorId <- map["creatorId"]
        joinCode <- map["joinCode"]
        members <- map["members"]
        preferences <- map["preferences"]
    }

}






struct ChatData : Mappable {
    var chatId : String?
    var type : String?
    var name : String?
    var image : String?
    var createdAt : String?
    var lastMessageAt : String?
    var lastMessage : LastMessage?
    var members : [UserMembers]?
    init?(map: Map) {

    }

    mutating func mapping(map: Map) {
        members <- map["members"]
        chatId <- map["chatId"]
        type <- map["type"]
        name <- map["name"]
        image <- map["image"]
        createdAt <- map["createdAt"]
        lastMessageAt <- map["lastMessageAt"]
        lastMessage <- map["lastMessage"]
    }

}



struct LastMessage : Mappable {
    var id : String?
    var chatRoomId : String?
    var senderId : String?
    var content : String?
    var fileUrl : String?
    var fileType : String?
    var replyToId : String?
    var reactions : [String]?
    var createdAt : String?
    var sender : Sender?

    init?(map: Map) {

    }

    mutating func mapping(map: Map) {

        id <- map["id"]
        chatRoomId <- map["chatRoomId"]
        senderId <- map["senderId"]
        content <- map["content"]
        fileUrl <- map["fileUrl"]
        fileType <- map["fileType"]
        replyToId <- map["replyToId"]
        reactions <- map["reactions"]
        createdAt <- map["createdAt"]
        sender <- map["sender"]
    }

}
struct ChatInboxModel : Mappable {
    var success : Bool?
    var code : Int?
    var message : String?
    var data : [ChatData]?
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        data <- map["data"]
        success <- map["success"]
        code <- map["code"]
        message <- map["message"]
    }
    
}

struct Members : Mappable {
    var id : String?
    var groupId : String?
    var userId : String?
    var role : String?
    var joinedAt : String?
    var user : User?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        
        id <- map["id"]
        groupId <- map["groupId"]
        userId <- map["userId"]
        role <- map["role"]
        joinedAt <- map["joinedAt"]
        user <- map["user"]
    }
    
}


struct Preferences : Mappable {
    var id : String?
    var groupId : String?
    var minAge : Int?
    var maxAge : Int?
    var preferredGender : String?
    var activityInterests : [String]?
    
    init?(map: Map) {
        
    }
    
    mutating func mapping(map: Map) {
        
        id <- map["id"]
        groupId <- map["groupId"]
        minAge <- map["minAge"]
        maxAge <- map["maxAge"]
        preferredGender <- map["preferredGender"]
        activityInterests <- map["activityInterests"]
    }
    
}

import ObjectMapper

class DashboardResponse: Mappable {
    var success: Bool?
    var code: Int?
    var message: String?
    var data: DashboardData?

    required init?(map: Map) {}

    func mapping(map: Map) {
        success <- map["success"]
        code <- map["code"]
        message <- map["message"]
        data <- map["data"]
    }
}

class DashboardData: Mappable {
    var counts: DashboardCounts?

    required init?(map: Map) {}

    func mapping(map: Map) {
        counts <- map["counts"]
    }
}

class DashboardCounts: Mappable {
    var newMatches: Int?
    var activeChats: Int?
    var savedGroups: Int?

    required init?(map: Map) {}

    func mapping(map: Map) {
        newMatches <- map["newMatches"]
        activeChats <- map["activeChats"]
        savedGroups <- map["savedGroups"]
    }
}
