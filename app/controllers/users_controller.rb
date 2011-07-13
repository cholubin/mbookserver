# encoding: utf-8

class UsersController < ApplicationController
  
  # GET /users
  # GET /users.xml
  def show

    @user = User.get(params[:id])
        
    if signed_in? && @user.id == current_user.id
      @menu = "home"
      @board = "user"
      @section = "show"
    
      render 'user'
    else
      redirect_to '/'
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    @menu = "home"
    @board = "user"
    @section = "new"
    
    render 'user'
    
  end

  def create

    @menu = "home"
    @board = "user"
    @section = "new"
        
    userid = (params[:userid] == "" or params[:userid] == nil) ? nil : params[:userid]
    name = (params[:name] == "" or params[:name] == nil) ? nil : params[:name]
    password = (params[:password] == "" or params[:password] == nil) ? nil : params[:password]
    email = (params[:email] == "" or params[:email] == nil) ? nil : params[:email]
    servicetype = (params[:servicetype] == "" or params[:servicetype] == nil) ? "shared" : params[:servicetype]
    
    if userid != nil and name != nil and password != nil and email != nil

      if not User.first(:userid => userid).nil? # 아이디 중복인 경우 ========================== 
        render 'user'    
      else
        @user = User.new
        @user.userid = userid
        @user.name = name
        @user.password = password
        @user.email = email
        @user.type = "writer"
        @user.servicetype = servicetype
        
        auth_code = @user.make_authcode
        @user.auth_code = auth_code
        
        
        if emailing(userid, email, auth_code) and @user.save
          # render :update do |page|
          #    page.replace_html 'message', :partial => 'user_join_finished', :object => @message
          # end
          render :text => "success"
        else
          render :text => "fail"
        end
        
        # @message = "이메일 주소로 승인번호가 발송되었습니다!<br>메일을 확인하시고 링크를 클릭하시면<br>가입절차가 완료됩니다!"        
        
      end
    
      
    else
      render 'user'    
    end
        
  end
  
  
  def emailing(userid, email, auth_code)
    begin
      Emailer.deliver_email(
        :recipients => email,
        :subject => "[엠북스토어] 고객님, 인증메일 입니다.",
        :from => "mbookserver@gmail.com",
        :body => "<html><head><body><a href='#{HOSTING_URL}auth.htm?userid=#{userid}&code=#{auth_code}'>여기를 클릭하시면 인증이 완료됩니다!~</a></body></head></html>"
      )
      
      return true
    rescue
      return false
    end
    
  end
  # GET /users/1/edit
  def edit
    @user = User.get(params[:id])
        
    if signed_in? && @user.id == current_user.id
      @menu = "home"
      @board = "user"
      @section = "edit"

      render 'user'
    else
      redirect_to '/'
    end
    
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.get(params[:id].to_i)
    
    if signed_in? && @user.id == current_user.id
      @board = "user"
      @section = "edit"
          

      if params[:password] != ""

        @user.update_password(params[:password])
        @user.email = params[:email]
        @user.publisher = params[:publisher]
        
        if @user.save
          @board = "mbook"
          @section = "index"

          redirect_to '/mbooks'
        else
          render 'user'
        end
      else  #메일만 수정하는 경우       
        @user.email = params[:email]
        @user.publisher = params[:publisher]

        if @user.save
          
          @board = "mbook"
          @section = "index"
          
          redirect_to '/mbook'
        else
          render 'user'
        end 
      end
      
      
    else
      redirect_to '/'
    end
      

  end



  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    
    @user = User.get(params[:id])
    
    if signed_in? && current_user.id == @user.id

      user_dir = "#{RAILS_ROOT}" + "/public/user_files/#{current_user.userid}/"
      FileUtils.rm_rf user_dir
      
      begin
        @mycarts = Mycart.all(:user_id => current_user.id)  
        @mycarts.destroy

        @freeboards = Freeboard.all(:user_id => current_user.id)  
        @freeboards.destroy
      
        @mytemplates = Mytemplate.all(:user_id => current_user.id)
        @mytemplates.destroy
      
        @myimages = Myimage.all(:user_id => current_user.id)  
        @myimages.destroy

        @usertempopenlists = Usertempopenlist.all(:user_id => current_user.id)
        @usertempopenlists.destroy
      rescue
        puts_message "사용자 관련 테이블 삭제 진행중 오류 발생!"
      end
      
      if @user.destroy
      else
        puts_message "사용자 테이블 삭제 진행중 오류 발생!"
        puts @user.errors
      end
            
      sign_out

            
      @menu = "home"
      @board = "user"
      @section = "edit"
      
      render 'users/withdrawal_finished'
      # render '/users/withdrawal_finished'  이경우에는 users컨트롤러가 아닌 users폴더내의 템플릿을 참고하게 된다. 즉 기본 레이아웃을 가져오지 않는다.
    else
      redirect_to '/'
    end
  end
  
  
  def id_check

      # 중복아이디 체크 
     @user = User.first(:userid => params[:user_id])
     # puts @user.name

     render :update do |page|
       page.replace_html 'id_check', :partial => 'id_check', :object => @user
     end   

  end

    
    
end
