 # The MIT License (MIT)
 # Copyright (c) 2014 MAPI.WORKS - Mario Pilz
 # URL: www.mapiworks.com
 # MAIL: mario@mapiworks.com
 #
 # Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 # to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 # and/or sell copies of  the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 # The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 # FITNESS FOR  A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
 # IN THE  SOFTWARE.
 
require 'digest/sha1'
class User < ActiveRecord::Base
  
	has_many :apis #, :through => :user_id#, :dependent => :destroy
	has_many :videos, :through => :user_id#, :dependent => :destroy # zerstört routes (zerstört polylines), uploads
	
	
  # Virtual attribute for the unencrypted password
  attr_accessor :password

  validates_presence_of     	:login, :email, :if => Proc.new { |user| user.service == "vidmap"}
  validates_presence_of     	:password,                   :if => :password_required? && Proc.new { |user| user.service == "vidmap"}
  validates_presence_of     	:password_confirmation,      :if => :password_required? && Proc.new { |user| user.service == "vidmap"}
  validates_length_of       	:password, :within => 4..16, :if => :password_required? && Proc.new { |user| user.service == "vidmap"}
  validates_confirmation_of :password,                   :if => :password_required? && Proc.new { |user| user.service == "vidmap"}
  validates_length_of       	:login,    :within => 3..16, :if => Proc.new { |user| user.service == "vidmap"}
  validates_length_of      		:email,    :within => 3..45, :if => Proc.new { |user| user.service == "vidmap"}
  validates_uniqueness_of   :login, :case_sensitive => false, :if => Proc.new { |user| user.service == "vidmap"}

  before_save :set_user_variables
  before_destroy :remove_assets 
  
  def remove_assets
	
		#Remove associated Routes
		Api.destroy_all(["user_id = ?", self.id])
		
		#Remove associated Upload
		Video.destroy_all(["user_id = ?", self.id])
		
  end	


  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login_and_service(login, "vidmap") # need to get the salt
    u && u.authenticated?(password) && !u.blocked && u.activated ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 10.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end

  # Save login date
  def set_last_login_date
    self.last_login = Time.now
	save(:validate => false)
  end
	
	# Save upload error
  def save_latest_upload_error(message)
    self.upload_errors_latest = message.to_json
	self.upload_errors_count = self.upload_errors_count + 1
	save(:validate => false)
  end
	
	# Get the users specific role
	def get_role
		self.role
	end
	
	# Get activation statue
	def activated?
		self.activated
	end
		
	# Check for presence of a specific role
	def has_role?(the_role)
		the_role==self.role ? true : false
	end
	
	def has_video?(video_id)
		Video.find_by_id_and_user_id(video_id.to_i, self.id) ? true : false;	
	end
	
  protected
    # before filter 
	def set_user_variables
		encrypt_password
		
		if  new_record?
			self.blocked = 0
			self.activated = 0
			self.role = "USER"
			self.activation_code = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{email}--") 
		end
	end
	
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
    
    def password_required?
      crypted_password.blank? || !password.blank?
    end
		

end
