#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint memento_nfc.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'memento_nfc'
  s.version          = '0.0.1'
  s.summary          = 'NFC plugin for Memento app to read and write NFC tags.'
  s.description      = <<-DESC
A Flutter plugin for reading and writing NFC tags using NDEF format.
Supports both Android and iOS platforms.
                       DESC
  s.homepage         = 'https://github.com/hunmer/Memento'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Memento Team' => 'hunmer@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '13.0'
  s.frameworks = 'CoreNFC'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'memento_nfc_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
