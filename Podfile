use_modular_headers!

target 'BSWFoundationPlayground-iOS' do
    platform :ios, '9.0'

    pod 'BSWFoundation', :path => './BSWFoundation.podspec'

    target 'Tests-iOS' do
    end
end

target 'BSWFoundationPlayground-tvOS' do
    platform :tvos, '9.0'

    pod 'BSWFoundation', :path => './BSWFoundation.podspec'

    target 'Tests-tvOS' do
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '4.1.0'
        end
    end
end
