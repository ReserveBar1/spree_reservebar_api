Spree::Core::Engine.routes.prepend do
  namespace :api do
    resources :brands, except:  [:new,:edit]
    resources :images
    resources :checkouts
    resources :variants, :only => [:index] do
    end

    put '/shipping_methods', to: 'shipping_methods#index'

    resources :orders do
      resources :return_authorizations
      member do
        put :address
        put :delivery
        put :cancel
        put :empty
      end

      resources :line_items
      resources :payments do
        member do
          put :authorize
          put :capture
          put :purchase
          put :void
          put :credit
        end
      end

      resources :shipments do
        member do
          put :ready
          put :ship
        end
      end
    end
  end
end
