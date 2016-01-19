Pod::Spec.new do |s|
  s.name         = "iTunesSearch"
  s.version      = "1.1.1"
  s.summary      = "Block based iTunes store communication for iOS and Mac OS X."
  s.homepage     = "https://github.com/gangverk/iTunesSearch"
  s.license      = 'MIT'
  s.author       = { "Gangverk" => "contact@gangverk.is" }
  s.source       = { :git => "https://github.com/gangverk/iTunesSearch.git", :tag => s.version.to_s }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.6'
  s.tvos.deployment_target = '9.0'
  s.source_files = 'iTunesSearch/*.{h,m}'
  s.requires_arc = true
end
