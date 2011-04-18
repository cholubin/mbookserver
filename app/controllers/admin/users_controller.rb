# encoding: utf-8

class Admin::UsersController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!      
  # GET /users
  # GET /users.xml
  def index
    @users = User.search_admin(params[:keyword], params[:search], params[:page])
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


  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    
    @user = User.get(params[:id])
    

      user_dir = "#{RAILS_ROOT}" + "/public/user_files/#{current_user.userid}/"
      FileUtils.rm_rf user_dir
      
      @mycarts = Mycart.all(:user_id => @user.id)  
      @mycarts.destroy

      @freeboards = Freeboard.all(:user_id => @user.id)  
      @freeboards.destroy

      @myimages = Myimage.all(:user_id => @user.id)  
      @myimages.destroy

      if @user.destroy
        redirect_to(admin_users_url)        
      else
        puts "에러 발생 =========================================="
        puts @user.errors
        redirect_to(admin_users_url)                
      end
          

  end
  
  
  # multiple deletion
  def deleteSelection 

    chk = params[:chk]

    if !chk.nil? 
      chk.each do |chk|
        @user = User.get(chk[0].to_i)
        
        begin
          user_dir = "#{RAILS_ROOT}" + "/public/user_files/#{@user.userid}/"
          FileUtils.rm_rf user_dir

          @mycarts = Mycart.all(:user_id => @user.id)  
          @mycarts.destroy

          @freeboards = Freeboard.all(:user_id => @user.id)  
          @freeboards.destroy

          @myimages = Myimage.all(:user_id => @user.id)  
          @myimages.destroy
        
          @mytemplates = Mytemplate.all(:user_id => @user.id)  
          @mytemplates.destroy
          
          @folders = Folder.all(:user_id => @user.id)  
          @folders.destroy

          @mybookfolders = Mybookfolder.all(:user_id => @user.id)  
          @mybookfolders.destroy

          @mybookpdfs = Mybookpdf.all(:user_id => @user.id)  
          @mybookpdfs.destroy

          @mybooks = Mybook.all(:user_id => @user.id)  
          @mybooks.destroy

          @mypdfs = Mypdf.all(:user_id => @user.id)  
          @mypdfs.destroy

          @usertempopenlists = Usertempopenlist.all(:user_id => User.get(@user.id).userid)
          @usertempopenlists.destroy
          
          if @user.destroy   
            flash[:notice] = "정상적으로 사용자 삭제됨!"
          else
            flash[:notice] = "사용자 삭제진행중 오류 발생!"            
          end
          
        rescue
          flash[:notice] = '사용자 관련 테이블 삭제 진행중 오류가 발생했습니다!'              
        end 
      end
    else
        flash[:notice] = '삭제할 사용자를 선택하지 않으셨습니다!'    
    end
      
    redirect_to(admin_users_url)  
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
