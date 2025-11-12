Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  get 'my_classes', to: 'students#show', as: :student_profile
  get 'my_questions', to: 'students#questions', as: :student_questions

  resources :office_hours do
    resource :enrollment, only: [:create, :destroy], controller: 'enrollments'
    resources :questions, only: [:create, :index, :edit, :update, :destroy]
  end
  root 'office_hours#index'
end
