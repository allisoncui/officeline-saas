Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  get 'my_classes', to: 'students#show', as: :student_profile
  get 'my_hours', to: 'students#my_hours', as: :student_my_hours
  get 'my_questions', to: 'students#questions', as: :student_questions
  
  # Route for saving a class (by course_name)
  post 'save_class', to: 'students#save_class', as: :save_class
  delete 'remove_class', to: 'students#remove_class', as: :remove_class

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