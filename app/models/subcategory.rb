# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-pager'

class Subcategory

  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource

  
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,           Serial
  property :name,         String, :required => true
  property :priority,     Integer, :default => 9999
  property :gubun,        String, :default => "template"
  property :icon_image,   String, :default => "icon_subcategory.png"
  property :category_id,  Integer    
  timestamps :at

  belongs_to :category

end


