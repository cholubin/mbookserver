# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class Mbookdncount
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,                 Serial
  property :userid,             String, :required => true
  property :mbookid,            Integer
  
  # 포인트 관련 추가 속성
  property :mbook_title,        String
  property :free_or_not_fl,     Boolean
  property :mbook_price,        String  #다운로드 당시의 mbook 가격, 무료인 경우 0 
  property :dn_user_id,         String
  property :devicetype,         String
  
  timestamps :at


end

DataMapper.auto_upgrade!