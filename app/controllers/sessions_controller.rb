# encoding: utf-8

class SessionsController < ApplicationController
  # 

  def new
    @menu = "home"
    @board = "session"
    @section = "new"
    
    if signed_in?
      redirect_to '/'
    else    
      render 'session'
    end
  end

  # POST /sessions
  # POST /sessions.xml
  def create
    
    @menu = "board"
    @board = "session"
    @section = "new"

    @uri = params[:session][:uri]
    
    if params[:session][:userid] == "" or params[:session][:password] == ""
      flash.now[:error] = "아이디와 비밀번호를 모두 입력해 주세요!"        
      render 'session'    
    else
      
      @user = User.first(:userid => params[:session][:userid])

      if @user != nil and @user.auth_fl == false
        flash.now[:error] = "아직 이메일 인증을 하지 않은 아이디 입니다."
        @input_user_id = params[:session][:userid] 
        render 'session', :object => @input_user_id
      else
        if @user != nil 
          user = User.authenticate(params[:session][:userid], 
                               params[:session][:password])

          if user.nil? 
            flash.now[:error] = "아이디와 비밀번호가 일치하지 않습니다!"
            @input_user_id = params[:session][:userid] 
            render 'session', :object => @input_user_id

          else

            sign_in user
            
            if params[:session][:uri] != ""      
              if params[:session][:uri] == "/users"
                redirect_to '/'
              else
                if params[:session][:uri] == "/mbooks"
                  url = "/mbooks?me=y&store=n"
                else
                  url = CGI::escape(params[:session][:uri]).gsub(/%2F/,'/').gsub(/%3F/,'?').gsub(/%3D/,'=')
                end
                redirect_to url
              end
            else
              if current_user.type == "writer"
                redirect_to "/mbooks?me=y&store=n"
              else
                redirect_to '/'
              end
              
            end
          end

        else
          flash.now[:error] = "존재하지 않는 회원아이디 입니다!"
          @input_user_id = params[:session][:userid] 
          render 'session', :object => @input_user_id
        end
      end
      
    end
    
  end

  def destroy
    sign_out
    redirect_to '/'
  end
  
  def check_login_id
    userid = params[:id]
    
    if User.first(:userid => userid) != nil
      render :text => "success"
    else
      render :text => "fail"
    end
  end
end
