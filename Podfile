
platform :ios, '18.0'

target 'TravelDate' do
  use_frameworks!

  # Authentication
  pod 'GoogleSignIn'
  pod 'Firebase'
  pod 'FirebaseAuth'
  pod 'FirebaseMessaging'

  # Networking
  pod 'Alamofire'

  # Models and utilities
  pod 'ObjectMapper', '~> 4.2'
  pod 'IQKeyboardManagerSwift'
  pod 'CountryKit'

  # Images
  pod 'Kingfisher', '~> 7.11'
  pod 'SDWebImage'

  # Socket connection
  pod 'Socket.IO-Client-Swift', '~> 16.0'

  # Subscription / Paywall
  pod 'SuperwallKit', '< 5.0.0'

  # Optional
  # pod 'PhoneNumberKit'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
    end
  end
end

