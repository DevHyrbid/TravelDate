import Foundation
import ObjectMapper
import UIKit
import Alamofire


class User : Mappable {
    var day : String?
    var name : String?
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
    
    
    var subject :  String?
    var message : String?
    
    var title :  String?
    var description : String?
    var notificationOn : Int?
    
    var profile_image :  String?
    var social_type :  String?
    var social_id :  String?
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        
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
        dob <- map["dob"]
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
                print(newValue?.toJSON() as Any)
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
                if responseObject["statusCode"] as? Int ?? 0 == 201 {
                    if let data = responseObject["data"] as? [String :Any] {
                        print(data,"USER")
                        UserDefaults.standard.setValue(data["access_token"], forKey: "UserToken")
                        User.curentUser = Mapper<User>().map(JSON: data["user"] as? [String:Any] ?? [:])
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
    }
    
    
    func loginAPi(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        if self.email == "" {
            callBack(nil,Constants.Validation.emailEmpty,400)
        } else if !(self.email!.isValidEmail()) {
            callBack(nil,Constants.Validation.emailInvalid,400)
        } else if self.password == ""{
            callBack(nil,Constants.Validation.password,400)
        } else {
            NetworkManger.sendRequestAF(urlPath: APiConstant.loginAPi, type: .post, parms: self.toJSON()) { responseObject, suces in
                
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
                callBack(nil,errMsg, errCode)
            }
        }
    }
//    "http://85.31.234.205:9800/api/v1/users/social-login"
    
    
    func socialLogin(callBack:((_ loginUser:User?,_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.socialLogin, type: .post, parms: self.toJSON()) { responseObject, suces in
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
    
    
    func changePwd(callBack:((_ errMsg:String,_ errCode:Int)->Void)!) {
        
        
        NetworkManger.sendRequestAF(urlPath: APiConstant.changePassword, type: .patch, parms: self.toJSON()) { responseObject, suces in
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
    
    
}
