require 'carrierwave/orm/datamapper' 
 
class MbookUploader < CarrierWave::Uploader::Base

  #include CarrierWave::RMagick

  storage :file
                                         

  def store_dir   
    "#{RAILS_ROOT}" + "/public/mbook/"
  end
  

  def filename
    if original_filename # MBook 파일을 업로드 한 경우에만 적용 
      # puts_message original_filename
      file_ext_name = ".mbook.zip"
      file_name = model.id.to_s
      # file_name = original_filename
      temp_filename = file_name + file_ext_name
      
      temp_filename
    end
  end

  def extension_white_list
          %w(zip)
  end

end
