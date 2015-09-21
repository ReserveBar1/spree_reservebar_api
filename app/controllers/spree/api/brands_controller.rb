class Spree::Api::BrandsController < Spree::Api::BaseController
  skip_before_filter :authenticate_user
  skip_before_filter :check_for_api_key

  private

  def collection
    brands = Spree::Brand.where('title != ?', 'Not Set').map { |b| { title: b.title, id: b.id } }
    @collection = { brands: brands }
  end

end
