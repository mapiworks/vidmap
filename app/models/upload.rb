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
 
class Upload < ActiveRecord::Base
	
	belongs_to :video
	
	#has_attachment :content_type => ['video/*'],
	#			 :storage => :file_system, 
	#			 :max_size => 500.megabytes,
	#			 :min_size => 50.bytes,
	#			 :path_prefix => 'videos'

	validates_acceptance_of :terms_accepted, :allow_nil => false, :accept => "YES"
	##attr_accessible :terms_accepted #virtual attribute behaves like true database attribute, necessary for access inside web/upload

	validates_presence_of :name, :size, :content_type
	##validates_uniqueness_of  :name, :scope => :user_id, :case_sensitive => false #Does not work in case of forgotten UPLOAD entries (& files) --> prepare macro in admin section
  	
	#validates_inclusion_of :movement_type, :in =>0..7, :message => "is not supported."
	
	#validates_as_attachment

  
	before_destroy :remove_assets 
	

	def remove_assets
		
		#Remove uploaded video file
		logger.debug "### Removing upload_id " + self.id.to_s + " for user_id " + self.user_id.to_s + " ###"
		begin
			
			#if File.exist?(self.full_filename.to_s)
			#	File.delete(self.full_filename.to_s)
			#	Dir.delete(self.full_filepath.to_s)
			#end
			
		rescue Exception => exc
			logger.debug "Removing of " + self.full_filename.to_s + " failed during upload.before_destroy(): #{exc.message}"
		end
	
	
		
		true
	end
	  
end
