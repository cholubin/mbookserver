# encoding: utf-8
require 'rexml/document'
include REXML

class ApisController < ApplicationController
  
  def user_authentication(userid, userpw)
    begin
      @user = User.first(:userid => userid)

      if @user != nil 
        user = User.authenticate(userid,userpw)
        if user.nil? 
          result = 5
        else
          result = 0
        end
      else
        result = 4
      end
    rescue
      result = "~"
    end
    # result 값
    # 0 : user exist
    # 3 : User in approval process
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # ~ : Error
    return result
  end
  
  def mbookdownchk
    userid = params[:userid]
    userpw = params[:userpw]
    mbookid = params[:mbookid].to_i
    begin
      result = user_authentication(userid, userpw)
      
      if result == 0
        mbook = Mbook.get(mbookid)
        if mbook.nil?
          result = 6
        else
          if File.exists?(mbook.zipfile)
            result = 0  
          else
            result = 6
          end
        end
      end
      
    rescue
      result = "~"
    end
    # result 값
    # 0 : OK
    # 3 : User in approval process
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # 6 : mBook not exist
    # ~ : Error
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    render :xml => result_xml
  end
  
  def mbookdown
    userid = params[:userid]
    userpw = params[:userpw]
    mbookid = params[:mbookid].to_i
    
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
              if userbook.save
                result = 0
              else
                result = 7
              end
            end
          else
            result = 6
          end
        end
      end
    rescue
      result = "~"
    end
    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 3 : User in approval process
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # 6 : mBook not exist    
    # 7 : 사용자 구매리스트 업데이트 (구매하고 다운로드 한적이 없는 경우만 인서트)
    # ~ : Error
    
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    if result == 0
      send_file mbook.zipfile, :filename => mbook.id.to_s + ".mbook.zip",  :type => "application/zip", :stream => "false", :disposition => 'attachment'
    else
      render :xml => result_xml
    end
    
  end
  
  def mbookdownconfirm
    userid = params[:userid]
    userpw = params[:userpw]
    mbookid = params[:mbookid].to_i
    
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
              if userbook.save
                result = 0
              else
                result = 7
              end
            end
            result = 0
          else
            result = 7
          end #if dncount.save
        end #if mbook.nil?
      end #if result == o
    rescue
      result = "~"
    end
    
    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 3 : User in approval process
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # 6 : mBook not exist    
    # 7 : 다운로드 카운트 업데이트 에러 
    # ~ : Error
    
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    render :xml => result_xml
  end
  
  def mbookinfo
    begin
      mbookid = params[:mbookid].to_i
      mb = Mbook.get(mbookid)
      
      if !mb.nil?
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
        result = 0
    rescue
      puts mb.errors.to_s
      result = "~"
    end
    
    # result 값
    # 0 : OK
    # 6 : mBook is not exist
    # ~ : Error
    if result != 0
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<mbookinfo></mbookinfo>
</xml>
EOF
    end

    render :xml => result_xml
  end
  
  def register
    userid = params[:userid]
    userpw = params[:userpw]
    email = params[:email]
    
    
    if User.all(:userid => userid).count > 0
      result = 1
    elsif User.all(:email => email).count > 0
      result = 2
    else
      @user = User.new
      @user.userid = userid
      @user.name = userid
      @user.password = userpw
      @user.email = email
      @user.type = "reader"

      if @user.save
        result = 0
      else
        result = "~"
      end
    end
    # result 값
    #       0 : OK
    #       1 : user id exists already
    #       2 : email exists already
    #       3 : 인증 절차 중인 사용자
    #       ~ : Error
    
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    render :xml => result_xml
  end
  
    
  def reader_login
    userid = params[:userid]
    userpw = params[:userpw]
    begin
      result = user_authentication(userid, userpw)
      if result == 0
        sign_in user
      end
      
    rescue
      result = "~"
    end
    # result 값
    # 0 : OK
    # 3 : 인증 절차 중인 사용자
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # ~ : Error
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    render :xml => result_xml
  end
  
  def memberout
    userid = params[:userid]
    userpw = params[:userpw]

    begin
      result = user_authentication(userid, userpw)
      if result == 0
        if @user.destroy
          result = 0
        else
          result = "~"
        end
      end
      
    rescue
      result = "~"
    end
    # result 값
    # 0 : OK
    # 3 : 인증 절차 중인 사용자
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # ~ : Error
    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF
    render :xml => result_xml
  end
  
  def modifymember
    begin
      userid = params[:userid]
      userpw = params[:userpw]
      newpw  = params[:newpw]
    
      result = user_authentication(userid, userpw)
      if result == 0
        if @user.update_password(newpw)
          result = 0
        else
          result = "~"
        end
      end
    
    rescue
      result = "~"
    end
      
      # result 값
      #      0 : OK
      #      3 : 인증 절차 중인 사용자
      #      4 : Invalid userid
      #      5 : Invalid userpw
      #      ~ : Error
  result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
</xml>
EOF

      render :xml => result_xml
        
  end
  
  # 개별공지 
  def notification
    if params[:userid] != nil and params[:userid] != ""
      userid = params[:userid]
    else
      userid = ""
    end
    
    if params[:userpw] != nil and params[:userpw] != ""
      userpw = params[:userpw]
    else
      userpw = ""
    end
    
    if userid == "" and userpw == ""
      notice = "전체공지입니다!"
    else
      notice = "개별공지입니다!"
    end
    
    
    begin
      if userid == "" and userpw == ""
        if notice == "" or notice.nil?
          result = 1
        else
          result = 0
        end
      else
        result = user_authentication(userid, userpw)

        if result == 0
          if notice == "" or notice.nil?
            result = 1
          else
            result = 0
          end
        end
      end
      
    rescue
      result = "~"
    end
    
    if result != 0
      notice = ""
    end
    
    # result 값
    # 0 : OK
    # 1 : 공지 없슴
    # 3 : 인증 절차 중인 사용자
    # 4 : Invalid userid
    # 5 : Invalid userpw
    # ~ : Error
    
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
    userid = params[:userid]
    userpw = params[:userpw]
    
    begin
      result = user_authentication(userid, userpw)

      if result == 0
        booklist = Userbook.all(:userid => userid)
        
        userbooklist = ""
        booklist.each do |book|
          userbooklist = userbooklist + book.id.to_s + ","
        end
      end
      
    rescue
      result = "~"
    end
    # result 값
    # 0 : OK
    # 3 : User in approval process
    # 4 : Invalid userid
    # 5 : Invalid userpw
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
    
    begin
  
      if params[:folder_id] != nil and params[:folder_id] != ""
        #category_id 와 동일 
        category_id = params[:folder_id].to_i

        mbooks = Mbook.all(:category_id => category_id)

        items = ""
        mbooks.each do |mb|
          items = items + "<item>
          <type>folder</type>
          <id>#{category_id.to_s}</id>
          <name>#{Category.get(category_id).name}</name>
          <subitems>#{mbooks.count.to_s}</subitems>
          <thumbnail>/images/icon_category.png</thumbnail>
          </item>"
        end
        result = "0"
      else
        result = "~"
      end
    rescue
      result = "~"
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
  
  
end