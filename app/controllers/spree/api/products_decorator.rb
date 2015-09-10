Spree::Api::ProductsController.class_eval do
  def show
    respond_with(@object) do |format|
      format.json { render :json => @object.attributes.merge( 'sku' => @object.sku).to_json(object_serialization_options) }
    end
  end

  private

  def collection
    return 'brand needed' unless params['brand'].present?
    brand_id = Spree::Brand.find_by_title(params['brand']).id
    products = Spree::Product.active.available.where(brand_id: brand_id)
    @collection = { products: products.map { |p|
      { sku: p.sku, name: p.name, permalink: p.permalink, id: p.id, states_available: p.ships_to_states } } }
  end

  def object_serialization_options
    # overiding method provided by SpreeApi
  end

end
