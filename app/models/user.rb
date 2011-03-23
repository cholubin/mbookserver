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
  property :publisher,          String #필명/출판사명
  property :email,              String
  property :tel,                String
  property :mobile,             String

  property :encrypted_password, String, :length => 150
  property :salt,               String, :length => 150
  property :remember_token,     Text,   :length => 150

  property :withdrawal_reason,  Text
  timestamps :at
  
  
  before :save, :encrypt_password
  before :update, :encrypt_password
  before :create, :pdf_path
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

       def secure_hash(string)
         Digest::SHA2.hexdigest(string)
       end
end
