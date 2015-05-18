Rails.application.routes.draw do
  # Support both GET and POST
  get 'photo/search'
  post 'photo/search'
  root 'photo#index'
end
