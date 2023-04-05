#
# Be sure to run `pod lib lint OpenAIKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OpenVPNXor'
  s.version          = '1.2'
  s.summary          = 'Library for simple connection via OpenVPN protocol with Xor patch.'

  s.description      = <<-DESC
OpenVPNXor is a library that allows to configure and establish VPN connection using OpenVPN protocol easily. It is based on the original openvpn3 library so it has every feature the library has.
The library is designed to use in conjunction with NetworkExtension framework and doesn't use any private Apple API. Compatible with iOS and macOS and also Swift friendly.
                       DESC

  s.homepage         = 'https://github.com/FuturraGroup/OpenVPNXor'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Sergey Zhuravel' => 'sergey.zhuravel@icloud.com' }

  s.platform            = :ios, "11.0"
  s.source            = { :http => 'https://github.com/FuturraGroup/OpenVPNXor/raw/main/releases/1.2/OpenVPNXor.framework.zip' }
  s.ios.vendored_frameworks = 'OpenVPNXor.framework'
  s.ios.deployment_target = '11.0'
 s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }


  
end
