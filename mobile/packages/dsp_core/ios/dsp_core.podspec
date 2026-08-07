Pod::Spec.new do |s|
  s.name             = 'dsp_core'
  s.version          = '0.1.0'
  s.summary          = 'AetherRide dsp_core FFI'
  s.homepage         = 'https://github.com/dmghausundhof-dot/aetherride'
  s.license          = { :type => 'proprietary' }
  s.author           = { 'AetherRide' => 'dev@aetherride.app' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
