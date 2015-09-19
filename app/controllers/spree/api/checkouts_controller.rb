require 'card_reuse'

module Spree
  module Api
    class CheckoutsController < Spree::Api::BaseController


      include SslRequirement
      include CardReuse

      ssl_required
      skip_before_filter :check_http_authorization
      skip_before_filter :load_resource
      before_filter :load_order, :only => :update
      before_filter :associate_user, :only => :update
      before_filter :set_address_state_id, :only => :update

      def create
        @order = Order.build_from_api(current_api_user, nested_params)
        render json: response_hash(@order).to_json
      end

      def update
        authorize! :update, @order, params[:order_token]
        if @order.update_attributes(object_params)
          #fire_event('spree.checkout.update')

          if @order.next
            state_callback(:after)
          else
            render json: {error: "Could not transition order state"}.to_json
            return
          end
          render json: response_hash(@order).to_json
        else
          render json: response_hash(@order).to_json
        end
      end


      def object_params
        if @order.payment?
          if params[:bill_address].present?
            @order.bill_address_attributes = params[:bill_address]
            bill_address = @order.bill_address
            if bill_address && bill_address.valid?
              @order.update_attribute_without_callbacks(:bill_address_id, bill_address.id)
              bill_address.update_attribute(:user_id, current_user.id) if current_user
              params[:order].delete(:bill_address_id)
            else
              raise Exceptions::NewBillAddressError
            end
            @order.reload
            params[:order][:payments_attributes].first[:source_attributes][:address_id] = @order.bill_address_id
          else
              raise 'No Billing Address'
          end

          if params[:order].present? && params[:order][:payments_attributes].present?
            params[:order][:payments_attributes].first[:amount] = @order.total
          end
        end
        params[:order]
      end

      def nested_params
        map_nested_attributes_keys Order, params[:order] || {}
      end

      # Should be overriden if you have areas of your checkout that don't match
      # up to a step within checkout_steps, such as a registration step
      def skip_state_validation?
        false
      end

      def current_order(create_if_necessary = false)
        @order = Spree::Order.find_by_number!(params[:id])
      end

      def load_order
        @order = Spree::Order.find_by_number!(params[:id])
        raise_insufficient_quantity and return if @order.insufficient_stock_lines.present?
        @order.state = params[:state] if params[:state]
        state_callback(:before)
      end

      def raise_insufficient_quantity
        respond_with(@order, :default_template => 'spree/api/orders/insufficient_quantity')
      end

      def state_callback(before_or_after = :before)
        method_name = :"#{before_or_after}_#{@order.state}"
        send(method_name) if respond_to?(method_name, true)
      end

      def before_address
        @order.bill_address ||= Address.default
        @order.ship_address ||= Address.default
      end

      def before_delivery
        return if params[:order].present?
        @order.shipping_method ||= (@order.rate_hash.first && @order.rate_hash.first[:shipping_method])
      end

      def has_checkout_step?(step)
        step.present? ? self.checkout_steps.include?(step) : false
      end


      def order_url(order)
        spree.api_order_url(order)
      end

      def response_hash(order)
        rh = {order: { token: order.token, line_items: [] } }
        rh =  order.attributes.keys.each_with_object(rh) do |k|
          rh[:order][k] = order.attributes[k]
          rh
        end
        order.line_items.each_with_object(rh) do |li|
          rh[:order][:line_items] << { quantity: li.quantity, price: li.price, variant: {name: li.variant.name}}
          rh
        end
        if order.ship_address && order.bill_address
          rh[:order][:ship_address] = {}
          rh[:order][:bill_address] = {}
          rh[:order][:ship_address][:firstname] = order.ship_address.firstname
          rh[:order][:ship_address][:lastname] = order.ship_address.lastname
          rh[:order][:bill_address][:id] = order.bill_address.id
        end
        rh
      end

      def set_address_state_id
        if params[:bill_address]
            state = params[:bill_address].delete(:state)
            state = Spree::State.find_by_abbr(state)
            params[:bill_address][:state_id] = state.id
        end
        [:bill_address_attributes, :ship_address_attributes].each do |address_type|
          if params[:order] && params[:order][address_type]
            state = params[:order][address_type].delete(:state)
            state = Spree::State.find_by_abbr(state)
            params[:order][address_type][:state_id] = state.id
          end
        end
      end

      def before_payment
        @order.payments.destroy_all if request.put?
        @order.bill_address = Spree::Address.default
        @cards = all_cards_for_user(@order.user, @order.retailer)
        @cards = @cards.reject { |c| c.expired? }
      end

    end
  end
end
