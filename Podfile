platform :ios, '9.0'
use_frameworks!

abstract_target 'Common' do

    pod 'BSWFoundation', :path => './BSWFoundation.podspec'

    target 'BSWFoundationPlayground'
    target 'Tests'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = "4.0"
    end
  end
end
