require 'carrierwave/orm/datamapper' 
 
class Category_iconUploader < CarrierWave::Uploader::Base

  #include CarrierWave::RMagick

  storage :file
                                         

  def store_dir   
    "#{RAILS_ROOT}" + "/public/images/category_icon"
  end
  

  def filename

    if original_filename 
      temp_filename = sanitize_filename(original_filename)
      
      temp_filename
    end
  end

  def extension_white_list
          %w(jpg gif png)
  end

end
