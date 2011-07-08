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
  property :userid,             String
  property :mbookid,            Integer
  
  # 포인트 관련 추가 속성
  property :mbook_title,        String
  property :free_or_not_fl,     Boolean
  property :mbook_price,        String  #다운로드 당시의 mbook 가격, 무료인 경우 0 
  property :dn_user_id,         String
  
  # 통계시 그룹핑시 유리하도록..
  #devicetype : 100 - iPad, 101 - iPhone, 102 - iPod Touch, 200 - 갤럭시 탭, 201 - 갤럭시 10.9…
	#* 1XX -> iOS Device, 2XX -> Android Device
  property :deviceid,           String
  property :devicetype_main,    String
  property :devicetype_sub,     String
  
  property :down_cnt,           Integer
  timestamps :at


end

DataMapper.auto_upgrade!