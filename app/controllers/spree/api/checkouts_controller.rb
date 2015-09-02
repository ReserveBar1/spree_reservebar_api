module Spree
  module Api
    class CheckoutsController < Spree::Api::BaseController
      skip_before_filter :check_http_authorization
      skip_before_filter :load_resource
      before_filter :load_order, :only => :update
      before_filter :associate_user, :only => :update

      #before_filter :associate_user, only: :update

      #include Spree::Core::ControllerHelpers::Auth
      #include Spree::Core::ControllerHelpers::Order
      ## This before_filter comes from Spree::Core::ControllerHelpers::Order
      #skip_before_filter :set_current_order


      #probably skip this
      def create
        @order = Order.build_from_api(current_api_user, nested_params)
        #render file: 'spree/api/orders/create.rabl'
        render json: response_hash(@order).to_json
      end

      def update
        authorize! :update, @order, params[:order_token]
        @order.retailer = Retailer.first
        if @order.state == 'complete'
          respond_with(@order, :default_template => 'spree/api/orders/show')
          render file: 'spree/api/orders/show.rabl'
        else
          if object_params && object_params[:user_id].present?
            @order.update_attribute(:user_id, object_params[:user_id])
            object_params.delete(:user_id)
          end
          if @order.update_attributes(object_params) && @order.next
            state_callback(:after)
            #render file: 'spree/api/checkouts/update.rabl'
            render json: response_hash(@order).to_json
          else
            #render file: 'spree/api/orders/could_not_transition.rabl'
            render json: {error: "Could not transition order state"}.to_json
          end
        end
      end


      def object_params
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

      def before_payment
        @order.payments.destroy_all if request.put?
      end

      #def next!(options={})
        #if @order.valid? && @order.next
          #render 'spree/api/orders/show', :status => options[:status] || 200
        #else
          #render 'spree/api/orders/could_not_transition', :status => 422
        #end
      #end

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
      end
    end
  end
end
