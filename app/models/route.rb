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
 
class Route < ActiveRecord::Base

	has_one :video
	belongs_to :polyline
	has_many :syncronisations, :through => :route_id#, :dependent => :destroy
	
	#def to_json
	 #self.attributes(:only =>[:id, :video_id, :play_order, :polyline_id, :video_direction, :start_at_distance, :end_at_distance]).to_json
	#end	
	
	before_destroy :remove_unused_polylines
	
	#Here we assume a 1:1 relation between route and polyline.
	def remove_unused_polylines
		#Polyline.delete(self.polyline_id)
		Polyline.destroy_all(["id = ?", self.polyline_id])
		
		Syncronisation.destroy_all(["route_id = ?", self.id])
		
		#Polyline.find(:all, :conditions => ["video_id = ?", self.id]).each { |object| object.destroy }
	end

end
