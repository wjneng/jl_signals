#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint jl_signals.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'jl_signals'
  s.version          = '0.0.1'
  s.summary          = 'Flutter wrapper for the Ocean Engine conversion signal SDK.'
  s.description      = <<-DESC
Flutter wrapper for the Ocean Engine conversion signal SDK. This plugin keeps
the Dart API small and calls the native SDK methods documented by Ocean Engine.
                       DESC
  s.homepage         = 'https://github.com/wjneng/jl_signals'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'wjneng' => 'https://github.com/wjneng' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'BDASignalSDK'
  s.platform = :ios, '13.0'
  s.weak_frameworks = 'AppTrackingTransparency', 'AdSupport'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  s.resource_bundles = {'jl_signals_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
