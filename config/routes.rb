GhStock::Application.routes.draw do
  root :to => 'home#index'
  match '/refresh', :via => [:post, :get], :to => 'home#refresh'
end
