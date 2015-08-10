Spree::Api::ProductsController.class_eval do
  private

  def collection
    return 'brand needed' unless params['brand'].present?
    brand_id = Spree::Brand.find_by_title(params['brand']).id
    products = Spree::Product.active.available.where(brand_id: brand_id)
    @collection = { products: products.map { |p|
      { sku: p.sku, name: p.name, permalink: p.permalink, id: p.id } } }
  end

  def object_serialization_options
    # overiding method provided by SpreeApi
  end

end
