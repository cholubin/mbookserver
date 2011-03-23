# encoding: utf-8

class PagesController < ApplicationController

  def home
    
    user = User.first(:userid => "demo")
    user.update_password("demo")
    user.save
    
    @title  = "home"
    @menu = "main"
    
    @categories = Category.all(:gubun => "template", :order => [:priority])
    
  end

  def sub
    category_id = params[:cat].to_i
    @title  = "home"
    @menu = "sub"
    
    @subcategories = Subcategory.all(:category_id => category_id, :order => [:priority])
    
    render 'home'
  end
  
  def contact
    @title  = "contact"
    @menu = "contact"
  end

  def about
    @title = "about"
    @menu = "about" 
    @categories = Category.all(:gubun => "template", :order => [:priority])

  end
  
  def tutorial
    @title = "tutorial"
    @menu = "tutorial"
    @categories = Category.all(:gubun => "template", :order => [:priority])

  end
  
  def test
    @title = "test"
    @menu = "home"
  end
  
  def login
    @title = "login"
    @menu = "home"    
  end 
  
  def logout
 
  end
  
  def congratulations
    @title = "가입완료"
    @menu = "home"
  end
  
  
  def withdraw
    
    if signed_in?
      @users = current_user
      @menu = "home"
      @board = "user"
      @section = "withdraw"

      render 'users/user' 
    else
      redirect_to '/' 
    end
  end 
end
