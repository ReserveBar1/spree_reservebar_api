Spree::Core::Engine.routes.prepend do

  namespace :api do
    resources :brands, :except => [:new,:edit]
  end

end
