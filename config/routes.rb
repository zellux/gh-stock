GhStock::Application.routes.draw do
  root :to => 'home#index'
  match '/refresh', :via => :post, :to => 'home#refresh'
end
