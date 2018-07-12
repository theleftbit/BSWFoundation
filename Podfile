platform :ios, '9.0'
use_frameworks!
inhibit_all_warnings!

target 'BSWFoundationPlayground' do

    pod 'BSWFoundation', :path => './BSWFoundation.podspec'

    target 'Tests' do
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.2'
        end
    end
end
