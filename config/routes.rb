ActionController::Routing::Routes.draw do |map|
  map.resources :userbooks
  map.resources :myadmins
  map.resources :adminsessions  

  # map.resources :temps, :only => [:index, :show]
  map.resources :sessions, :only => [:new, :create, :destory]
  map.login '/login', :controller => 'sessions', :action => 'new'
  map.logout '/logout', :controller => 'sessions', :action => 'destroy'

  map.login '/admin/login', :controller => 'adminsessions', :action => 'new'
  map.login '/admin', :controller => 'adminsessions', :action => 'new'
  map.join '/join', :controller => 'users', :action => 'new'
  map.logout '/admin/logout', :controller => 'adminsessions', :action => 'destroy'
  
  map.root :controller => 'pages', :action => 'home'
  map.sub '/sub', :controller => 'pages', :action => 'sub'
  map.booklist '/booklist', :controller => 'mbooks', :action => 'booklist'
  
  # map.resources :pages
  map.resources :subcategories, :categories
  map.resources :categories, :has_many => :subcategories
  map.resources :users
  map.resources :mbooks, :mpoints
  
  map.namespace :admin do |admin|
      admin.resources :users, :temps, :categories, :subcategories, :myadmins, :mbooks, :mpoints
  end 
  
  
  # API
  map.register '/register.htm', :controller => 'apis', :action => 'register'
  map.reader_login '/login.htm', :controller => 'apis', :action => 'reader_login'
  map.memberout '/memberout.htm', :controller => 'apis', :action => 'memberout'
  map.modifymember '/modifymember.htm', :controller => 'apis', :action => 'modifymember'
  map.notification '/notification.htm', :controller => 'apis', :action => 'notification'
  map.userbooklist '/userbooklist.htm', :controller => 'apis', :action => 'userbooklist'
  map.userbookitems '/userbookitems.htm', :controller => 'apis', :action => 'userbookitems'
  
  map.mbookdownchk '/mbookdownchk.htm', :controller => 'apis', :action => 'mbookdownchk'
  map.mbookdown '/mbookdown.htm', :controller => 'apis', :action => 'mbookdown'
  map.mbookdownconfirm '/mbookdownconfirm.htm', :controller => 'apis', :action => 'mbookdownconfirm'
  map.mbookinfo '/mbookinfo.htm', :controller => 'apis', :action => 'mbookinfo'
  map.store '/store.htm', :controller => 'apis', :action => 'store'
  map.auth '/auth.htm', :controller => 'apis', :action => 'authentication'
  
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
