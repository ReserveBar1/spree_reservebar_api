# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment", __FILE__)
require 'rspec/rails'
require 'database_cleaner'
require 'spree/core/testing_support/factories'
require 'spree/core/testing_support/env'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

# load default data for tests
require 'active_record/fixtures'

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.before(:suite) do
    DatabaseCleaner.strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  config.include Spree::Core::Engine.routes.url_helpers,
                 example_group: {
                   file_path: %r{\bspec\/requests\/}
                 }

  config.include Devise::TestHelpers, type: :controller
  config.include Rack::Test::Methods, type: :request
end

def api_login(user)
  authorize user.authentication_token, 'X'
end

def current_api_user
  @current_api_user ||= stub_model(Spree::User, email: 'spree@example.com')
end

def stub_authentication!
  controller.stub :check_for_api_key
  Spree::User.stub find_by_spree_api_key: current_api_user
end

def json_response
  JSON.parse(response.body)
end

def assert_unauthorized!
  json_response.should == { 'error' => 'Invalid order token' }
  response.status.should == 401
end

 


def sign_in_as_admin!
  let!(:current_api_user) do
    user = stub_model(Spree::User)
    user.should_receive(:has_spree_role?).any_number_of_times.with("admin").and_return(true)
    user
  end
end

shared_examples_for "status ok" do
  it "should return status 200" do
    last_response.status.should == 200
  end
end

shared_examples_for "unauthorized" do
  it "should return status 401" do
    last_response.status.should == 401
  end
end

RSpec::Matchers.define :have_attributes do |expected_attributes|
  match do |actual|
    # actual is a Hash object representing an object, like this:
    # { "name" => "Product #1" }
    actual_attributes = actual.keys.map(&:to_sym)
    expected_attributes.map(&:to_sym).all? { |attr| actual_attributes.include?(attr) }
  end
end


Spree::AppConfiguration.class_eval do
  preference :tax_using_retailer_address, :boolean
  preference :taxon_preview_max_products, :integer
  preference :mail_bcc, :string, :default => 'management@reservebar.com'
  preference :mail_cc, :string
  preference :mail_notification_to, :string, :default => 'management@reservebar.com'
  preference :corporate_fedex_account_number, :string
  preference :use_age_gate_on_all_pages, :boolean, :default => false
  preference :checkout_zone, :string
  preference :use_taxcloud, :boolean
  preference :use_county_based_routing, :boolean, :default => false
end

