Rails.application.routes.draw do
  resources :office_hours do
    resources :questions, only: [:create, :index]
  end
  root :to => redirect('/office_hours')
end
