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
 
class Video < ActiveRecord::Base

	belongs_to :user
	belongs_to :route
	has_one :upload
	
	
	#def to_json
	 #self.attributes(:only =>[:id, :video_id, :play_order, :polyline_id, :user_id, :name, :duration, :video_direction, :movement_type, :filename_flash, :start_at_distance, :end_at_distance, :at_distance, :distance]).to_json
	#end	
	
	before_destroy :remove_assets 
	
	def remove_assets
	
		#Remove associated Routes
		Route.destroy_all(["video_id = ?", self.id])
		
		#Remove associated Upload
		Upload.destroy_all(["id = ?", self.upload_id])
		
		#Remove video files and image
		logger.info "### Removing video_id " + self.id.to_s + " for user_id " + self.user_id.to_s + " ###"
		begin
			File.delete('/usr/lib/red5/webapps/vmStream/streams/' + self.filename_flash.to_s)
		rescue
			logger.info "Removing of " + self.filename_flash.to_s + " failed during video.before_destroy()."
		end
		begin
			File.delete('/usr/lib/red5/webapps/vmStream/streams/' + self.filename_flash.to_s + ".meta")
		rescue
			logger.info "Removing of " + self.filename_flash.to_s + ".meta failed during video.before_destroy() (video probably not played yet)."
		end
		
		begin
			File.delete('/usr/lib/red5/webapps/vmStream/streams/' + self.filename_thumb.to_s)
		rescue
			logger.info "Removing of " + self.filename_thumb.to_s + " failed during video.before_destroy()."
		end
		begin
			File.delete('/usr/lib/red5/webapps/vmStream/streams/' + self.filename_thumb.to_s + ".meta")
		rescue
			logger.info "Removing of " + self.filename_thumb.to_s + ".meta failed during video.before_destroy() (video probably not played yet)."
		end
		
		begin
			File.delete('/usr/lib/red5/webapps/vmStream/streams/' + self.filename_img.to_s)
		rescue
			logger.info "Removing of " + self.filename_img.to_s + " failed during video.before_destroy()."
		end
	
		
		true
	end

end
