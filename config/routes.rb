Rails.application.routes.draw do
  resources :office_hours
  root :to => redirect('/office_hours')
end
