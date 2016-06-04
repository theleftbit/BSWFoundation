
Pod::Spec.new do |s|
  s.name         = "BSWFoundation"
  s.version      = "0.0.1"
  s.summary      = "A short description of BSWFoundation."
  s.homepage     = "https://github.com/BlurredSoftware/BSWFoundation"
  s.license      = "MIT"
  s.author             = { "Pierluigi Cifani" => "pcifani@blurredsoftware.com" }
  s.social_media_url   = "http://twitter.com/piercifani"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.11"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/BlurredSoftware/BSWFoundation.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "Source/**/*.{swift,m,h}"

  # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.dependency "Alamofire", "~> 3.3.1"
  s.dependency "BNRDeferred", "~> 2.0.0-rc.1"
  s.dependency "Decodable", "~> 0.4.2"

end
