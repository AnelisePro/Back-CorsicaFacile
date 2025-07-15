Rails.application.routes.draw do
  get 'uploads/presigned_url'
  get 'expertises/index'
  get 'artisans/index'
  get '/annonces/:id', to: 'annonces#show'
  get '/artisan-profile/:id', to: 'artisans#show', as: 'artisan-profile'
  resources :client_notifications, only: [:index, :create, :update, :destroy]
  get '/client_notifications/check', to: 'client_notifications#check_response'

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
    get 'me/plan_info', to: 'profiles#plan_info'
    get 'notifications', to: 'notifications#index'
    put 'notifications/:id/read', to: 'notifications#mark_as_read'
    delete 'notifications/:id', to: 'notifications#destroy'
    resources :besoins, only: [:index]
    resources :availability_slots, only: [:index, :create, :update, :destroy]
    resource :profile, only: [:show, :update, :destroy]
    resources :project_images, only: [:index, :create, :destroy]
  end

  resources :artisans, only: [:index, :show]
  get '/api/expertises', to: 'expertises#index'
  post "/stripe/create-checkout-session", to: "payments#create_checkout_session"
  post '/webhooks/stripe', to: 'webhooks#stripe'
  post '/presigned_url', to: 'uploads#presigned_url'

  get "up" => "rails/health#show", as: :rails_health_check

  # root "posts#index"
end

