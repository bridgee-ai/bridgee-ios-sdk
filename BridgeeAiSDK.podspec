Pod::Spec.new do |s|
  s.name             = 'BridgeeAiSDK'
  s.version          = '1.1.1'
  s.summary          = 'SDK de atribuição completo para conectar campanhas de marketing com instalações iOS'
  
  s.description      = <<-DESC
  O Bridgee iOS SDK é uma solução completa de atribuição que conecta suas 
  campanhas de marketing aos eventos de instalação e primeira abertura do seu 
  aplicativo iOS. Integra-se perfeitamente com provedores de analytics como 
  Firebase Analytics.
  DESC

  s.homepage         = 'https://github.com/bridgee-ai/bridgee-ios-sdk'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bridgee.ai' => 'contato@bridgee.ai' }
  s.source           = { :git => 'https://github.com/bridgee-ai/bridgee-ios-sdk.git', :tag => s.version.to_s }

  s.ios.deployment_target = '14.0'
  s.swift_version = '5.5'

  s.source_files = 'Sources/BridgeeSDK/**/*.{swift,h,m}'
  s.resource_bundles = {"BridgeeSDK": "Sources/BridgeeSDK/Resources/PrivacyInfo.xcprivacy"}
  
  # Frameworks necessários
  s.frameworks = 'Foundation', 'UIKit'
  
end