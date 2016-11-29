Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
   root to: "setup#index"
   devise_scope :user do
    get '/users/sign_out' => 'devise/sessions#destroy'
      resource :setup
  end
end
