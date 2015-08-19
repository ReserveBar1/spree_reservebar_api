Spree::Order.class_eval do
  #attr_accessible :channel, :as => :api_admin

  alias_attribute :billing_address, :bill_address
  alias_attribute :shipping_address, :ship_address

  def self.build_from_api(user, params)
    begin
      order = create!

      #order.create_shipments_from_api params.delete(:shipments_attributes) || []
      order.create_line_items_from_api params.delete(:line_items_attributes) || {}
      #order.create_adjustments_from_api params.delete(:adjustments_attributes) || []
      #order.create_payments_from_api params.delete(:payments_attributes) || []
      #order.complete_from_api params.delete(:completed_at)

      #destroy_automatic_taxes_on_import(order, params)

      if user.has_role? "admin"
        order.update_attributes!(params, without_protection: true)
      else
        order.update_attributes!(params)
      end

      order.reload
    rescue Exception => e
      order.destroy if order && order.persisted?
      raise e.message
    end
  end

  def create_line_items_from_api(line_items_hash)
    line_items_hash.each_key do |k|
      begin
        line_item = line_items_hash[k]

        item = self.add_variant(Spree::Variant.find_by_sku(line_item[:variant_id]), line_item[:quantity].to_i)

        if line_item.key? :price
          item.price = line_item[:price]
          item.save!
        end
      rescue Exception => e
        raise "Order import line items: #{e.message} #{line_item}"
      end
    end
  end

end
