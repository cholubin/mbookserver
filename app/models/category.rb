# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-pager'

class Category
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,           Serial
  property :name,         String, :required => true
  property :priority,     Integer, :default => 9999
  property :gubun,        String, :default => "template"
  property :icon_image,   String, :default => "icon_category.png"
  
  property :level,        Integer
  property :parent_id,    Integer
  property :display_fl,   Boolean, :default => true
  timestamps :at

end

DataMapper.auto_upgrade!