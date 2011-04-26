# encoding: utf-8

class Admin::SubcategoriesController < ApplicationController
  layout 'admin_layout'
  before_filter :authenticate_admin!      
  # GET /admin_categories
  # GET /admin_categories.xml
  def index
    if params[:cat] != nil and params[:cat] != ""
      category_id = params[:cat].to_i
    else
      category_id = Subcategory.first(:gubun => "template").id
    end
    
    @menu = "subcategory"
    @board = "subcategory"
    @section = "index"
    @menu_on = "category"  
    
    @categories = Category.all(:gubun => "template", :order => [:priority])
    @subcategories = Subcategory.all(:category_id => category_id, :order => [:priority])

     render 'subcategory'
  end
  
  def create
    if params[:category_id] != nil and params[:category_id] != ""
      category_id = params[:category_id]
    else
      if Category.first(:gubun => "template") != nil
        category_id = Category.first(:gubun => "template").id
      else
        redirect_to '/admin/categories'
      end
    end
    
    if params[:mode] == "new"
      
      if params[:subcategory_name] != "" and params[:subcategory_name] != ""
        if Subcategory.all(:name => params[:subcategory_name], :gubun => "template", :category_id => category_id.to_i).count < 1
          @subcategory = Subcategory.new
          @subcategory.category_id = category_id.to_i
          @subcategory.name = params[:subcategory_name] 
          @subcategory.gubun = "template"
          @subcategory.priority = Subcategory.all(:gubun => "template", :category_id => category_id.to_i).count + 1
        
          if params[:file] != nil and params[:file] != ""
              if Subcategory.all(:icon_image => sanitize_filename(params[:file].original_filename), :gubun => "template").count > 0 or File.exists( "#{RAILS_ROOT}" + "/public/images/icon_images/" + sanitize_filename(params[:file].original_filename) )
                render :text => "fail:동일한 파일명의 아이콘 이미지가 이미 업로드되어있습니다! \n파일명을 수정하거나 다른 이미지를 선택해주세요~"
              else
                @subcategory.icon_image = sanitize_filename(params[:file].original_filename)
                icon_upload(params[:file])
                
                if @subcategory.save
                  puts_message 'Subcategory was successfully created.'
                  @subcategories = Subcategory.all(:category_id => category_id.to_i)

                  render :partial => 'list_category', :object => @subcategories
                else
                  render :text => "fail:카테고리 생성중 오류가 발생했습니다!"
                end
              end
          else
              if @subcategory.save
                puts_message 'Sub category was successfully created.'
                @subcategories = Subcategory.all(:category_id => category_id.to_i)

                render :partial => 'list_category', :object => @subcategories
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
      @subcategory = Subcategory.get(params[:subcategory_id].to_i)
      @subcategory.name = params[:subcategory_name] 
      
      if params[:file] != nil and params[:file] != ""
        if Subcategory.all(:icon_image => sanitize_filename(params[:file].original_filename), :gubun => "template").count > 0 or File.exists( "#{RAILS_ROOT}" + "/public/images/icon_images/" + sanitize_filename(params[:file].original_filename) )
          render :text => "fail:동일한 파일명의 아이콘 이미지가 이미 업로드되어있습니다! \n파일명을 수정하거나 다른 이미지를 선택해주세요~"
        else
          if @subcategory.icon_image != "icon_subcategory.png"
            FileUtils.rm_rf("#{RAILS_ROOT}" + "/public/images/category_icon/" + @subcategory.icon_image)
          end
          @subcategory.icon_image = sanitize_filename(params[:file].original_filename)
          icon_upload(params[:file])
          
          if @subcategory.save;
            @subcategories = Subcategory.all(:category_id => category_id.to_i)
            render :partial => 'list_category', :object => @subcategories
          else
            render :text => "fail:카테고리 수정중 오류가 발생했습니다!"
          end
        end
        
      else
        if @subcategory.save;
          @subcategories = Subcategory.all(:category_id => category_id)
          render :partial => 'list_category', :object => @subcategories
        else
          render :text => "fail:카테고리 수정중 오류가 발생했습니다!"
        end  
      end
      
      
      
    else
      render :text => "카테고리 작업중 알수없는 오류가 발생했습니다!"
    end
  end
  
  def update_subcategory_name
    category_id = params[:subcategory_id].to_i
    category_name = params[:subcategory_name]
    
    @subcategory = Subcategory.get(category_id)
    @subcategory.name = category_name

    if @subcategory.save
      render :text => "success"
    else
      render :text => "fail"
    end
  end
  
  def delete_selection
    result = ""
    category_id = params[:category_id]
    
    if params[:ids] != nil and params[:ids] != ""
      ids = params[:ids].split(",")
    
      ids.each do |id|
        subcat = Subcategory.get(id.to_i)
        
        if subcat.destroy
          
          begin
            if Mbook.all(:subcategory1_id => id.to_i).count > 0
              mbooks = Mbook.all(:subcategory1_id => id.to_i)
              mbooks.each do |mbook|
                mbook.subcategory1_id = nil
              
                mbook.save
              end
              puts_message "mbook 서브카테고리1 초기화 완료"
              result = "success"
            end
            
            if Mbook.all(:subcategory2_id => id.to_i).count > 0
              mbooks = Mbook.all(:subcategory2_id => id.to_i)
              mbooks.each do |mbook|
                mbook.subcategory2_id = nil
              
                mbook.save
              end
              puts_message "mbook 서브카테고리2 초기화 완료"
              result = "success"
            end
            
          rescue
            result = "mbook의 서브카테고리 정보를 초기화 하는중 오류가 발생했습니다!"
          end
          
          result = "success"
        else
          result = "서브테고리 삭제중 오류 발생"
        end
      end #ids do loop end
      
    else
      result = "삭제할 항목을 선택해 주세요!"
    end
    
    html_str = ""
    if result == "success"
      i = 1
				Subcategory.all(:category_id => category_id.to_i, :order => [:priority.asc]).each do |cat|
				    html_str  = html_str	+ "<ul class='list_ul #{'list_first' if i % 6 == 1}' id='ul_#{cat.id}'>\n" +
						"<li class='icon_cotegory'><img src='/images/category_icon/#{cat.icon_image}' alt='카테고리 아이콘'></li>\n" +
						"<li class='category_name cat_name' category_id='#{cat.id}' cat_name='#{cat.name}'>#{cat.name}</li>\n" +
						"<li><img src='/images/bt/bt_upload_re.png' alt='수정' style='cursor:pointer;' class='btn_mod' category_id='#{cat.id}' category_name='#{cat.name}'>\n" + 
						"<input type='checkbox' class='chkbox' category_id='#{cat.id}'></li>\n" +
						"</ul>\n";
				i += 1
				end
				
				result = "success@@" + html_str 
    end
    
    puts_message result
    render :text => result
    
  end
  
  def update_category_order
    ids = params[:ul_ids].gsub(/ul_/,"").split(",")
    
    begin 
      i = 1
      ids.each do |id|
        subcategory = Subcategory.get(id.to_i)
        subcategory.priority = i
        subcategory.save
        
        i += 1
      end
      
      result = "success"
    rescue
      result = "카테고리의 우선순위 업데이트 중 오류가 발생했습니다!"
    end
    
    render :text => result
  end
  
  
end
