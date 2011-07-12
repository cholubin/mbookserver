# encoding: utf-8
require 'rubygems'
require 'carrierwave/orm/datamapper'   
require 'dm-core'
require 'dm-validations'
require 'dm-pager'

$:.unshift File.dirname(__FILE__) + '/../lib'

class User
  
  # Class Configurations ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  include DataMapper::Resource
  attr_accessor :password
  
  # Attributes ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
  property :id,                 Serial
  property :userid,             String, :required => true
  property :name,               String, :required => true 
  property :type,               String, :default => "writer" # reader / writer
  property :servicetype,        String, :default => "shared" # shared / single / multiple
  property :publisher,          String #필명/출판사명
  property :email,              String
  property :tel,                String
  property :mobile,             String

  # 메일인증을 위해서 추가 
  property :auth_code,          String, :length => 150  #인증코드 (메일인증)
  property :auth_fl,            Boolean, :default => false
  
  property :encrypted_password, String, :length => 150
  property :salt,               String, :length => 150
  property :remember_token,     Text,   :length => 150

  property :withdrawal_reason,  Text
  
  timestamps :at
  
  
  before :save, :encrypt_password
  before :update, :encrypt_password
  # after  :save, :demo_up

  def update_password(submitted_password)
    self.update(:encrypted_password => encrypt(submitted_password))
  end
  
  def has_password?(submitted_password)
      encrypted_password == encrypt(submitted_password)      
  end

  def remember_me!
      # self.remember_token = encrypt("#{salt}--#{id}")  
      self.update(:remember_token => encrypt("#{salt}--#{id}"))

  end
  
  
  def self.search_admin(keyword, search, page)
      User.all(:name.like => "%#{search}%").page :page => page, :per_page => 12
  end

  
  def self.search(search, page)
      User.all(:name.like => "%#{search}%").page :page => page, :per_page => 10
  end
  
  def self.authenticate(userid, submitted_password)
    
      user = User.first(:userid => userid)
      
      if user.nil?
        nil
      elsif user.has_password?(submitted_password)
        user
      end
  end

  def make_authcode
    return make_auth
  end
  
   private

       def encrypt_password
         if self.encrypted_password.nil?
           self.salt = make_salt
           self.encrypted_password = encrypt(password)
         end
       end

       def encrypt(string)
         secure_hash("#{salt}#{string}")
       end

       def make_salt
         secure_hash("#{Time.now.utc}#{password}")
       end
       
       def make_auth
         secure_hash("#{Time.now.utc}#{self.userid}")
       end

       def secure_hash(string)
         Digest::SHA2.hexdigest(string)
       end
end

DataMapper.auto_upgrade!