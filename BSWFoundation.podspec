
Pod::Spec.new do |s|
  s.name         = "BSWFoundation"
  s.version      = "0.2.2"
  s.summary      = "This framework creates the infrastructure that it's used throughout Blurred Software's projects."
  s.homepage     = "https://github.com/BlurredSoftware/BSWFoundation"
  s.license      = "MIT"
  s.author             = { "Pierluigi Cifani" => "pcifani@blurredsoftware.com" }
  s.social_media_url   = "http://twitter.com/piercifani"

  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.11"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/BlurredSoftware/BSWFoundation.git", :tag => "#{s.version}" }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source_files  = "Source/**/*.{swift,m,h}"

  # ――― Dependencies ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.dependency "Alamofire", "~> 4.0.1"
  s.dependency "BNRDeferred", "3.0.0-beta.2"
  s.dependency "Decodable", "~> 0.5"

  # ――― Swift Version ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '3.0' }

end
