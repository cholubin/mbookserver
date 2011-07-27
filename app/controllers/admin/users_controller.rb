# encoding: utf-8

class Admin::UsersController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!      
  # GET /users
  # GET /users.xml
  def index
    @users = User.all()
    
    if params[:auth] != nil and params[:auth] != "" and params[:auth] != "all"
        user_auth_fl = (params[:auth] == "true") ? true : false
        @users = @users.all(:auth_fl => user_auth_fl)
    end
    
    if params[:type] != nil and params[:type] != "" and params[:type] != "all"
      @users = @users.all(:type => params[:type])
    end
    
    
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
  
  def auth_user_email
    user_id = (params[:user_id] != nil and params[:user_id] != "") ? params[:user_id].to_i : nil
    begin
      if user_id != nil
        user = User.get(user_id)
        user.auth_fl = user.auth_fl ? false:true
        if user.save
          render :text => "success"
        else
          render :text => "fail"
        end
      else
        render :text => "fail"
      end
    rescue
      render :text => "fail"
    end
  end

  def auth_email_resend
    user_id = (params[:user_id] != nil and params[:user_id] != "") ? params[:user_id].to_i : nil
    begin
      if user_id != nil
        user = User.get(user_id)
        
        if emailing(user_id, user.email, user.auth_code, user.name)
          puts_message "auth email resended!"
          render :text => "success"
        else
          render :text => "fail"
        end
      else
        render :text => "fail"
      end
    rescue
      render :text => "fail"
    end
  end

  def emailing(userid, email, auth_code, user_name)
    begin
      Emailer.deliver_email(
        :recipients => email,
        :subject => "[엠북스토어] #{user_name} 고객님, 앰북스토어 인증메일 입니다.",
        :from => "앰북스토어<mbookserver@gmail.com>",
        :body => "<html><head><body><a href='#{HOSTING_URL}auth.htm?userid=#{userid}&code=#{auth_code}'>여기를 클릭하시면 인증이 완료됩니다!~</a></body></head></html>"
      )
      return true
    
    rescue  
      return false
    end
    
    
  end
  
end
