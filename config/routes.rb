Rails.application.routes.draw do
  get 'expertises/index'
  get 'artisans/index'

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
    resources :besoins, only: [:index, :create, :update, :destroy]
  end

  namespace :artisans, defaults: { format: :json } do
    get 'me', to: 'profiles#show'
    put 'me', to: 'profiles#update'
    delete 'me', to: 'profiles#destroy'
    delete 'delete_project_image/:image_id', to: 'profiles#delete_project_image'
    get 'me/plan_info', to: 'profiles#plan_info'
    
    resources :besoins, only: [:index]
    resources :availability_slots, only: [:index, :create, :update, :destroy]
  end

  resources :artisans, only: [:index, :show]
  get '/api/expertises', to: 'expertises#index'
  post "/stripe/create-checkout-session", to: "payments#create_checkout_session"
  post '/webhooks/stripe', to: 'webhooks#stripe'

  get "up" => "rails/health#show", as: :rails_health_check

  # root "posts#index"
end

