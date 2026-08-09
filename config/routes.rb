Rails.application.routes.draw do
  resource :registration, only: %i[ new create ]
  resource :session, only: %i[ new create destroy ]
  resources :passwords, param: :token, only: %i[ new create edit update ]

  resources :categories
  resources :plans

  namespace :actuals do
    resource :import, only: %i[ new create ]
    resource :import_template, only: :show
  end
  resources :actuals

  resources :locks, only: %i[ index new create destroy ]

  namespace :reports do
    resources :entries, only: :index
  end
  resources :reports, only: :index

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
