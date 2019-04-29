Pod::Spec.new do |spec|
    spec.name     = 'WVJSB'
    spec.version  = '1.0.1'
    spec.license  = 'MIT'
    spec.summary  = 'WebView JavaScript Bridge'
    spec.homepage = 'https://github.com/retriable/WVJSB'
    spec.author   = { 'retriable' => 'retriable@retriable.com' }
    spec.source   = { :git => 'https://github.com/retriable/WVJSB.git',:tag => "#{spec.version}" }
    spec.description = 'Cross-iframe WebView JavaScript Bridge.'
    spec.requires_arc = true
    spec.source_files = 'WVJSB/*.{h,m}'
    spec.resource = 'WVJSB/Resources/Proxy.js'
    spec.ios.frameworks = 'UIKit','WebKit'
    spec.osx.frameworks = 'WebKit'
    spec.ios.deployment_target = '8.0'
    spec.osx.deployment_target = '10.10'
end
