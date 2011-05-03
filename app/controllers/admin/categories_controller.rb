# encoding: utf-8

class Admin::CategoriesController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!      
  # GET /admin_categories
  # GET /admin_categories.xml
  def index
    @board = "category"
    @section = "index"
    @menu_on = "category"  
    
    @categories = Category.all(:gubun => "template", :order => [ :priority ])
    
    if params[:level] !=nil and  params[:level] != ""
      level = params[:level].to_i
      
    else
      level = 0
    end
    
    @categories = @categories.all(:level => level)
    
    if params[:parent_id] != nil and params[:parent_id]
      parent_id = params[:parent_id].to_i
      
      @categories = @categories.all(:parent_id => parent_id)
    end
    

     render 'category'
  end
  


  # GET /admin_categories/1
  # GET /admin_categories/1.xml
  def show
    @menu = "category"
    @board = "category"
    @section = "show"
        
    @category = Category.get(params[:id])
    @subcategories = @category.subcategories.all(:order => [ :priority.asc ])
    
     render 'admin/categories/category', :layout => false
  end

  # GET /admin_categories/new
  # GET /admin_categories/new.xml
  def new
    @menu = "category"
    @board = "category"
    @section = "new"
      
    @category = Category.new
    @select_main_category = Category.all(:order => [ :priority.asc ])  

     render 'admin/categories/category'
  end

  # GET /admin_categories/1/edit
  def edit
    
    @menu = "category"
    @board = "category"
    @section = "edit"
        
    @category = Category.get(params[:id])
    
    render 'category'
  end

  # POST /admin_categories
  # POST /admin_categories.xml
  def create
    if params[:level] !=nil and  params[:level] != ""
      level = params[:level].to_i
    else
      level = 0
    end

    if params[:display_fl] != nil and params[:display_fl]
      if params[:display_fl] == "on"
        display_fl = false
      else
        display_fl = true
      end
    else
      display_fl = true
    end
    
    if params[:parent_id] != nil and params[:parent_id]
      parent_id = params[:parent_id].to_i
    else
      parent_id = 0
    end
    
    if params[:mode] == "new"
      if params[:category_name] != "" and params[:category_name] != ""
        if Category.all(:name => params[:category_name], :gubun => "template", :level => level, :parent_id => parent_id).count < 1
          @category = Category.new
          @category.name = params[:category_name] 
          @category.gubun = "template"
          @category.level = level
          @category.display_fl = display_fl
          @category.parent_id = parent_id
          @category.priority = Category.all(:gubun => "template", :level => level).count + 1
        
          if params[:file] != nil and params[:file] != ""
              if Category.all(:icon_image => sanitize_filename(params[:file].original_filename), :gubun => "template").count > 0
                render :text => "fail:동일한 파일명의 아이콘 이미지가 이미 업로드되어있습니다! \n파일명을 수정하거나 다른 이미지를 선택해주세요~"
              else
                @category.icon_image = sanitize_filename(params[:file].original_filename)
                icon_upload(params[:file])
                
                if @category.save
                  puts_message 'Main category was successfully created.'
                  @categories = Category.all(:gubun => "template")

                  render :partial => 'list_category', :object => @categories
                else
                  render :text => "fail:카테고리 생성중 오류가 발생했습니다!"
                end
              end
          else
              if @category.save
                puts_message 'Main category was successfully created.'
                @categories = Category.all(:gubun => "template", :level => level, :parent_id => parent_id)

                render :partial => 'list_category', :object => @categories
              else
                render :text => "fail:카테고리 생성중 오류가 발생했습니다!"
              end
          end
          
          
        else
          render :text => "fail:이미 사용중인 카테고리 이름입니다!"
        end
      else
        render :text => "fail:카테고리 이름을 입력하세요!"
      end
      
    elsif params[:mode] == "mod"
      @category = Category.get(params[:category_id].to_i)
      @category.name = params[:category_name] 
      @category.display_fl = display_fl
      
      if params[:file] != nil and params[:file] != ""
        if Category.all(:icon_image => sanitize_filename(params[:file].original_filename), :gubun => "template").count > 0
          render :text => "fail:동일한 파일명의 아이콘 이미지가 이미 업로드되어있습니다! \n파일명을 수정하거나 다른 이미지를 선택해주세요~"
        else
          if @category.icon_image != "icon_category.png"
            FileUtils.rm_rf("#{RAILS_ROOT}" + "/public/images/category_icon/" + @category.icon_image)
          end
          @category.icon_image = sanitize_filename(params[:file].original_filename)
          icon_upload(params[:file])
          
          if @category.save;
            @categories = Category.all(:gubun => "template", :level => level, :parent_id => parent_id)
            render :partial => 'list_category', :object => @categories
          else
            render :text => "fail:카테고리 수정중 오류가 발생했습니다!"
          end
        end
        
      else
        if @category.save;
          @categories = Category.all(:gubun => "template", :level => level, :parent_id => parent_id)
          render :partial => 'list_category', :object => @categories
        else
          render :text => "fail:카테고리 수정중 오류가 발생했습니다!"
        end  
      end
      
      
      
    else
      render :text => "카테고리 작업중 알수없는 오류가 발생했습니다!"
    end
  end
  
  def icon_upload(file)
    uploader = Category_iconUploader.new
    uploader.store!(file)
  end

  # PUT /admin_categories/1
  # PUT /admin_categories/1.xml
  def update
    @menu = "category"
    @board = "category"
    @section = "edit"
    
    @category = Category.get(params[:id])
    
    @category.name = params[:category][:name]
    @category.priority = params[:category][:priority].to_i
        
      if @category.save
        redirect_to (admin_category_url)
      else
        render 'category'
      end

  end

  # # DELETE /admin_categories/1
  # # DELETE /admin_categories/1.xml
  # def destroy
  #   puts "==============================="
  #   @category = Category.get(params[:id])
  #   @subcategoris = Subcategory.all(:category_id => @category.id)
  #   
  # 
  #   if @subcategoris.destroy
  #     @category.destroy
  #     redirect_to admin_categories_url      
  #   else
  #     puts_message "Error occured during deleting subcategories"
  #     redirect_to admin_categories_url      
  #   end
  # end
  # 
  # def destroy_sub
  #   @categories = Category.all
  #   @subcategory = @categories.subcategories.get(params[:id].to_i)
  #   
  #   if @subcategory.destroy
  #     redirect_to admin_categories_url      
  #   else
  #     puts_message "Error occured during deleting subcategories"
  #     redirect_to admin_categories_url      
  #   end
  # end  

  def category_order_update
    category_id = params[:category_id].split(',')
    
    if !category_id.nil? 
      i = 1
      category_id.each do |c|
        temp = c.split('_')
        if Category.get(temp[1].to_i) != nil
          category = Category.get(temp[1].to_i)
          category.priority = i
          category.save
        end
        i += 1
      end
    end

  puts_message "category sorting has finished!"
  render :nothing => true
  end

  def subcategory_order_update
    subcategory_id = params[:subcategory_id].split(',')
    @category = Category.get(params[:category_id].to_i)
    
    if !subcategory_id.nil? 
      i = 1
      subcategory_id.each do |s|
        temp = s.split('_')
        subcategory = Subcategory.get(temp[1].to_i)
        subcategory.priority = i
        subcategory.save
        
        i += 1
      end
    end

    puts_message "subcategory sorting has finished!"
  render :nothing => true
  end

  def add_category
    category_name = params[:category_name]
    
    categories = Category.all(:order => [:priority])

    i = 2
    categories.each do |c|
      c.priority = i
      c.save
      i += 1
    end
    
    category = Category.new()
    category.name = category_name
    category.priority = 1
    category.save
    
    @categories = Category.all(:gubun => "template")
    
    # render :update do |page|
      render :partial => 'list_category', :object => @categories
      # page.replace_html 'list_category', :partial => 'list_category', :object => @categories
    # end
  end
  
  def add_subcategory
    category_id = params[:category_id]
    subcategory_name = params[:subcategory_name]
    
    @category = Category.get(category_id.to_i)
    @subcategory = @category.subcategories.new

    if @category.subcategories.first(:order => [:priority.desc]).nil?
      max_order = 0
    else
      max_order =  @category.subcategories.first(:order => [:priority.desc]).priority
    end
    
    @subcategory.priority = max_order + 1
    @subcategory.name = subcategory_name
    
    if @subcategory.save
      puts_message "adding subcategory has finished!"
    else
      puts_message "erorr occrued!"
    end

    @category_id = category_id
    
    render :update do |page|
      page.replace_html 'created_subcategory', :partial => 'created_subcategory', :object => @subcategory, :object => @category_id
    end

  end

  def delete_category
    temp_category_name = params[:category_id].split('_')
    
    category_selector = temp_category_name[0]
    id = temp_category_name[1]
    
    if category_selector == "cate-del"
      #카테고리 삭제의
      category_id = id.to_i
      @category = Category.get(id.to_i)
      @subcategories = Subcategory.all(:category_id => @category.id)
    
    
      if @subcategories.destroy
        puts_message "서브카테고리들 삭제 완료!"
        if @category.destroy
          puts_message "카테고리 삭제 완료!"
        end
      end
    else
    #서브카테고리의 삭제 
    @subcategory = Subcategory.get(id.to_i)
      if @subcategory.destroy
        puts_message "서브카테고리 삭제 완료!"
      end
    end
    
    render :nothing => true
  end
  
  
  def update_category
    temp_category_id = params[:category_id].split('_')
    category_name = params[:category_name]
    category_selector = temp_category_id[0]
    category_id = temp_category_id[1]
    
    if category_selector == "cate-edit"
      @category = Category.get(category_id.to_i)
      @category.name = category_name
      if @category.save
        puts_message "카테고리 업데이트 완료!"
      end
    else
      @subcategory = Subcategory.get(category_id.to_i)
      @subcategory.name = category_name
      if @subcategory.save
        puts_message "서브카테고리 업데이트 완료!"
      end
    end
    render :nothing => true
  end
  
  def update_category_name
    category_id = params[:category_id].to_i
    category_name = params[:category_name]
    
    @category = Category.get(category_id)
    @category.name = category_name

    if @category.save
      render :text => "success"
    else
      render :text => "fail"
    end
  end
  
  
  def delete_subcategory(id)
    parent_id = id.to_i
    begin
      if Category.all(:parent_id => parent_id).count > 0
        puts_message "자신의 서브카테고리 삭제 진행 ("+Category.all(:parent_id => parent_id).count.to_s+")"
        Category.all(:parent_id => parent_id).each do |cat|
          delete_subcategory(cat.id)
        end
      end
      
      self_category = Category.get(id.to_i)
      self_name = self_category.name
      if self_category.destroy
        puts_message self_name + ": 삭제 완료"
      end
      
      result = "success"
    rescue
      result = "fail"
    end
    
    return result
  end
  
  def delete_selection
    result = ""
    if params[:parent_id] != nil and params[:parent_id] != ""
      parent_id = params[:parent_id].to_i
    else
      parent_id = 0
    end

    if params[:level] != nil and params[:level] != ""
      level = params[:level].to_i
    else
      level = 0
    end
    
    if params[:ids] != nil and params[:ids] != ""
      ids = params[:ids].split(",")
    
      ids.each do |id|
          result = delete_subcategory(id)
      end #ids do loop end
      
    else
      result = "삭제할 항목을 선택해 주세요!"
    end
    
    
    html_str = ""
    if result == "success"
      i = 1
				Category.all(:gubun => "template",:level => level, :parent_id=> parent_id, :order => [:priority.asc]).each do |cat|
				    html_str  = html_str	+ "<ul class='list_ul #{'list_first' if i % 6 == 1}' id='ul_#{cat.id}'>\n" +
						"<li class='icon_cotegory'><a href='/admin/categories?level=#{level+1}&parent_id=#{cat.id}'><img src='/images/category_icon/#{cat.icon_image}' alt='카테고리 아이콘'></a></li>\n" +
						"<li class='category_name cat_name' category_id='#{cat.id}' cat_name='#{cat.name}'>#{cat.name}</li>\n" +
						"<li><img src='/images/bt/bt_upload_re.png' alt='수정' style='cursor:pointer;' class='btn_mod' category_id='#{cat.id}' category_name='#{cat.name}'>\n" + 
						"<input type='checkbox' class='chkbox' category_id='#{cat.id}'></li>\n" +
						"</ul>\n";
				i += 1
				end
				
				result = "success@@" + html_str 
    end
    render :text => result
    
  end
  
  def update_category_order
    ids = params[:ul_ids].gsub(/ul_/,"").split(",")
    
    begin 
      i = 1
      ids.each do |id|
        category = Category.get(id.to_i)
        category.priority = i
        category.save
        
        i += 1
      end
      
      result = "success"
    rescue
      result = "카테고리의 우선순위 업데이트 중 오류가 발생했습니다!"
    end
    
    render :text => result
  end
  
  
end
