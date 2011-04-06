# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class Mbook
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  mount_uploader :mbook_file, MbookUploader
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :mbook_file,         Text
  property :original_filename,  String
  property :id,                 Serial
  property :user_id,            Integer
  property :category_id,        Integer
  property :subcategory1_id,    Integer
  property :subcategory2_id,    Integer
  property :title,              String
  property :writer,             String
  property :publisher,          String
  property :pages,              String
  property :issue_date,         String
  property :description,        Text
  property :price,              String
  property :status,             String, :default => "대기"  # (status; "대기", "승인완료", "승인거부", "승인대기", "삭제대기")
  property :coverimage_name,    String
  property :thumbnail_name,     String

  timestamps :at
  
  before :create, :file_path
  
  def file_path   
    dir = MBOOK_PATH
    FileUtils.mkdir_p dir if not File.exist?(dir)
    FileUtils.chmod 0777, dir
    
    return dir 
  end
  
  def self.search(keyword, search, page)
    # puts_message self.count.to_s
    case keyword
      when "wrter"
        self.all(:wrter.like => "%#{search}%").page :page => page, :per_page => 10
      when "publisher"
        self.all(:publisher.like => "%#{search}%").page :page => page, :per_page => 10
      when "title"
        self.all(:title.like => "%#{search}%").page :page => page, :per_page => 10
      when "user_id"
        self.all(:user_id.like => "%#{search}%").page :page => page, :per_page => 10
      else
        self.all.page :page => page, :per_page => 10
    end
      
  end
  
  def zipfile
    zip_path = MBOOK_PATH + "#{self.id.to_s}.mbook.zip"
    return zip_path
  end

  def zip_path
    zip_path = MBOOK_PATH + "#{self.id.to_s}"
    return zip_path
  end
  
  def zip_url
    zip_path = MBOOK_URL + "#{self.id.to_s}"
    return zip_path
  end

  def coverimage_url
    zip_path = MBOOK_URL + "#{self.id.to_s}/#{self.coverimage_name}"
    return zip_path
  end

  def thumbnail_url
    zip_path = MBOOK_URL + "#{self.id.to_s}/#{self.thumbnail_name}"
    return zip_path
  end

  
end

DataMapper.auto_upgrade!

