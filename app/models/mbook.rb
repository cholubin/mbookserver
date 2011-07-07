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
  property :userid,             String
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
  property :cancel_reason,      Text
  property :coverimage_name,    String
  property :covermedium_name,   String
  property :thumbnail_name,     String
  property :file_size,          Float #단위:MB

  #포인트관련 추가사항 
  property :unlimited_down_fl,  Boolean, :default => false

  timestamps :at
  
  before :create, :file_path
  
  def file_path   
    dir = MBOOK_PATH
    FileUtils.mkdir_p dir if not File.exist?(dir)
    FileUtils.chmod 0777, dir
    
    return dir 
  end
  
  def self.search(mbooks, keyword, search, page)
    case keyword
      when "writer"
        mbooks.all(:writer.like => "%#{search}%").page :page => page, :per_page => 10
      when "publisher"
        mbooks.all(:publisher.like => "%#{search}%").page :page => page, :per_page => 10
      when "issue_date"
        mbooks.all(:issue_date.like => "%#{search}%").page :page => page, :per_page => 10
      when "title"
        mbooks.all(:title.like => "%#{search}%").page :page => page, :per_page => 10
      when "reg_date"
        mbooks.all(:created_at.like => "%#{search}%").page :page => page, :per_page => 10
      when "userid"
        mbooks.all(:userid.like => "%#{search}%").page :page => page, :per_page => 10
      when "price"
        mbooks.all(:price.like => "%#{search}%").page :page => page, :per_page => 10
      when "status"
        mbooks.all(:status.like => "%#{search}%").page :page => page, :per_page => 10  
      else
        mbooks.all.page :page => page, :per_page => 10
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

  def covermedium_url
    if self.covermedium_name != nil and self.covermedium_name != ""
      zip_path = MBOOK_URL + "#{self.id.to_s}/#{self.covermedium_name}"
    else
      zip_path = MBOOK_URL + "#{self.id.to_s}/#{self.thumbnail_name}"
    end
    return zip_path
  end
end

DataMapper.auto_upgrade!

