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
  # -1 : Error
  # ======================================

  
  def user_authentication(userid, userpw)
    begin
      @user = User.first(:userid => userid)
      
      
      if @user != nil 
      
        @user = User.authenticate(userid,userpw)
        
        if @user != nil
          if @user.auth_fl == false
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
    # isfree  = (params[:isfree]  != nil and params[:isfree]  != "") ? params[:isfree]       : ""
    # userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
    # userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    
    # isfree  = (params[:isfree]  != nil and params[:isfree]  != "") ? params[:isfree]       : ""
    # devicetype  = (params[:devicetype]  != nil and params[:devicetype]  != "") ? params[:devicetype]       : ""
    # deviceid  = (params[:deviceid]  != nil and params[:deviceid]  != "") ? params[:deviceid]       : ""
    
    begin
      # result = user_authentication(userid, userpw)
    mbook = Mbook.get(mbookid)
      
    if mbook.nil?
      result = 6
    else
      result = File.exists?(mbook.zipfile) ? 0 : 7
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
    
    # userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
    # userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    admin_down = (params[:admin_down] != nil and params[:admin_down] != "") ? params[:admin_down] : ""
    
    if admin_down == "y" and admin_signed_in?
      result = 0
      mbook = Mbook.get(mbookid) if Mbook.get(mbookid) != nil
    else
      begin
        # result = user_authentication(userid, userpw)

        # if result == 0
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
        # end
      rescue
        result = -1
      end

      result_xml = make_result_xml(result)
    end
    

    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 6 : mBook not exist    
    # 7 : 사용자 구매리스트 업데이트 오류(구매하고 다운로드 한적이 없는 경우만 인서트)
    if admin_down == "y" 
      mbook_filename = mbook.title + "(#{mbook.id.to_s})"
    else
      mbook_filename = mbook.id.to_s
    end
    
    if result == 0
      send_file mbook.zipfile, :filename => mbook_filename  + ".mbook.zip",  :type => "application/zip"# , :stream => "false", :disposition => 'attachment'
    else
      render :xml => result_xml
    end
    
  end
  
  # 무료컨텐츠 다운: 디바이스 정보만 저장
  # 유료컨텐츠 다운: 사용자 정보만 저장 
  def mbookdownconfirm
    
    # 무료다운로드의 경우 사용자 정보는 제외하고 디바이스정보만 저장한다.
    isfree  = (params[:isfree]  != nil and params[:isfree]  != "") ? params[:isfree]       : ""
    mbookid = (params[:mbookid] != nil and params[:mbookid] != "") ? params[:mbookid].to_i : ""
    
    mbook = Mbook.get(mbookid) != nil ? Mbook.get(mbookid) : nil
    
    if mbook == nil
      result = 6
    else
      if isfree == "y"
        #  devicetype : 100 - iPad, 101 - iPhone, 200 - 갤럭시 탭, 201 - 갤럭시 10.9…
        # * 1XX -> iOS Device, 2XX -> Android Device
        devicetype  = (params[:devicetype]  != nil and params[:devicetype]  != "") ? params[:devicetype]       : ""
        deviceid    = (params[:deviceid]    != nil and params[:deviceid]    != "") ? params[:deviceid]         : ""
      
        if devicetype != "" and deviceid != ""
          is_first = download_first_by_device(mbookid, deviceid)
          result = update_dncount_by_device(is_first, mbook, devicetype, deviceid)
        else
          result = 8
        end
      else
        userid  = (params[:userid]  != nil and params[:userid]  != "") ? params[:userid]       : ""
        userpw  = (params[:userpw]  != nil and params[:userpw]  != "") ? params[:userpw]       : ""
      
        result = user_authentication(userid, userpw)
      
        if result == 0
          is_first = download_first_by_user(mbookid, userid)
          result = update_dncount_by_user(is_first, mbook, userid)
        end
      end
    end
  
    result_xml = make_result_xml(result) 

    # result 값
    # 0 : OK  // 파일을 보내는 경우에는 xml을 보낼 수 없다. 렌더링을 동시에 두종류 할 수 없다. 
    # 6 : mBook not exist    
    # 71: 다운로드 카운트 업데이트 에러 
    # 72: MPoint 업데이트 에러 
    # 73: Userbooklist(사용자 구매목록) 업데이트 에러 
    # 8 : Device 정보 없슴 (device type, device id)
    # ~ : Error
    render :xml => result_xml
  end
  
  def download_first_by_user(mbookid, userid)
    if Mbookdncount.all(:mbookid => mbookid, :dn_user_id => userid).count > 0
      return false
    else
      return true
    end
  end  
  
  def download_first_by_device(mbookid, deviceid)
    if Mbookdncount.all(:mbookid => mbookid, :deviceid => deviceid).count > 0
      return false
    else
      return true
    end
  end
  
    
  def update_dncount_by_user(is_first, mbook, userid)  
    if is_first
      dncount = Mbookdncount.new(:mbookid => mbook.id, :dn_user_id => userid, :userid => mbook.user_id)
      dncount.mbook_title = mbook.title
      dncount.mbook_price = mbook.price
      dncount.free_or_not_fl = false
      dncount.down_cnt = 1
      
      if dncount.save
        #최초의 다운로드인 경우 MPoint를 차감한다.
        mpoint_update_result = mpoint_update(mbook, dncount.id)
        if mpoint_update_result != 72 
          if userbook_update(mbook, userid) == 0
            return 0
          else
            puts_message "here"
            dncount.destroy
            Mpoint.get(mpoint_update_result).destroy
            return 73
          end
        else
          dncount.destroy
          return 72
        end
      else
        return 71
      end
      
    else
      dncount = Mbookdncount.first(:mbookid => mbook.id, :dn_user_id => userid)
      dncount.down_cnt += 1
      if dncount.save
        return 0
      else
        return 71
      end
    end
    
  end
  
  def update_dncount_by_device(is_first, mbook, devicetype, deviceid)  
    if is_first
      dncount = Mbookdncount.new(:mbookid => mbook.id, :userid => mbook.user_id, :deviceid => deviceid)
      dncount.mbook_title = mbook.title
      dncount.mbook_price = mbook.price
      dncount.free_or_not_fl = true
      dncount.down_cnt = 1
      dncount.devicetype_main = devicetype[0]
      dncount.devicetype_sub = devicetype
      dncount.deviceid = deviceid
      
      if dncount.save
        #최초의 다운로드인 경우 MPoint를 차감한다.
        if mpoint_update(mbook, dncount.id) != 72
          return 0
        else
          dncount.destroy
          return 72
        end
      else
        return 71
      end
      
    else
      dncount = Mbookdncount.first(:mbookid => mbook.id, :deviceid => deviceid)
      dncount.down_cnt += 1
      if dncount.save
        return 0
      else
        return 71
      end
    end
  end
  
  def mpoint_update(mbook, dncount_id)
    begin
      mpoint = Mpoint.new(:user_id => mbook.user_id, :mbook_id => mbook.id, :mbookdncount_id => dncount_id)
    
      mpoint.account = "M01" #MBook 다운로드 계정
    
      #관리자가 특정사용자에 대해서 무제한 다운로드 옵션을 허용한 경우 다운로드시 발생하는 포이트 차감이 없음.
      if mbook.unlimited_down_fl == true
        mpoint.point = 0
        mpoint.info = "무제한 다운로드로 포인트차감 0"
      else
        mpoint.point = MDOWN_POINT
        mpoint.info = "MBook 다운로드"
      end
    
      if mpoint.save
        return mpoint.id
      else
        puts_message mpoint.errors.to_s
        return 72
      end    
    rescue
      return 72
    end
  end
  
  def userbook_update(mbook, userid)
    begin
      userbook = Userbook.new(:userid => userid, :mbookid => mbook.id, :mbook_price => mbook.price)
      if userbook.save
        return 0
      else
        return 73
      end
    rescue
      return 73
    end
  end
  
    # begin
    #   mbook = Mbook.get(mbookid) != nil ? Mbook.get(mbookid) : nil
    #   
    #   if mbook == nil
    #     result = 6
    #   else
    # 
    #     # 무료 다운로드
    #     if isfree == "y"
    #       if Mbookdncount.all(:deviceid => deviceid, :mbookid => mbook.id).count < 1 
    #         dncount = Mbookdncount.new()
    #         # 공통 ==================================
    #         dncount.mbookid     = mbook.id
    #         dncount.mbook_title = mbook.title
    #         dncount.mbook_price = mbook.price
    #         #======================================
    #         
    #         dncount.free_or_not_fl = true
    #         dncount.down_cnt = 1
    #         dncount.devicetype_main = devicetype[0]
    #         dncount.devicetype_sub = devicetype
    #         dncount.deviceid = deviceid
    # 
    #         if dncount.save
    #           @dncount_id = dncount_up.id
    #           result = 0
    #         else
    #           result = -1
    #         end
    #       else
    #         dncount_up = Mbookdncount.first(:deviceid => deviceid, :mbookid => mbook.id)
    #         dncount_up.down_cnt += 1
    #         if dncount_up.save
    #           @dncount_id = dncount_up.id
    #           result = 0
    #         else
    #           result = -1
    #         end
    #       end
    # 
    #     # 유료 다운로드 isfree == "n"
    #     else 
    #       result = user_authentication(userid, userpw)
    # 
    #       if result == 0
    #         
    #         if Mbookdncount.all(:dn_user_id => userid, :mbookid => mbook.id).count < 1 
    #           dncount.dn_user_id = userid
    #           dncount.down_cnt = 1
    #           dncount.free_or_not_fl = false
    #           if dncount.save
    #             result = 0
    #             @dncount_id = dncount.id
    #           else
    #             result = -1
    #           end
    #         else
    #           dncount_up = Mbookdncount.first(:dn_user_id => userid, :mbookid => mbook.id)
    #           dncount_up.down_cnt += 1
    #           if dncount_up.save
    #             result = 0
    #             @dncount_id = dncount.id
    #           else
    #             result = -1
    #           end
    #         end
    #         
    #         
    #         #유료다운로드의 경우만 userbook에 저장한다.
    #         if Userbook.all(:userid => userid, :mbookid => mbookid).count < 1
    #         
    #           userbook = Userbook.new()
    #           userbook.userid = userid
    #           userbook.mbookid = mbookid
    #           userbook.mbook_price = mbook.price
    #           result = userbook.save ? 0 : 7
    #         end
    # 
    #       end #if result == o
    #     end  #if isfree = "y"
    #   end # if mbook != nil
    #   
    #   
    #   mpoint = Mpoint.new()
    #   
    #   mpoint.user_id = mbook.user_id
    # 
    #   if @dncount_id != nil
    #     mpoint.mbookdncount_id = @dncount_id
    #   end
    #   
    #   mpoint.account = "M01" #MBook 다운로드 계정
    #   
    #   
    #   #관리자가 특정사용자에 대해서 무제한 다운로드 옵션을 허용한 경우 다운로드시 발생하는 포이트 차감이 없음.
    #   if mbook.unlimited_down_fl == true
    #     mpoint.point = 0
    #     mpoint.info = "무제한 다운로드로 포인트차감 0"
    #   else
    #     mpoint.point = MDOWN_POINT
    #     mpoint.info = "MBook 다운로드"
    #   end
    #   
    #   if mpoint.save
    #     result = 0
    #   else
    #     puts_message mpoint.errors.to_s
    #     result = -1
    #   end
    #   
    # rescue
    #   result = -1
    # end
    
    
  
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
          userbooklist +=  book.mbookid.to_s + ","
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



    def userbookitems
      userid = (params[:userid] != nil and params[:userid] != "") ? params[:userid] : ""
      userpw = (params[:userpw] != nil and params[:userpw] != "") ? params[:userpw] : ""
      
      begin
        result = user_authentication(userid, userpw)
        
        
        if result == 0
          booklist = Userbook.all(:userid => userid)
          
          if booklist.count > 0
          
            items = ""
            booklist.each do |ub|
              mb = Mbook.get(ub.mbookid)
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
        end
          result = 0
        end

      rescue
        result = -1
      end
      # result 값
      #       0 : OK 
      # 3 : User in approval process
      # 4 : Invalid userid
      # 5 : Invalid userpw  
      # -1 : Error

    result_xml = <<-EOF
<?xml version="1.0" encoding="UTF-8"?>
<xml>
<result>#{result}</result>
<itemlist>#{items}</itemlist>
</xml>
EOF
      render :xml => result_xml
    end
      
      
      
      
  def store
    items = "\n"
    
    #  :limit => 1, :offset => 2 (3번째부터 3개)
    begin
      if params[:start] != nil and params[:start] != ""
        offset = params[:start].to_i
      else
        offset = 0
      end
      
      if params[:count] != nil and params[:count] != ""
        limit = params[:count].to_i
      else
        limit = 0
      end
      
      if params[:folder_id] != nil and params[:folder_id] != ""
        #category_id 와 동일 
        category_id = params[:folder_id].to_i
        
        categories = Category.all(:parent_id => category_id, :gubun => "template")
        
        
        categories.each do |sub|
          category_count = Category.all(:parent_id => sub.id).count.to_s
          if limit > 0
            mbook_count = Mbook.all(:status => "승인완료", :subcategory1_id => sub.id, :limit => limit, :offset => offset).count.to_s
          else
            mbook_count = Mbook.all(:status => "승인완료",:subcategory1_id => sub.id, :offset => offset).count.to_s
          end
          items = items + 
"<item>
<type>folder</type>
<id>#{sub.id.to_s}</id>
<name>#{Category.get(sub.id).name}</name>
<subitems>#{category_count}</subitems>
<books>#{mbook_count}</books>
<thumbnail>/images/category_icon/#{sub.icon_image}</thumbnail>
</item>\n"
        end
        
        if limit > 0
          mbooks = Mbook.all(:status => "승인완료",:subcategory1_id => category_id, :limit => limit, :offset => offset)
        else
          mbooks = Mbook.all(:status => "승인완료",:subcategory1_id => category_id, :offset => offset)
        end
        
        # puts_message mbooks.count.to_s
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
          subcat_count = Category.all(:parent_id => cat.id).count.to_s
          mbooks_count = Mbook.all(:status => "승인완료",:subcategory1_id => cat.id).count.to_s
          items = items + 
"<item>
<type>folder</type>
<id>#{cat.id.to_s}</id>
<name>#{cat.name}</name>
<subitems>#{subcat_count}</subitems>
<books>#{mbooks_count}</books>
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