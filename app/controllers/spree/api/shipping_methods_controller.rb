# Available shipping methods as json
class Spree::Api::ShippingMethodsController < Spree::Api::BaseController
  include SslRequirement
  ssl_required

  private

  def collection
    order = Spree::Order.find_by_number(params['id'])
    @collection = []
    Spree::ShippingMethod.all.each do |sm|
      @collection << sm if sm.available_to_order?(order)
    end
    @collection
  end

end
