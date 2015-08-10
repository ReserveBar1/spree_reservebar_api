Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_reservebar_api'
  s.version     = '0.0.1'
  s.summary     = 'Spree Commerce API for reservebar.com'

  s.author        = 'Jason Knebel'
  s.email         = 'jknebel@reservebar.com'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_path = 'lib'
  s.requirements << 'none'

  s.has_rdoc = false
  s.add_dependency 'spree_core', '1.0.3'
  s.add_dependency 'spree_auth', '1.0.3'
  s.add_dependency 'spree_api', '1.0.3'
end
