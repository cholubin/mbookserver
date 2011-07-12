# encoding: utf-8
require 'rexml/document'
include REXML
class MbooksController < ApplicationController
  skip_before_filter :verify_authenticity_token
  # before_filter :authenticate_user!

  def index
    @menu = "mbook"
    @board = "mbook"
    @section = "index"
    
    @mbooks = Mbook.all(:id => 00)
    
    if params[:sid] != nil and params[:sid] != ""
      @c_sid = params[:sid].to_i
    else
      @c_sid = 0
    end
    
    if @c_sid != 0 
      if Category.get(@c_sid) != nil
        @c_pid = Category.get(@c_sid).parent_id
      else
        @c_pid = 0
      end
    else
      @c_pid = 0
    end
    
    if params[:lv] != nil and params[:lv] != ""
      @level = params[:lv].to_i
    else
      @level = 0
    end


    @pid = []
    @pid_temp = []
    @sid = []
    @sid_temp = []
    
    if @level == 0
        @pid_temp << @c_pid
        @pid_temp << @c_sid
        
        @sid_temp << @c_sid
        @sid_temp << 0
    else
      pid = 0
      sid = 0
      @pid_temp << @c_sid
      @sid_temp << 0
      
      (@level).downto(0) { |x|
        if @level == x
          @pid_temp << @c_pid
          pid = Category.get(@c_pid).parent_id if Category.get(@c_pid) != nil

          @sid_temp << @c_sid
          sid = Category.get(@c_sid).parent_id if Category.get(@c_sid) != nil
          
        else
          if x == 0
            @pid_temp <<  0
            
            @sid_temp << sid
          else
            @pid_temp << pid
            pid = Category.get(pid).parent_id if Category.get(pid) != nil
            
            @sid_temp << sid
            sid = Category.get(sid).parent_id
          end
          
        end
      }
    end
    
    if @level < 1
      @pid = @pid_temp
    else
      i = @pid_temp.length() -1
      # puts_message "pid 갯수"+i.to_s
      @pid_temp.each do |x|
        @pid[i] = x
        i = i -1
      end
    end
    
    if @level < 1
      @sid = @sid_temp
    else
      i = @sid_temp.length() -1
      # puts_message "sid 갯수"+i.to_s
      @sid_temp.each do |x|
        @sid[i] = x
        i = i -1
      end
      
    end
    
    # @pid.each do |x|
    #   puts_message "pid::" + x.to_s
    # end
    # 
    # @sid.each do |x|
    #   puts_message "sid::" + x.to_s
    # end
    
    
    
    # 로그인 한 경우 
    if signed_in?
       @mbooks = get_mbooks(@mbooks, @c_sid)
       
      if (params[:me] == nil or params[:me] == "") and (params[:store] == nil or params[:store] == "")
        params[:me] = "n"
        params[:store] = "y"
      end
      # 내가 올린 mbook중 스토어에 등록된 책 
      if params[:me] == "y" and params[:store] == "y"
        @mbooks = @mbooks.all(:user_id => current_user.id, :status => "승인완료") + Mbook.all(:user_id => current_user.id, :status => "삭제대기")
        
        # puts_message @mbooks.count.to_s
        @menu_on = "my_mb_store"
        @menu_class = "sub_my_mbook_in_store"
        
      # 내가 올린 모든 책 
      elsif params[:me] == "y" and params[:store] == "n"
        @mbooks = @mbooks.all(:user_id => current_user.id)
        @menu_on = "my_mb"
        @menu_class = "sub_my_mbook"
      # 스토어에 등록된 모든 책 
      elsif params[:me] == "n" and params[:store] == "y"
        @mbooks = @mbooks.all(:status => "승인완료")
        @menu_on = "mb_store"
        @menu_class = "sub_mbook_in_store_writer"
      end
      
      if params[:st] != nil and params[:st] != ""
        strStatus = params[:st]
        @mbooks = @mbooks.all(:status => strStatus)
      end
    
      
     
            
      mbooks = @mbooks
      
      @total_count = @mbooks.search(mbooks, params[:keyword], params[:search],"").count
      @mbooks = @mbooks.search(mbooks, params[:keyword], params[:search], params[:page])
      
    # 로그인 하지 않은 경우 (스토어에 등록된 책만 보여준다.)
    else
      
      @menu_on = "mb_store"
      
      @mbooks = get_mbooks(@mbooks, @c_sid)
      @mbooks = @mbooks.all(:status => "승인완료")  
      mbooks = @mbooks
      @total_count = @mbooks.search(mbooks, params[:keyword], params[:search],"").count
      @mbooks = @mbooks.search(mbooks, params[:keyword], params[:search], params[:page])
      
    end

    
    @categories = Category.all(:gubun => "template", :order => :priority, :display_fl => true, :level => 0)
    
    if params[:level] !=nil and  params[:level] != ""
      level = params[:level].to_i
    else
      level = 0
    end
    
    @categories = @categories.all(:level => level, :display_fl => true, :level => 0)
    
    if params[:parent_id] != nil and params[:parent_id]
      parent_id = params[:parent_id].to_i
      
      @categories = @categories.all(:parent_id => parent_id, :display_fl => true, :level => 0)
    end
      
    render 'mbook', :object => @total_count
  end

  def get_mbooks(mbooks, current_id)
    @mbooks = mbooks
    
    # puts_message "id: "+ current_id.to_s + " // " + Mbook.all(:subcategory1_id => current_id).count.to_s
    @mbooks = @mbooks + ( Mbook.all(:subcategory1_id => current_id) || Mbook.all(:subcategory2_id => current_id) )
    # puts_message @mbooks.count.to_s
    if Category.all(:parent_id => current_id).count > 0
      Category.all(:parent_id => current_id).each do |cat|
        @mbooks = get_mbooks(@mbooks, cat.id)
      end
      
      return @mbooks
    else
      return @mbooks
    end
  end
  
  def booklist
    @board = "mbook"
    @section = "booklist"
    
    @mbooks = Mbook.all(:order => [:created_at.asc])
    
    render 'mbook', :layout => "no_layout"
  end

  # GET /mbooks/1
  # GET /mbooks/1.xml
  def show
    @mbook = Mbook.get(params[:id].to_i)
    
    if @mbook.file_size == nil
      file_size = round_to(File.size(@mbook.zipfile) / (1000.0 * 1000.0), 1)
      @mbook.file_size = file_size
      @mbook.save
    end
    
    if @mbook != nil
      @menu = "mbook"
      @board = "mbook"
      @section = "show"
    
      if params[:me] == "y" and params[:store] == "y"
        @menu_on = "my_mb_store"
      # 내가 올린 모든 책 
      elsif params[:me] == "y" and params[:store] == "n"
        @menu_on = "my_mb"
      # 스토어에 등록된 모든 책 
      elsif params[:me] == "n" and params[:store] == "y"
        @menu_on = "mb_store"
      end

      category_id = @mbook.category_id
      @categories = Category.all(:gubun => "template", :order => :priority, :display_fl => true, :level => 0)        
      # @subcategories = Subcategory.all(:category_id => category_id, :order => [:priority])
      render 'mbook'
    else
      redirect_to '/mbooks' 
    end
    
    
    
    
  end

  # GET /mbooks/new
  # GET /mbooks/new.xml
  def new
    if signed_in?
      @menu = "mbook"
      @board = "mbook"
      @section = "new"
      
      @menu_on = "mb_reg"
      
      @mbook = Mbook.new()
      
      @categories = Category.all(:gubun => "template", :order => :priority, :display_fl => true, :level => 0)    
      category_id = Category.first(:gubun => "template", :order => [:priority]).id
      @subcategories = Category.all(:parent_id => category_id, :order => [:priority], :display_fl => true)    
      
      render 'mbook'
    else
      redirect_to '/login'
    end
  end

  # GET /mbooks/1/edit
  def edit
    @mbook = Mbook.find(params[:id])
  end

  # POST /mbooks
  # POST /mbooks.xml
  def create
    puts_message "Create Mbook process has start!"
    
    @mbook = Mbook.new()
    # @mbook.category_id = params[:category_id]
    @mbook.subcategory1_id = params[:sub1]
    if params[:sub2] != nil and params[:sub2] != ""
      @mbook.subcategory2_id = params[:sub2]
    else
      @mbook.subcategory2_id = nil
    end
    @mbook.issue_date = params[:issue_date]

    @mbook.price_android = "0"
    @mbook.price = "0"
    
    @mbook.user_id = current_user.id
    @mbook.userid = current_user.userid
    
    @mbook.mbook_file = params[:mbook_file]
    @mbook.original_filename = params[:mbook_file].original_filename.gsub(".zip","")
    
    
    # mbook_upload(params[:mbook_file])
    if @mbook.save
      
      puts_message "unzip_uploaded_file start!"
      unzip_uploaded_file(@mbook)
      
      puts_message "get_xml_data_update start!"
      get_xml_data_update(@mbook)
      redirect_to '/mbooks?me=y&store=n'
    else
      puts_message "실패! " + @mbook.errors.to_s
      redirect_to '/mbooks'
    end
  end

  # def mbook_upload(file)
  #   uploader = MbookUploader.new
  #   uploader.store!(file)
  # end
  
  def unzip_uploaded_file(mbook) 
    puts_message "unzip_uploaded_file in progress"
    
    destination = mbook.zip_path

    begin
     FileUtils.mkdir_p destination if not File.exist?(destination)
     FileUtils.chmod 0777, destination
    rescue
      puts_message "mbook folder creation was failed!"
    end

    loop do 
      break if File.exists?(mbook.zipfile)
    end

     file_size = round_to(File.size(mbook.zipfile) / (1000.0 * 1000.0), 1)
     mbook.file_size = file_size
     
     unzip(mbook, destination)    
     get_xml_data_update(mbook)
     
     puts_message "unzip_uploaded_file finished"
  end
  
   def rezip_uploaded_file(mbook)
     path = mbook.zip_path
     zip_name = mbook.id.to_s + ".zip"
     
     # puts_message path
     # puts_message zip_name
     
     # system "zip #{MBOOK_PATH+zip_name} #{mbook.id.to_s}/*.*"
     
     system "cd #{MBOOK_PATH}; pwd; zip -r #{zip_name} #{mbook.id.to_s}/*.*" 
   end
   
   def get_xml_data_update(mbook)
     doc = Document.new(File.new(mbook.zip_path + "/BookInfo.xml"))

     doc.elements.each("xml") do |mb|
       mbook.title = mb.elements["BookTitle"].text
       mbook.writer = mb.elements["Author"].text
       mbook.pages = mb.elements["NumberOfPages"].text
       # mbook.publisher = mb.elements["Publisher"].text
       mbook.coverimage_name = mb.elements["CoverImage"].text
       mbook.thumbnail_name = mb.elements["CoverThumbnail"].text
       if mb.elements["CoverMedium"] != nil and mb.elements["CoverMedium"] != ""
         mbook.covermedium_name = mb.elements["CoverMedium"].text
       else
         mbook.covermedium_name = mbook.thumbnail_name
       end
       mbook.description = mb.elements["Description"].text if mb.elements["Description"] != nil
       if mbook.save
         puts_message "mBook 메타데이타 업데이트 완료!"
       else
         puts_message "mBook 메타데이타 업데이트 실패!"
       end
     end 
   end

   def unzip(mbook, destination)  
        file = mbook.zipfile
        file_names = ["BookInfo.xml", "medium.jpg", "thumb.jpg", "cover.jpg"]
        
        Zip::ZipFile.open(file) { |zip_file|
          i = 0
          zip_file.each{ |f| 
            f_path = File.join(destination, f.name)
            temp = f.name
            if i == 0
              temp = temp.split("\/") 
              @folder_name = temp[0]
            end
            
            # puts_message "@folder_name::" + @folder_name
            
            # puts_message f.name
            file_names.each do |file|
              puts_message f.name
              if f.name.match(file)
                make_path( f_path.sub(file,"") )
                zip_file.extract(f, f_path) unless File.exist?(f_path)
              elsif f.name.match(@folder_name + "thumb.jpg")
                zip_file.extract(f, f_path) unless File.exist?(f_path)
              end
              i += 1
            end
          }
        }
        
        FileUtils.rm_rf (destination + "/__MACOSX")
        
        
        @dir_names = Dir.entries(mbook.zip_path)
        puts_message "디렉토리 갯수: " + @dir_names.length.to_s
        
        if @dir_names.length == 3
          @folder_name = @folder_name.sub("/","")
          
          puts_message "폴더이름:::: ==> " + mbook.zip_path.force_encoding("UTF-8") + "/" + @folder_name.force_encoding("UTF-8")
          
          mv_source = mbook.zip_path + '/' + "\"" + @folder_name + "\""
          mv_dest = (mbook.zip_path + '/' + @folder_name).gsub(@folder_name, "")
          
          system("cd #{mv_source}; mv *.* #{mv_dest}")
          FileUtils.rm_rf (mbook.zip_path + "/" + @folder_name)
        end 
        
        # tree = REXML::Document.new mbook.zip_path + "/BookInfo.xml"
        # 
        # tree.elements.each("Sections/Section") do |person|
        #   puts person.get_elements("SectionTitle").first
        # end
   end

  def make_path(destination)
    FileUtils.mkdir_p destination if not File.exist?(destination)
    FileUtils.chmod 0777, destination
  end
   
   def unzip_old(mbook, destination)  
        file = mbook.zipfile
        original_filename = (mbook.original_filename).force_encoding("ASCII-8BIT")
        
        Zip::ZipFile.open(file) { |zip_file|
          zip_file.each{ |f| 
            f_path = File.join(destination, f.name.force_encoding("UTF-8"))
            f_path = f_path.gsub(/\/{1}[\sa-zA-Z0-9\w]*\.mBook/,"")
          
            zip_file.extract(f, f_path) unless File.exist?(f_path)
          }
        }
        
        FileUtils.rm_rf (destination + "/__MACOSX")
        
        tree = REXML::Document.new mbook.zip_path + "/BookInfo.xml"
        
        tree.elements.each("Sections/Section") do |person|
          puts person.get_elements("SectionTitle").first
        end
   end
   
   
  def update
    @mbook = Mbook.get(params[:id].to_i)
    @mbook.subcategory1_id = params[:sub1].to_i

    if params[:sub2] != nil and params[:sub2] != ""
      @mbook.subcategory2_id = params[:sub2].to_i
    else
      @mbook.subcategory2_id = nil
    end
    
    
    @mbook.issue_date = params[:issue_date]
    
    @mbook.price = params[:price]
    
    if params[:mbook_file] != nil and params[:mbook_file] != ""
      @mbook.mbook_file = params[:mbook_file]
      @mbook.original_filename = params[:mbook_file].original_filename.gsub(".zip","")
    else
      @mbook.mbook_file = nil
    end
    
    
    if @mbook.save
      if params[:mbook_file] != nil and params[:mbook_file] != ""
        FileUtils.rm_rf(@mbook.zip_path)
        unzip_uploaded_file(@mbook)
        get_xml_data_update(@mbook)
      end
      redirect_to "/mbooks?me=#{params[:me]}&store=#{params[:store]}"
    else
      puts_message "실패!"
      redirect_to '/mybooks'
    end
  end

  # DELETE /mbooks/1
  # DELETE /mbooks/1.xml
  def destroy
    @mbook = Mbook.find(params[:id])
    @mbook.destroy

    respond_to do |format|
      format.html { redirect_to(mbooks_url) }
      format.xml  { head :ok }
    end
  end
  
  def update_subcategories
      categories = Category.first(:id => params[:category_id].to_i, :display_fl => true)
      @subcategories = Category.all(:parent_id => categories.id)

      render :update do |page|
        page.replace_html 'subcategories1', :partial => 'subcategories1', :object => @subcategories
        page.replace_html 'subcategories2', :partial => 'subcategories2', :object => @subcategories
      end
  end
  
  def deleteSelection 

    chk_ids = params[:ids]
    chks = chk_ids.split(",")

    chks.each do |chk|
      mbook = Mbook.get(chk.to_i)
      if mbook != nil
          puts_message mbook.zipfile
          if File.exists?(mbook.zipfile)
            FileUtils.rm_rf mbook.zipfile
          end
          
          puts_message mbook.zip_path
          if File.exists?(mbook.zip_path)
            FileUtils.rm_rf mbook.zip_path
          end
          
          puts_message MBOOK_PATH + mbook.id.to_s + ".zip"
          if File.exists?(MBOOK_PATH + mbook.id.to_s + ".zip")
            FileUtils.rm_rf MBOOK_PATH + mbook.id.to_s + ".zip"
          end
          
          mbook.destroy 
      end    
    end
    
    redirect_to(mbooks_url)
  end
  
  # Ajax:: mbook 상세페이지에서 스토어 등록 신청을 하는 경우 호출 
  def registration_request_in_store
    puts_message "registration_request_in_store process"
    
    if params[:mbook_id] != nil and params[:mbook_id] != ""
      puts_message params[:mbook_id]
      begin
        mbook_id = params[:mbook_id].to_i
        mbook = Mbook.get(mbook_id)
        mbook.status = "승인대기"
        mbook.save
        
        render :text => "success"
        
      rescue
        render :text => "fail"
      end
      
    else
      render :text => "fail"
    end
  end  
  
  def req_del_from_store
    chk_ids = params[:ids]
    chks = chk_ids.split(",")

    chks.each do |chk|
      mbook = Mbook.get(chk.to_i)
      if mbook != nil
        mbook.status = "삭제대기"  
        mbook.save
      end    
    end
    
    render :text => "success"
  end
  
  
  def fetch_subcategories  
    if params[:category_id] != nil and params[:category_id] != ""
      category_id = params[:category_id].to_i
      level = params[:level].to_i
      mode = params[:mode]
      html_str = ""
    
      html_str = make_parent(level, category_id, mode)
      html_str += make_children(level, category_id, mode)
    
      @result = html_str
    
      render :update do |page|
        if mode == "opt" #선택분류를 선택할 때 
          page.replace_html 'select_category2', :partial => 'subcategories1', :object => @result
        else
          page.replace_html 'select_category', :partial => 'subcategories1', :object => @result
        end
        
      end  

  end
      
    end
  
  
  def make_parent(level, id, mode)
    
    
    if Category.get(id) != nil and Category.get(id) != ""
      
      if level > -1 
    	  parent_id = Category.get(id).parent_id
      	parent_level = level -1

        
    		html_str = make_parent(level-1, parent_id, mode)
        
        if html_str == nil
          html_str = ""
        end
        
    		categories = Category.all(:parent_id => parent_id, :display_fl => true, :order => [:priority])
    		
    		if categories.count > 0
    		  if mode == "opt"
        		html_str += "<select class='select_category' name='select_category2_#{level}' id='select_category2_#{level}' level='#{level}' mode='#{mode}'>"
        		html_str += "<option value="">케테고리 선택</option>"
        	else
        	  html_str += "<select class='select_category' name='select_category_#{level}' id='select_category_#{level}' level='#{level}' mode='#{mode}'>"
        		html_str += "<option value="">케테고리 선택</option>"
        		
      	  end
    		
      		categories.each do |cat|
      			html_str += "<option value='#{cat.id}' #{'selected' if cat.id == id}>#{cat.name}</option>"
      		end

      		html_str += "</select>"
    	  end
    	else
    	  html_str = ""
    	end

    	return html_str
    end
    
    end
    
  	

  def make_children(level, id, mode)
  	categories = Category.all(:parent_id => id, :display_fl => true, :order => [:priority])
    
    if categories.count > 0
      if mode == "opt"
      	html_str = "<select class='select_category' name='select_category2_#{level+1}' id='select_category2_#{level+1}' level='#{level+1}' mode='#{mode}'>"
      	html_str += "<option value="">카테고리 선택</option>"
      else
        html_str = "<select class='select_category' name='select_category_#{level+1}' id='select_category_#{level+1}' level='#{level+1}' mode='#{mode}'>"
      	html_str += "<option value="">카테고리 선택</option>"
      end
    	categories.each do |cat|
    		html_str += "<option value='#{cat.id}'>#{cat.name}</option>"
    	end

    	html_str += "</select>"
    else
      html_str = ""
    end
    
    return html_str
    
  end
  
end








