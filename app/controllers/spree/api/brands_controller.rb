class Spree::Api::BrandsController < Spree::Api::BaseController
  include SslRequirement

  ssl_required

  private

  def collection
    brands = Spree::Brand.where('title != ?', 'Not Set').map { |b| { title: b.title, id: b.id } }
    @collection = { brands: brands }
  end

end
