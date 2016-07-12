Pod::Spec.new do |s|
  s.name         = "NTYPomeloKit"
  s.version      = "0.0.1"
  s.summary      = "Ninty pomelo kit for iOS"
  s.homepage     = "https://github.com/ninty90/NTYPomeloKit.git"
  s.license      = "MIT"
  s.author       = { "Yinglun Duan" => "duanyinglun@ninty.cc" }
  s.ios.deployment_target = "8.0"
  s.source       = { :git => "https://github.com/ninty90/NTYPomeloKit.git", :tag => s.version }
  s.source_files = "Source/*.{h,m}"
  s.ios.frameworks     = 'CFNetwork', 'Security'
  s.libraries          = "icucore"
end
