class Spree::Api::BrandsController < Spree::Api::BaseController

  private

  def collection
    brands = Spree::Brand.select(:title).where('title != ?', 'Not Set')
    Rails.logger.error "\n\nBRAND PRODUCTS: #{brands.map(&:title)}\n\n"
    @collection = { brands: brands.map(&:title) }
  end

end
