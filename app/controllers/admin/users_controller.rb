# encoding: utf-8

class Admin::UsersController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!      
  # GET /users
  # GET /users.xml
  def index
    @users = User.all()
    
    puts_message @users.count.to_s
    
    if params[:auth] != nil and params[:auth] != "" and params[:auth] != "all"
        user_auth_fl = (params[:auth] == "true") ? true : false
        @users = @users.all(:auth_fl => user_auth_fl)
    end
    
    puts_message @users.count.to_s
    
    if params[:type] != nil and params[:type] != "" and params[:type] != "all"
      @users = @users.all(:type => params[:type])
    end
    
    puts_message @users.count.to_s
    
    @users = @users.search_admin(params[:keyword], params[:search], params[:page])
    @total_count = User.search_admin(params[:keyword], params[:search],"").count
        
    @menu_on = "user"
    @board = "user"
    @section = "index"
    
    render 'admin/users/user'
  end

  # GET /users/1
  # GET /users/1.xml
  def show

    @user = User.get(params[:id])
        
    if admin_signed_in?
      @menu = "home"
      @board = "user"
      @section = "show"
    
      render 'admin/users/user'
    else
      redirect_to '/'
    end
  end

  # multiple deletion
  def deleteSelection 

    chk = params[:ids].split(",")
    result = ""
    if !chk.nil? 
      chk.each do |chk|
        @user = User.get(chk.to_i)
        
        begin
          mbooks = Mbook.all(:user_id => @user.id)  
          mbooks.each do |mbook|
            if File.exists?(mbook.zipfile)
              FileUtils.rm_rf(mbook.zipfile)
            end
            
            if File.exists?(mbook.zip_path)
              FileUtils.rm_rf(mbook.zip_path)
            end
          end
          
          if mbooks.count > 0
            mbooks.destroy
          end
          
          if @user.destroy   
            result = "success"
          else
            result = "fail"
          end
          
        rescue
          result = "fail"
        end 
      end
    end
    
    render :text => result
  end

  def initialize_password
    id = params[:id].to_i
    
    user = User.get(id)
    user.update_password("1234")
    
    if user.save
      render :text => "success"
    else
      render :text => "fail"
    end
  end
  
  def pop_user
    user_id = params[:user_id]
    
    @user = User.get(user_id.to_i)
    
    render :update do |page|
      page.replace_html 'pop_user', :partial => 'pop_user', :object => @user
    end
  end
  
  def init_user_password
    user_id = (params[:user_id] != nil and params[:user_id] != "") ? params[:user_id].to_i : nil
    
    if user_id != nil
      user = User.get(user_id)
      user.update_password("1234")
      if user.save
        render :text => "success"
      else
        render :text => "fail"
      end
    else
      render :text => "fail"
    end
  end
end
