Rails.application.routes.draw do
  get 'reviews/create'
  get 'reviews/show'
  get 'reviews/create'
  get 'uploads/presigned_url'
  get 'expertises/index'
  get 'artisans/index'
  get '/annonces/:id', to: 'annonces#show'
  get '/artisan-profile/:id', to: 'artisans#show', as: 'artisan-profile'
  resources :client_notifications, only: [:index, :create, :update, :destroy]
  get '/client_notifications/check', to: 'client_notifications#check_response'
  resources :reviews, only: [:create, :show]
  get 'reviews/for_notification/:notification_id', to: 'reviews#for_notification'
  get 'artisans/:artisan_id/reviews', to: 'reviews#index'

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

  # ROUTES POUR LA RÉINITIALISATION DE MOT DE PASSE
  namespace :api do
    namespace :v1 do
      post 'password_resets/artisan', to: 'password_resets#create_artisan'
      post 'password_resets/client', to: 'password_resets#create_client'
      put 'password_resets/artisan/update', to: 'password_resets#update_artisan'
      put 'password_resets/client/update', to: 'password_resets#update_client'
    end
  end

  namespace :clients, defaults: { format: :json } do
    get 'me', to: 'profiles#show'
    put 'me', to: 'profiles#update'
    delete 'me', to: 'profiles#destroy'
    resources :besoins, only: [:index, :create, :update, :destroy]
    resources :conversations, only: [:index, :create, :show] do
      member do
        post :send_message
        put :mark_as_read
        patch :archive
        patch :unarchive
        delete :destroy
      end
      collection do
        get :archived
      end
    end
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
    resources :conversations, only: [:index, :create, :show] do
      member do
        post :send_message
        put :mark_as_read
        patch :archive
        patch :unarchive
        delete :destroy
      end
      collection do
        get :archived
      end
    end
  end

  resources :artisans, only: [:index, :show]
  get '/api/expertises', to: 'expertises#index'
  post "/stripe/create-checkout-session", to: "payments#create_checkout_session"
  post '/webhooks/stripe', to: 'webhooks#stripe'
  post '/presigned_url', to: 'uploads#presigned_url'

  get "up" => "rails/health#show", as: :rails_health_check

  # root "posts#index"
end



