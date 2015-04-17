class Spree::Api::BrandsController < Spree::Api::BaseController

  private
  
  def collection
    brands = Spree::Brand.select(:title).where('title != ?', 'Not Set')
    @collection = { brands: brands.map(&:title) }
  end

end
