ActionController::Routing::Routes.draw do |map|
  map.resources :myadmins
  map.resources :adminsessions  

  # map.resources :temps, :only => [:index, :show]
  map.resources :sessions, :only => [:new, :create, :destory]
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.login '/admin/login', :controller => 'adminsessions', :action => 'new'
  map.login '/admin', :controller => 'adminsessions', :action => 'new'
  map.logout '/admin/logout', :controller => 'adminsessions', :action => 'destroy'
  
  map.root :controller => 'pages', :action => 'home'
  map.sub '/sub', :controller => 'pages', :action => 'sub'
  map.booklist '/booklist', :controller => 'mbooks', :action => 'booklist'
  
  # map.resources :pages
  map.resources :subcategories, :categories
  map.resources :categories, :has_many => :subcategories
  map.resources :users
  map.resources :mbooks
  
  map.namespace :admin do |admin|
      admin.resources :users, :temps, :categories,:myadmins, :mbooks
  end 
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
