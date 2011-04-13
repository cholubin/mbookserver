# encoding: utf-8
require 'rexml/document'
include REXML
class MbooksController < ApplicationController
  # before_filter :authenticate_user!

  def index
    @menu = "mbook"
    @board = "mbook"
    @section = "index"
    
    @mbooks = Mbook.all()
    
    # 로그인 한 경우 
    if signed_in?
      
      if (params[:me] == nil or params[:me] == "") and (params[:store] == nil or params[:store] == "")
        params[:me] = "n"
        params[:store] = "y"
      end
      # 내가 올린 mbook중 스토어에 등록된 책 
      if params[:me] == "y" and params[:store] == "y"
        @mbooks = @mbooks.all(:user_id => current_user.id, :status => "승인완료")
        @menu_on = "my_mb_store"
      # 내가 올린 모든 책 
      elsif params[:me] == "y" and params[:store] == "n"
        @mbooks = @mbooks.all(:user_id => current_user.id)
        @menu_on = "my_mb"
      # 스토어에 등록된 모든 책 
      elsif params[:me] == "n" and params[:store] == "y"
        @mbooks = @mbooks.all(:status => "승인완료")
        @menu_on = "mb_store"
      end

      if params[:st] != nil and params[:st] != ""
        if params[:st] == "1"
          strStatus = "승인완료"
        elsif params[:st] == "2"
          strStatus = "삭제대기"
        end 
        @mbooks = @mbooks.all(:status   => strStatus)
      end
    
      
      if params[:cat] != nil and params[:cat] != ""
        @mbooks = @mbooks.all(:category_id => params[:cat].to_i)
      end
    
      if params[:sub] != nil and params[:sub] != ""
        @mbooks = (@mbooks.all(:subcategory1_id => params[:sub].to_i) || @mbooks.all(:subcategory2_id => params[:sub].to_i))
        puts_message "2:: " + @mbooks.count.to_s
        
      end
      
      @total_count = @mbooks.search(params[:keyword], params[:search],"").count
      @mbooks = @mbooks.search(params[:keyword], params[:search], params[:page])
      
    # 로그인 하지 않은 경우 (스토어에 등록된 책만 보여준다.)
    else
      
      @menu_on = "mb_store"
      
      if params[:in_store] == "y"
        @mbooks = @mbooks.all(:status => "승인완료")
      end
      
      if params[:cat] != nil and params[:cat] != ""
        @mbooks = @mbooks.all(:category_id => params[:cat].to_i)
      end
    
      if params[:sub] != nil and params[:sub] != ""
        @mbooks = (@mbooks.all(:subcategory1_id => params[:sub].to_i) || @mbooks.all(:subcategory2_id => params[:sub].to_i))
      end
      
      
      @total_count = @mbooks.search(params[:keyword], params[:search],"").count
      @mbooks = @mbooks.search(params[:keyword], params[:search], params[:page])
      
    end

    
    @categories = Category.all(:gubun => "template", :order => :priority)
      
    render 'mbook'  
  end


  def booklist
    puts_message "good"
    
    # respond_to do |format|
    #   format.xml { render :layout => false }
    # end
    @board = "mbook"
    @section = "booklist"
    
    @mbooks = Mbook.all(:order => [:created_at.asc])
    
    render 'mbook', :layout => "no_layout"
  end

  # GET /mbooks/1
  # GET /mbooks/1.xml
  def show
    @mbook = Mbook.get(params[:id].to_i)

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
    
    @categories = Category.all(:gubun => "template", :order => :priority)    
    category_id = @mbook.category_id
    @subcategories = Subcategory.all(:category_id => category_id, :order => [:priority])
    
    render 'mbook'
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
      
      @categories = Category.all(:gubun => "template", :order => :priority)    
      category_id = Category.first(:gubun => "template", :order => [:priority]).id.to_i
      @subcategories = Subcategory.all(:category_id => category_id, :order => [:priority])    
      
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
    @mbook = Mbook.new()
    @mbook.category_id = params[:category_id]
    @mbook.subcategory1_id = params[:subcategory1_id]
    @mbook.subcategory2_id = (params[:subcategory2_id] != nil and params[:subcategory2_id] != "") ? params[:subcategory2_id] : nil
    @mbook.issue_date = params[:issue_date]
    
    @mbook.price = params[:price]
    @mbook.user_id = current_user.id
    
    @mbook.mbook_file = params[:mbook_file]
    @mbook.original_filename = params[:mbook_file].original_filename.gsub(".zip","")
    
    if @mbook.save
      unzip_uploaded_file(@mbook)
      get_xml_data_update(@mbook)
      # rezip_uploaded_file(@mbook)
      redirect_to '/mbooks?me=y&store=n'
    else
      puts_message "실패!"
      redirect_to '/mybooks'
    end
  end

  def unzip_uploaded_file(mbook) 
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

     unzip(mbook, destination)    
     # get_xml_data_update(mbook)
  end
   
   def rezip_uploaded_file(mbook)
     path = mbook.zip_path
     zip_name = mbook.id.to_s + ".zip"
     
     puts_message path
     puts_message zip_name
     
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
       # mbook.description = mb.elements["Description"].text
       if mbook.save
         puts_message "mBook 메타데이타 업데이트 완료!"
       else
         puts_message "mBook 메타데이타 업데이트 실패!"
       end
     end 
   end

   def unzip(mbook, destination)  
        file = mbook.zipfile
        file_names = ["BookInfo.xml", "medium.jpg", "cover_image.png"]
        
        Zip::ZipFile.open(file) { |zip_file|
          i = 0
          zip_file.each{ |f| 
            f_path = File.join(destination, f.name)
            
            @folder_name = f.name if i == 0
            
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
        
        if @dir_names.length == 3 # 폴더를 압축한 경우 
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
    @mbook.category_id = params[:category_id]
    @mbook.subcategory1_id = params[:subcategory1_id]
    @mbook.issue_date = params[:issue_date]
    
    if params[:subcategory2_id] != nil and params[:subcategory2_id] != ""
      @mbook.subcategory2_id = params[:subcategory2_id]
    else
      @mbook.subcategory2_id = nil
    end
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
      end
      redirect_to '/mbooks'
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
      categories = Category.first(:id => params[:category_id].to_i)
      @subcategories = Subcategory.all(:category_id => categories.id)

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
  
  
  
  
  
end
