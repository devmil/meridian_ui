Pod::Spec.new do |s|
  s.name             = 'meridian_native_menus'
  s.version          = '1.0.0'
  s.summary          = 'Native NSMenu presentation for Meridian menus.'
  s.description      = 'Shows Meridian menu models as NSMenus at a point in the Flutter view.'
  s.homepage         = 'https://github.com/devmil/meridian_ui'
  s.license          = { :type => 'MIT', :file => '../../../LICENSE' }
  s.author           = 'Michael Lamers'
  s.source           = { :path => '.' }
  s.source_files     = 'meridian_native_menus/Sources/meridian_native_menus/**/*.swift'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.14'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
