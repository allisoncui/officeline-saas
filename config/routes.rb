Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations'
  }

  get 'my_classes', to: 'students#show', as: :student_profile
  get 'my_questions', to: 'students#questions', as: :student_questions

  resources :office_hours do
    resource :enrollment, only: [:create, :destroy], controller: 'enrollments'
    resources :questions, only: [:create, :index, :edit, :update, :destroy]
    
    # Queue routes
    resources :queue_entries, only: [:create, :destroy] do
      member do
        delete :remove_student
      end
    end
    
    post 'start_queue', to: 'queue_entries#start_queue'
    post 'close_queue', to: 'queue_entries#close_queue'
    
    # Polling endpoint for queue updates
    member do
      get :queue_status
    end
  end
  
  root 'office_hours#index'
end