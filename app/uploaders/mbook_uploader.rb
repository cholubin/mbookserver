require 'carrierwave/orm/datamapper' 
 
class MbookUploader < CarrierWave::Uploader::Base

  #include CarrierWave::RMagick

  storage :file
                                         

  def store_dir   
    MBOOK_PATH
  end
  

  def filename
    if original_filename # mLayout 템플릿을 업로드 한 경우에만 적용 
      file_ext_name = ".mbook.zip"
      file_name = model.id.to_s

      temp_filename = file_name + file_ext_name
      
      # puts temp_filename
      
      temp_filename
    end
  end

  def extension_white_list
          %w(zip)
  end

end
