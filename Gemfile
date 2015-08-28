source 'http://rubygems.org'

gem 'json'
gem 'sqlite3'
gem 'rails', '3.1.1'
gem 'rubyzip', '0.9.9'
gem 'rabl', '0.9.3'

gem 'tax_cloud', '0.2.0'

gem 'spree_reservebar_core', :git => 'git://github.com/ReserveBar1/spree_reservebar_core.git', :branch => 'tests'
gem 'spree_gateway', :git => 'git://github.com/spree/spree_gateway.git', :branch => '1-1-stable'
gem 'active_shipping', :git => 'git://github.com/ReserveBar1/active_shipping.git'
gem 'spree_active_shipping', :git => 'git://github.com/ReserveBar1/spree_active_shipping.git'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails', "~> 3.1.4"
  gem 'coffee-rails', "~> 3.1.1"
  gem 'uglifier'
end

group :test do
  gem 'guard'
  gem 'guard-rspec', '~> 0.5.0'
  gem 'rspec-rails', '~> 2.14.0'
  gem 'factory_girl_rails', '~> 1.5.0'
  gem 'pry-debugger'

  platform :ruby_18 do
    gem 'rcov'
  end

  platform :ruby_19 do
    gem 'simplecov'
  end

  gem 'ffaker'
  gem 'shoulda-matchers', '~> 1.0.0'
  gem 'capybara', '1.1.4'
  gem 'selenium-webdriver', '2.16.0'
  gem 'database_cleaner', '0.7.1'
  gem 'launchy'
end

group :ci do
  gem 'mysql2', '~> 0.3.6'
end

# platform :ruby_18 do
#   gem "ruby-debug"
# end

# platform :ruby_19 do
#   gem "ruby-debug19"
# end

gemspec


