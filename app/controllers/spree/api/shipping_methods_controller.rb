class Spree::Api::ShippingMethodsController < Spree::Api::BaseController
  skip_before_filter :check_for_api_key
end
