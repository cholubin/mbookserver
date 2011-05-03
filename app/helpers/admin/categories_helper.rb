module Admin::CategoriesHelper
  def make_category_str(current_id)
    str = ""
    if Category.get(current_id) != nil
      parent_id = Category.get(current_id).parent_id
      parent_level = Category.get(current_id).level
  	  str = make_category_str(Category.get(current_id).parent_id) + "<li><a href='/admin/categories?level=#{parent_level}&parent_id=#{parent_id}'>#{Category.get(current_id).name}</a><b> ></b></li>"
  	end
  	
  	return str
  end
  
  
end
