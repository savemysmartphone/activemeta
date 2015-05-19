Gem::Specification.new do |s|
  s.name        = 'activemeta'
  s.version      = '0.0.1'
  s.platform     = Gem::Platform::RUBY
  s.licenses     = ['MIT']
  s.summary      = 'Separate model behaviour and model properties'
  s.homepage     = 'https://github.com/savemysmartphone/activemeta'
  s.description  = 'ActiveMeta provides a simple DSL to define model properties outside model files'
  s.authors      = ["Arnaud 'red' Rouyer"]

  s.files        = `git ls-files`.split("\n")
  s.require_path = 'lib'
  s.required_ruby_version = '>= 2.0.0'
end
