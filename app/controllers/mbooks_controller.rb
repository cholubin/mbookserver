# encoding: utf-8
require 'rexml/document'
include REXML
class MbooksController < ApplicationController
  # before_filter :authenticate_user!

  def index
    @menu = "mbook"
    @board = "mbook"
    @section = "index"
    
    @mbooks = Mbook.all
    
    if params[:me] == "y"
      @mbooks = @mbooks.all(:user_id => current_user.id)
    end
    
    if params[:cat] != nil and params[:cat] != ""
      @mbooks = @mbooks.all(:category_id => params[:cat].to_i)
    end
    
    if params[:sub] != nil and params[:sub] != ""
      @mbooks = (@mbooks.all(:subcategory1_id => params[:sub].to_i) + @mbooks.all(:subcategory2_id => params[:sub].to_i))
    end
    
    if params[:keyword] != nil and params[:keyword] != ""
      @total_count = @mbooks.search(params[:keyword], params[:search],"").count
      @mbooks = @mbooks.search(params[:keyword], params[:search], params[:page])
    end
    
    @total_count = @mbooks.search(params[:keyword], params[:search],"").count
    
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
    
    @mbooks = Mbook.all
    
    render 'mbook', :layout => "no_layout"
  end

  # GET /mbooks/1
  # GET /mbooks/1.xml
  def show
    @mbook = Mbook.get(params[:id].to_i)

    @menu = "mbook"
    @board = "mbook"
    @section = "show"
    
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
      
      @mbook = Mbook.new
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
    if params[:subcategory2_id] != nil and params[:subcategory2_id] != ""
      @mbook.subcategory2_id = params[:subcategory2_id]
    else
      @mbook.subcategory2_id = nil
    end
    @mbook.price = params[:price]
    @mbook.user_id = current_user.id
    
    @mbook.mbook_file = params[:mbook_file]
    @mbook.original_filename = params[:mbook_file].original_filename.gsub(".zip","")
    
    if @mbook.save
      unzip_uploaded_file(@mbook)
      redirect_to '/mbooks'
    else
      puts_message "실패!"
      redirect_to '/mybooks'
    end
  end

  def unzip_uploaded_file(mbook) 
   if mbook != nil   
     destination = MBOOK_PATH + "#{mbook.id.to_s}"
     
     begin
       FileUtils.mkdir_p destination if not File.exist?(destination)
       FileUtils.chmod 0777, destination
      rescue
        puts_message "mbook folder creation was failed!"
      end
     
     # puts_message destination 
     
     loop do 
        break if File.exists?(mbook.zipfile)
     end
     
       unzip(mbook, destination)    
       get_xml_data_update(mbook)
                 
     end
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
  
end
