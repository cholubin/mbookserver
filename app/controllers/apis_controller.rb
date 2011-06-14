# encoding: utf-8
require 'rexml/document'
include REXML

class ApisController < ApplicationController
  before_filter :set_cache_buster
  # result 값 공통 ==========================
  # 0 : OK
  # 3 : User in approval process
  # 4 : Invalid userid
  # 5 : Invalid userpw
  # ~ : Error
  # ======================================

  
  def user_authentication(userid, userpw)
    begin
      @user = User.first(:userid => userid)

      if @user != nil 
        user = User.authenticate(userid,userpw)
        
        if user != nil
          if user.auth_fl == false
            result = 3
          else
            result = 0
          end
        else
          result = 5
        end
        
      else
        result = 4
      end
    rescue
      result = -1
    end
    # result 값
    # 0 : user exist
    return result
  end

  def make_result_xml(result)
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    return result_xml
  end
  
  
  
  def mbookdownchk
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    
    begin
      result = user_authentication(userid, userpw)
      
      if result == 0
        mbook = Mbook.get(mbookid)
        if mbook.nil?
          result = 6
        else
          result = File.exists?(mbook.zipfile) ? 0 : 7
        end
      end
      
    rescue
      result = -1
    end
    
    result_xml = make_result_xml(result)

    # result 값
    # 6 : mBook not exist
    # 7 : mBook zipfile not exist
    render :xml => result_xml
  end
  
  def mbookdown
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    
    begin
      result = user_authentication(userid, userpw)
      
      if result == 0
        mbook = Mbook.get(mbookid)
        if mbook.nil?
          result = 6
        else
          if File.exists?(mbook.zipfile)
            if Userbook.all(:userid => userid, :mbookid => mbookid).count < 1
              userbook = Userbook.new()
              userbook.userid = userid
              userbook.mbookid = mbookid
              result = userbook.save ? 0 : 7
            end
          else
            result = 6
          end
        end
      end
    rescue
      result = -1
    end
    
    result_xml = make_result_xml(result)

    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 6 : mBook not exist    
    # 7 : 사용자 구매리스트 업데이트 오류(구매하고 다운로드 한적이 없는 경우만 인서트)

    if result == 0
      send_file mbook.zipfile, :filename => mbook.id.to_s + ".mbook.zip",  :type => "application/zip"# , :stream => "false", :disposition => 'attachment'
    else
      render :xml => result_xml
    end
    
  end
  
  def mbookdownconfirm
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    
    begin
      result = user_authentication(userid, userpw)

      if result == 0
        mbook = Mbook.get(mbookid)
        
        if mbook.nil?
          result = 6
        else
          dncount = Mbookdncount.new()
          dncount.userid = userid
          dncount.mbookid = mbookid
          if dncount.save
            if Userbook.all(:userid => userid, :mbookid => mbookid).count < 1
              userbook = Userbook.new()
              userbook.userid = userid
              userbook.mbookid = mbookid
              result = userbook.save ? 0 : 7
            end
            result = 0
          else
            result = 7
          end #if dncount.save
        end #if mbook.nil?
      end #if result == o
    rescue
      result = -1
    end
    
    result_xml = make_result_xml(result)

    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 6 : mBook not exist    
    # 7 : 다운로드 카운트 업데이트 에러 
    # ~ : Error
    render :xml => result_xml
  end
  
  def mbookinfo
    begin
      mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
      
      
      if mbookid != ""
        mb = Mbook.get(mbookid) 
      else
        result = -1
      end


      if mbookid != "" and !mb.nil?
        result = 0
        
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<mbookinfo>
<type>book</type>
<id>#{mb.id.to_s}</id>
<thumbnail>mbook/#{mb.id.to_s}/#{mb.thumbnail_name}</thumbnail>
<preview>mbook/#{mb.id}/#{mb.coverimage_name}</preview>
<download>mbook/#{mb.id}.zip</download>
<title>#{mb.title}</title>
<author>#{mb.writer}</author>
<publisher>#{mb.publisher}</publisher>
<pages>#{mb.pages}</pages>
<issue_date>#{mb.issue_date}</issue_date>
<price>#{mb.price}</price>
<description>#{mb.description}</description>
</mbookinfo>
</xml>
EOF
      else
        result = 6
      end
        # result = 0
    rescue
      # puts_message mb.errors.to_s
      result = -1
    end
    
    puts_message result.to_s
    if result != 0
      result_xml = make_result_xml(result)
    end
    
    # result 값
    # 0 : OK
    # 6 : mBook is not exist
    # ~ : Error
    render :xml => result_xml
  end
  
  def register
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid] : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw] : ""
    email   = (params[:email]   != nil and params[:email]   != "") ? params[:email]  : ""
    
    if userid != "" and userpw != "" and email != ""
      if User.first(:userid => userid) != nil
        result = 1
      elsif User.first(:email => email) != nil
        result = 2
      else
        @user = User.new
        @user.userid = userid
        @user.name = userid
        @user.password = userpw
        @user.email = email
        @user.type = "reader"
        
        auth_code = @user.make_authcode
        puts_message "승인 코드==>" + auth_code
        @user.auth_code = auth_code
        
        Emailer.deliver_email(
          :recipients => email,
          :subject => "엠북스토어 인증메일 입니다.",
          :from => "mbookserver@gmail.com",
          :body => "<html><head><body><a href='#{HOSTING_URL}auth.htm?userid=#{userid}&code=#{auth_code}'>여기를 클릭하시면 인증이 완료됩니다!~</a></body></head></html>"
        )
      
        result = @user.save ? 0 : -1
        
      end
    else
      result = -1
    end
    
    result_xml = make_result_xml(result)
    
    # result 값
    #       0 : OK
    #       1 : user id exists already
    #       2 : email exists already
    #       3 : 인증 절차 중인 사용자
    #       ~ : Error
    render :xml => result_xml
  end
  
    
  def reader_login
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid] : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw] : ""
    
    begin
      result = user_authentication(userid, userpw)
      if result == 0
        sign_in User.first(:userid => userid)
      end
      
    rescue
      result = -1
    end
    result_xml = make_result_xml(result)
    render :xml => result_xml
  end

  
  def memberout
    userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid] : ""
    userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw] : ""

    begin
      result = user_authentication(userid, userpw)
      if result == 0
        result = @user.destroy ? 0 : -1
      end
    rescue
      result = -1
    end
    result_xml = make_result_xml(result)
    render :xml => result_xml
  end
  

  def modifymember
    begin
      userid = (params[:userid] != nil and params[:userid] != "") ? params[:userid] : ""
      userpw = (params[:userpw] != nil and params[:userpw] != "") ? params[:userpw] : ""
      newpw  = (params[:newpw]  != nil and params[:newpw]  != "") ? params[:newpw]  : ""

      result = user_authentication(userid, userpw)
      if  result == 0
        if @user.update_password(newpw)
          result = 0
        else
          result = -1
        end
      end

    rescue
      result = -1
    end
  
    result_xml = make_result_xml(result)
    render :xml => result_xml
  end
  
  def notification
    userid = (params[:userid] != nil and params[:userid] != "") ? params[:userid] : ""
    userpw = (params[:userpw] != nil and params[:userpw] != "") ? params[:userpw] : ""
    notice = (userid == "" and userpw == "")? "전체공지" : "개별공지"
    
    begin
      if userid == "" and userpw == ""
        result = (notice == "" or notice.nil?) ? 1 : 0
      else
        result = user_authentication(userid, userpw)
        if result == 0; result = (notice == "" or notice.nil?) ? 1 : 0; end
      end
      
    rescue
      result = -1
    end
    
    if result != 0
      notice = ""
    end
    
    # result 값
    # 1 : 공지 없슴
    
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<message>#{notice}</message>
</xml>
EOF
    
    
    render :xml => result_xml
  end
  
  def userbooklist
    userid = (params[:userid] != nil and params[:userid] != "") ? params[:userid] : ""
    userpw = (params[:userpw] != nil and params[:userpw] != "") ? params[:userpw] : ""
    
    begin
      result = user_authentication(userid, userpw)

      if result == 0
        booklist = Userbook.all(:userid => userid)
        
        userbooklist = ""
        booklist.each do |book|
          userbooklist = userbooklist + book.id.to_s + ","
        end
        if userbooklist[-1] == ","; userbooklist[-1] = ""; end
        
      end
      
    rescue
      result = -1
    end
    # result 값
    # 0 : OK
    # ~ : Error
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<bookidlist>#{userbooklist}</bookidlist>
</xml>
EOF
    render :xml => result_xml
  end
  
  def store
    items = "\n"
    
    begin
      if params[:folder_id] != nil and params[:folder_id] != ""
        #category_id 와 동일 
        category_id = params[:folder_id].to_i
        categories = Category.all(:parent_id => category_id, :gubun => "template")
        
        categories.each do |sub|
          items = items + 
"<item>
<type>folder</type>
<id>#{sub.id.to_s}</id>
<name>#{Category.get(sub.id).name}</name>
<subitems>#{Mbook.all(:subcategory1_id => sub.id).count.to_s}</subitems>
<thumbnail>/images/category_icon/#{sub.icon_image}</thumbnail>
</item>\n"
        end
        
        mbooks = Mbook.all(:subcategory1_id => category_id)
        puts_message mbooks.count.to_s
        mbooks.each do |mb|
          items = items + 
"<item>
<type>book</type>
<id>#{mb.id.to_s}</id>
<thumbnail>mbook/#{mb.id.to_s}/#{mb.covermedium_name}</thumbnail>
<preview>mbook/#{mb.id.to_s}/#{mb.coverimage_name}</preview>
<download>mbook/#{mb.id.to_s}.mbook.zip</download>
<title>#{mb.title}</title>
<author>#{mb.writer}</author>
<publisher>#{mb.publisher}</publisher>
<pages>#{mb.pages}</pages>
<issue_date>#{mb.issue_date}</issue_date>
<price>#{mb.price}</price>
<description>#{mb.description}</description>
<product_identifier></product_identifier>
</item>\n"
        end
        result = "0"
      else
        categories = Category.all(:gubun => "template", :level => 0)
        categories.each do |cat|
          items = items + 
"<item>
<type>folder</type>
<id>#{cat.id.to_s}</id>
<name>#{cat.name}</name>
<subitems>#{Mbook.all(:category_id => cat.id).count.to_s}</subitems>
<thumbnail>/images/category_icon/#{cat.icon_image}</thumbnail>
</item>\n"
        end
      end
    rescue
      result = -1
      items = ""
    end

  # result값 
  # 0 : OK
  # ~ : Error

    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<itemlist>#{items}</itemlist>
</xml>
EOF
    render :xml => result_xml
  end
  
  def authentication
    auth_code = (params[:code] != nil and params[:code] != "") ? params[:code] : ""
    userid = (params[:userid] != nil and params[:userid] != "") ? params[:userid] : ""
    
    begin
      if auth_code != nil and userid != ""
        @user = User.first(:userid => userid)
        if @user.auth_fl == false
          if @user.auth_code == auth_code
            @user.auth_fl = true
            if @user.save
              result = 0
            else
              result = 2
            end
          else
            result = 1
          end
        else
          #이미 인증완료!
          result = 0
        end
      else
        result = -1
      end
    rescue
      result = -1
    end
    
      # result값 
      # 0 : 인증완료 
      # 1 : 인증실패 
      # 2 : 인증정보 업데이트 에러 
      # ~ : Error
      puts_message "인증결과::::" + result.to_s
      if result == 0 
        render :text => "인증성공"
      else
        render :text => "인증실패"
      end  end
end