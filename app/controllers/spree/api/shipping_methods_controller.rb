# Available shipping methods as json
class Spree::Api::ShippingMethodsController < Spree::Api::BaseController
  include SslRequirement
  ssl_required
end
