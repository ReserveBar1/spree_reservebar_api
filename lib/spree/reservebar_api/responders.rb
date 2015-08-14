require 'spree/reservebar_api/responders/rabl_template'

module Spree
  module ReservebarApi
    module Responders
      class AppResponder < ActionController::Responder
        include RablTemplate
      end
    end
  end
end
