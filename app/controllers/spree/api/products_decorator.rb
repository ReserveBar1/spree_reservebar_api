Spree::Api::ProductsController.class_eval do
  include SslRequirement

  ssl_required

  def show
    respond_with(@object) do |format|
      format.json {
        render :json => @object.attributes
                               .merge('sku' => @object.sku)
                               .merge('price' => @object.price)
                               .merge('id' => @object.master.try(:id))
                               .merge('variant_id' => @object.master.try(:id))
                               .to_json(object_serialization_options)
      }
    end
  end

  private

  def collection
    return 'brand needed' unless params['brand'].present?
    brand_id = Spree::Brand.find_by_title(params['brand']).id
    products = Spree::Product.active.where(brand_id: brand_id)
    products = products.select { |p| p.master.present? }
    @collection = {
      products: products.map { |p|
        { sku: p.sku,
          name: p.name,
          permalink: p.permalink,
          id: p.id,
          price: p.price,
          states_available: product_ships_to_states(p)
        }
      }
    }
  end

  def object_serialization_options
    # overiding method provided by SpreeApi
  end

  def product_ships_to_states(product)
    product.ships_to_states.sub('and','').split(',').to_a.map(&:strip)
  end

end
