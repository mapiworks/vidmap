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
 
class Polyline < ActiveRecord::Base

	belongs_to :user
	has_many :intersections
	has_many :routes
	has_many :waypoint, :through => :polyline_id#, :dependent => :destroy
	
	#def to_json
	 #self.attributes(:only =>[:id, :poly_points, :poly_levels, :poly_numLevels, :poly_zoomFactor]).to_json
	#end
	
	before_destroy :remove_unused_waypoints
	
	def remove_unused_waypoints
		Waypoint.destroy_all(["polyline_id = ?", self.id])
	end
	
  def to_s
    "{poly_numLevels:" + self.poly_numLevels.to_s + ", poly_levels:'" + self.poly_levels.to_s + "', poly_points:'" + self.poly_points.to_s + "', id:" + self.id.to_s + ", poly_zoomFactor:" + self.poly_zoomFactor.to_s + "},"
  end	
	
end
