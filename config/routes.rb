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

  namespace :settings do
    resources :api_tokens, only: %i[ index new create update destroy ] do
      scope module: :api_tokens do
        resource :rotation, only: :create
      end
    end
  end

  namespace :api do
    namespace :v1 do
      resources :categories, except: %i[ new edit ]
      resources :plans, except: %i[ new edit ]

      namespace :actuals do
        resource :import, only: :create
      end
      resources :actuals, except: %i[ new edit ]

      resources :locks, only: %i[ index show create destroy ]
      resource :report, only: :show
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
