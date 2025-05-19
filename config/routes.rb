Rails.application.routes.draw do
  devise_for :clients,
    path: 'clients',
    controllers: {
      sessions: 'clients/sessions',
      registrations: 'clients/registrations'
    },
    defaults: { format: :json }

  devise_for :artisans,
    path: 'artisans',
    controllers: {
      sessions: 'artisans/sessions',
      registrations: 'artisans/registrations'
    },
    defaults: { format: :json }

  namespace :clients, defaults: { format: :json } do
    get 'me', to: 'profiles#show'
    put 'me', to: 'profiles#update'
    delete 'me', to: 'profiles#destroy'
  end

  namespace :artisans, defaults: { format: :json } do
    get 'me', to: 'profiles#show'
    put 'me', to: 'profiles#update'
    delete 'me', to: 'profiles#destroy'
    get 'me/plan_info', to: 'profiles#plan_info'
  end

  post "/stripe/create-checkout-session", to: "payments#create_checkout_session"
  post '/webhooks/stripe', to: 'webhooks#stripe'

  get "up" => "rails/health#show", as: :rails_health_check

  # root "posts#index"
end

