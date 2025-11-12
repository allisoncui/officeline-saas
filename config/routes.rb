Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }
  resources :office_hours do
    resources :questions, only: [:create, :index]
  end
  root 'office_hours#index'
end
