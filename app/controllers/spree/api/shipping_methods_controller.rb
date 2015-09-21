class Spree::Api::ShippingMethodsController < Spree::Api::BaseController
  skip_before_filter :check_for_api_key
  skip_before_filter :authenticate_user
end
