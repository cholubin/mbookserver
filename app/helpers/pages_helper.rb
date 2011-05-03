module PagesHelper

  def make_category_str_main(current_id)
    str = ""
    if Category.get(current_id) != nil
      parent_id = Category.get(current_id).parent_id
      parent_level = Category.get(current_id).level

  	  str = make_category_str_main(Category.get(current_id).parent_id) + "<li><a href='?level=#{parent_level}&parent_id=#{parent_id}'>#{Category.get(current_id).name}</a></li><li><img src='/images/root/root_arrow_blue.png'></li>"
  	end
  	return str
  end

end