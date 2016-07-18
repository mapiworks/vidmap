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
 
# encoding: UTF-8


class EditorController < ApplicationController
	
	require 'sanitize'
	layout "layouts/standard_editor", :except => [:update_track]


	## Session management
	before_filter :login_required#, :except => [:getPolylineFromVideoAS, :getVideoWithSyncAS] 

	## Referer management        					
	before_filter :check_valid_key_and_domain, :except => [:index] 
	before_filter :check_language, :only => [:get_translation, :save_video_params]
	
	def index
	end
	
	def get_translation
		 render :json => @vm_editor_translation_table.to_json  
	end
	
	def create_track
			
		if !params[:end_at_distance] || !params[:video_id] || !params[:encodedPoints] || !params[:encodedLevels] || !params[:numLevels] || !params[:zoomFactor] || !params[:bound_north] || !params[:bound_south] || !params[:bound_west] || !params[:bound_east] || !params[:maptype]
			render :json => {:error => "Failed. (Parameters set improperly on create_track)"}.to_json
			return false
		end
		
		#logger.info "session[:api_user_id]: " + current_user.id.to_s
		#logger.info "params[:video_id]: " + params[:video_id].to_s
		
		if !Video.exists?(["user_id = ? AND id = ?", current_user.id, params[:video_id]])
			render :json => {:error => "Not authorized. (Session error in create_track)"}.to_json
			return false	
		end
		
		if Route.where({:video_id => params[:video_id]}).exists?
			render :json => {:error => "Failed. (Route exists already)"}.to_json
			return false	
		end
		
		#############
		# Create polyline record (user_id, poly_points, poly_levels, poly_numLevels, poly_zoomFactor, bound_north, bound_west, bound_south, bount_east
		@polyline = Polyline.new(:user_id => current_user.id)
		
		@polyline.poly_points = params[:encodedPoints]
		@polyline.poly_levels = params[:encodedLevels]
		@polyline.poly_numLevels = params[:numLevels]
		@polyline.poly_zoomFactor = params[:zoomFactor]
		
		@polyline.bound_north = params[:bound_north]
		@polyline.bound_west = params[:bound_west]
		@polyline.bound_south = params[:bound_south]
		@polyline.bound_east = params[:bound_east]
		
		@polyline.save!
		
		#logger.info  "Success on polyline save! New polyline ID: " + @polyline.id.to_s
		
		
		
		###########
		# Create route record (video_id, play_order, polyline_id, video_direction, start_at_distance, end_at_distance)
		@route = Route.new()
		@route.video_id = params[:video_id]
		@route.polyline_id = @polyline.id
		
		@route.play_order = 0 #It's the first (and only) polyline piece of the route
		@route.video_direction = 1 #play polyline forward
		@route.start_at_distance = 0 #start at beginning of the polyline
		@route.end_at_distance = params[:end_at_distance] #span router over full polyline length
		
		@route.map_type = params[:maptype] #save map type

		# update geo-details
		@geocode = params[:geocode] #ActiveSupport::JSON.decode(params[:geocode])

		@route.start_placemark_de = @geocode["formatted_address_start"]
		@route.start_placemark_en = @geocode["formatted_address_start"]
		@route.end_placemark_de = @geocode["formatted_address_end"]
		@route.end_placemark_en = @geocode["formatted_address_end"]
		
		@geocode["start"]["0"].each { |key,code|
			case code["types"][0].downcase
				when "country"
					@route.start_country_code  	= 	code["short_name"]
					@route.start_country_de  	= 	code["long_name"]
					@route.start_country_en  	= 	code["long_name"]
				when "postal_code"
					@route.start_locality_code  = 	code["short_name"]
				when "locality"
					@route.start_locality_de  	= 	code["long_name"]
					@route.start_locality_en  	= 	code["long_name"]
			end
		}
		
		@geocode["end"]["0"].each { |key,code|
			case code["types"][0].downcase
				when "country"
					@route.end_country_code  	= 	code["short_name"]
					@route.end_country_de  		= 	code["long_name"]
					@route.end_country_en  		= 	code["long_name"]
				when "postal_code"
					@route.end_locality_code	= 	code["short_name"]
				when "locality"
					@route.end_locality_de  	= 	code["long_name"]
					@route.end_locality_en  	= 	code["long_name"]
			end
		}
			
		@route.save!
		
		#render :text => params[:waypoints].map{|index,item| item} and return
		
		############
		# Create waypoint record and link to route
		@waypoint = Waypoint.new()
		@waypoint.polyline_id = @polyline.id
		@waypoint.waypoints = params[:waypoints] #.map{|index,item| item}
		@waypoint.save!
		
		#logger.info  "Success on route save! New route ID: " + @route.id.to_s
		#render :text => 'Successfully saved route & video!'
		render :json => {:poly_id => @polyline.id, :video_id => @route.video_id}.to_json
		
		rescue ActiveRecord::RecordInvalid
			render :json => {:error => "RecordInvalid"}.to_json
		rescue Exception => exc
			render :json => {:error => "#{exc.message}"}.to_json
			
	end	
	
	def update_track
			
		if !params[:poly_id] || !params[:end_at_distance] || !params[:video_id] || !params[:encodedPoints] || !params[:encodedLevels] || !params[:numLevels] || !params[:zoomFactor] || !params[:bound_north] || !params[:bound_south] || !params[:bound_west] || !params[:bound_east] || !params[:maptype]
			render :json => {:error => "Not authorized. (Session error in update_track)"}.to_json
			return false
		end
		
		if !Video.exists?(["user_id = ? AND id = ?", current_user.id, params[:video_id]])
			render :json => {:error => "Not authorized. (Session error in update_track)"}.to_json
			return false	
		end

		if !Polyline.exists?(["user_id = ? AND id = ?", current_user.id, params[:poly_id]])
			render :json => {:error => "Not authorized. (Session error in update_track)"}.to_json
			return false	
		end
		
		################
		# update polyline record
		Polyline.update(params[:poly_id], { :poly_points => params[:encodedPoints], :poly_levels => params[:encodedLevels], :poly_numLevels => params[:numLevels], :poly_zoomFactor => params[:zoomFactor], :bound_north => params[:bound_north], :bound_west => params[:bound_west], :bound_south => params[:bound_south], :bound_east => params[:bound_east]})
		#logger.info  "Success on polyline update! Polyline ID: " + params[:poly_id].to_s
		
		################
		# update route record
		@route = Route.find(:first, :conditions => [ "polyline_id = ?", params[:poly_id] ])
		route_id = @route.id
		
		Route.update(route_id, { :video_id => params[:video_id], :end_at_distance => params[:end_at_distance], :map_type => params[:maptype]})
		#logger.info  "Success on route update! Route ID: " + route_id.to_s
	
		# update geo-details
		
		@geocode = params[:geocode]
		
		@route.start_placemark_de = @geocode["formatted_address_start"]
		@route.start_placemark_en = @geocode["formatted_address_start"]
		@route.end_placemark_de = @geocode["formatted_address_end"]
		@route.end_placemark_en = @geocode["formatted_address_end"]
		
		@geocode["start"]["0"].each { |key,code|
			case code["types"][0].downcase
				when "country"
					@route.start_country_code  	= 	code["short_name"]
					@route.start_country_de  	= 	code["long_name"]
					@route.start_country_en  	= 	code["long_name"]
				when "postal_code"
					@route.start_locality_code  = 	code["short_name"]
				when "locality"
					@route.start_locality_de  	= 	code["long_name"]
					@route.start_locality_en  	= 	code["long_name"]
			end
		}
		
		@geocode["end"]["0"].each { |key,code|
			case code["types"][0].downcase
				when "country"
					@route.end_country_code  	= 	code["short_name"]
					@route.end_country_de  		= 	code["long_name"]
					@route.end_country_en  		= 	code["long_name"]
				when "postal_code"
					@route.end_locality_code	= 	code["short_name"]
				when "locality"
					@route.end_locality_de  	= 	code["long_name"]
					@route.end_locality_en  	= 	code["long_name"]
			end
		}
			
		@route.save!
				
		############
		# Update waypoint record
		waypoint_id = Waypoint.find(:first, :conditions => [ "polyline_id = ?", params[:poly_id]])
		
		if !waypoint_id.nil?
			Waypoint.update(waypoint_id.id, {:waypoints => params[:waypoints]})
			#logger.info  "Success on waypoints update! Route ID: " + waypoint_id.id.to_s
		else
			@waypoint = Waypoint.new()
			@waypoint.polyline_id = params[:poly_id]
			@waypoint.waypoints = params[:waypoints]
			@waypoint.save!
		end
		
		################
		# update sync data
		#params[:syncdata]
		Syncronisation.delete_all(["route_id = ?", route_id]);
	
		#ActiveSupport::JSON.decode(params[:syncdata]).each{|item| 
		#	item["route_id"] = route_id
		#	Syncronisation.create(item); 
		#}
	
		render :json => {:poly_id => params[:poly_id], :video_id =>  params[:video_id]}.to_json
		#render :text =>@debugreturn
		
		rescue ActiveRecord::RecordInvalid
			render :json => {:error => "RecordInvalid"}.to_json
		
		rescue Exception => exc
			render :json => {:error => "#{exc.message}"}.to_json
			
	end
	
	def remove_track
		#Here we delete whole polylines. Change this towards deletion of single routes in case of multiple routes sharing one polyline
		#logger.info "remove track: " +  session[:poly_id].to_s
		
		if !params[:poly_id]
			render :text => "Failed. (Parameters set improperly on remove_track)"
			return false
		end
		
		if !Polyline.exists?(["user_id = ? AND id = ?", current_user.id, params[:poly_id]])
			render :text => "Not authorized. (Session error)"
			return false	
		end
		
		#Polyline.destroy(params[:poly_id].to_i)
		Route.destroy_all(["polyline_id = ?", params[:poly_id]])
		
		render :text => "removed " + params[:poly_id].to_s + " (including dependent routes)"
	end
	
	#This function returns videos and routes for a selected point on a polyline
	def getVideoFromPolylineAS
		
		if !params[:poly_id]
			render :text => "Failed. (Parameters set improperly)"
			return false
		end
		
		speed = Syncronisation.find_by_sql(["select time, distance from syncronisations where route_id in (select id from routes where polyline_id = ?) order by time", params[:poly_id]])
		route = Route.find(:first, :conditions => [ "polyline_id = ?", params[:poly_id] ]);
		
		render :json => {:video_id => route.video_id, :sync => speed}.to_json
	end
	
	def getVideoSpeedAS
		@video_speed = Syncronisation.find_by_sql(["select * from (select routes.id as route_id from (SELECT * FROM videos where id = ? and user_id = ?) as t1 inner join routes on t1.id = routes.video_id) as t2 inner join syncronisations on t2.route_id = syncronisations.route_id order by time", params[:video_id], current_user.id])
		render :json => {:video_id => params[:video_id], :sync => @video_speed}.to_json
	end
	
	def getVideoWithSyncAS
		@video = Video.find(:first, :conditions => [ "user_id = ? AND id = ?", current_user.id, params[:video_id]])
		@video_sync = Syncronisation.find_by_sql(["select * from (select routes.id as route_id from (SELECT * FROM videos where id = ? and user_id = ?) as t1 inner join routes on t1.id = routes.video_id) as t2 inner join syncronisations on t2.route_id = syncronisations.route_id order by time", params[:video_id], current_user.id])
		render :json => {:video => @video, :sync => @video_sync}.to_json
	end
	
	def getPolylinesAS
		#logger.info "getPolylinesAS for current_user.id = " +  current_user.id.to_s
		
		bound_west = Polyline.minimum('bound_west', :conditions => {:user_id => current_user.id} )
		bound_east = Polyline.maximum('bound_east', :conditions => {:user_id => current_user.id} )
		bound_north = Polyline.maximum('bound_north', :conditions => {:user_id => current_user.id} )
		bound_south = Polyline.minimum('bound_south', :conditions => {:user_id => current_user.id} )   
		
		render :json => {:bounds => {:west => bound_west, :east => bound_east, :north => bound_north, :south => bound_south}, :polylines => Polyline.find_by_sql(["SELECT polylines.id, poly_points, poly_zoomFactor, poly_levels, poly_numLevels,video_id FROM polylines inner join routes on polylines.id = routes.polyline_id where user_id=?", current_user.id])}.to_json
	end
	
	def getPolylineFromVideoAS
		#logger.info "getPolylinesFromVideoAS for current_user.id = " +  current_user.id.to_s
		
		bound = Polyline.find_by_sql(["SELECT map_type, bound_west, bound_east, bound_south, bound_north FROM polylines inner join routes on polylines.id = routes.polyline_id where user_id=? AND video_id=? LIMIT 1", current_user.id, params[:video_id]])
		render :json => {:maptype => bound[0].nil? ? false : bound[0].map_type, :bounds => bound[0].nil? ? false : {:west =>bound[0].bound_west, :east => bound[0].bound_east, :north => bound[0].bound_north, :south => bound[0].bound_south},  :polylines => Polyline.find_by_sql(["SELECT user_id, polylines.id, poly_points, poly_zoomFactor, poly_levels, poly_numLevels, video_id FROM polylines inner join routes on polylines.id = routes.polyline_id where user_id=? AND video_id=? LIMIT 1", current_user.id, params[:video_id]])}.to_json
	end
	
	def getWaypointsAS
		#logger.info "getWaypointsAS for current_user.id = " +  current_user.id.to_s		
		
		render :json => Waypoint.find_by_polyline_id(params[:poly_id]).to_json
	end
	
	def getWaypointsByVideoAS
		#logger.info "getWaypointsByVideoAS for current_user.id = " +  current_user.id.to_s		
		
		render :json => Waypoint.find_by_sql(["SELECT * from (SELECT polyline_id as id FROM polylines inner join routes on polylines.id = routes.polyline_id where user_id = ? AND video_id = ? limit 1) as tPoly inner join waypoints where tPoly.id = waypoints.polyline_id", current_user.id, params[:video_id]])[0].to_json
	end
	
	def set_aspect(aspect, video_id)
		
		if aspect && video_id
			case aspect
				when "1:1"
					@DARX = 1
					@DARY = 1
					aspect_str = "1:1"
				when "4:3"
					@DARX = 4
					@DARY = 3
					aspect_str = "4:3"
				when "16:9"
					@DARX = 16
					@DARY = 9
					aspect_str = "16:9"
				when "16:10"
					@DARX = 16
					@DARY = 10
					aspect_str = "16:10"
				when "8:3"
					@DARX = 8
					@DARY = 3
					aspect_str = "8:3"
				when "5:4"
					@DARX = 5
					@DARY = 4
					aspect_str = "5:4"
				when "192:157"	
					@DARX = 192
					@DARY = 157
					aspect_str = "192:157"	
				else 
					@DARX = 4
					@DARY = 3
					aspect_str = "4:3"
			end
			
			Video.update_all(["DARX = ?, DARY = ?", @DARX, @DARY], ["user_id = ? AND id = ?", current_user.id, video_id])
			
			return aspect_str
		end

		#redirect_to(:controller => '/web', :action => 'videos')
	end
	
	def save_video_params
		
		#render :json => params and return
		
		if params[:video_place_description] && params[:video_id] && logged_in? && current_user.has_role?("ADMIN")
			
			@route = Route.find_by_sql(["select * from videos inner join routes on routes.video_id = videos.id where videos.id = ? LIMIT 1", params[:video_id]])[0]
			
			if !@route.nil?
			
				content = Content.update_all(["content = ?", params[:video_place_description]], ["country = ? AND city = ?", @route.start_country_en, @route.start_locality_en])
				
				if content == 0
					content = Content.create({:content => params[:video_place_description], :country => @route.start_country_en,  :city => @route.start_locality_en})
				end
			
			end
			
			render :layout => false, :inline => params[:video_place_description] and return
		end
		 
		if params[:video_name]
			
			params[:video_name] = Sanitize.clean(params[:video_name]).strip[0..62]
			
			if params[:video_name] === ""
				params[:video_name] = Video.find(:first, :conditions => [ "user_id = ? AND id = ?", current_user.id, params[:video_id]]).name
			end
				
			Video.update_all(["name = ?", params[:video_name]], ["user_id = ? AND id = ?", current_user.id, params[:video_id]])
			
			render :layout => false, :inline => params[:video_name]
			return
		end
		
		if params[:video_description]
			
			params[:video_description] = Sanitize.clean(params[:video_description])
			
			if params[:video_description] === ""
				params[:video_description] = Video.find(:first, :conditions => [ "user_id = ? AND id = ?", current_user.id, params[:video_id]]).description
			end
				
			Video.update_all(["description = ?", params[:video_description]], ["user_id = ? AND id = ?", current_user.id, params[:video_id]])
			
			render :layout => false, :inline => params[:video_description]
			return
		end
		
		if params[:video_public]
				params[:video_public] = Sanitize.clean(params[:video_public]).strip[0..12]
				
				if params[:video_public] === "private"
					Video.update_all(["public = ?", 0], ["user_id = ? AND id = ?", current_user.id, params[:video_id]])
					@privacy = @vm_string_table[:private]
					#render :layout => false, :inline => @vm_string_table[:private]
				else
					Video.update_all(["public = ?", 1], ["user_id = ? AND id = ?", current_user.id, params[:video_id]])	
					@privacy = @vm_string_table[:public]
					#render :layout => false, :inline => @vm_string_table[:public]
				end
				
				
				@video = Video.find_by_id(params[:video_id])
				@isPublic = @video.public ?  true : false
				@isOwner = @video.user_id == current_user.id ?  true : false
				
				@route = Route.find_by_sql(["select * from videos inner join routes on routes.video_id = videos.id where videos.id = ? LIMIT 1", params[:video_id]])[0]
				@hasRoute = !@route.nil?
				
				@api_key = Api.find_by_user_id(User.find_by_role("SYSTEM").id, :order => "id desc").key
				
				if @isOwner
					@private_api_key = Api.find_by_user_id(current_user.id)
					@private_api_key = @private_api_key ? @private_api_key.key : nil
				else 
					@private_api_key = nil
				end
		
		
				@sidebar_embed = render_to_string :layout => false, :template => "web/sidebar_embed_"+ @vm_language
				#render :json => {:sidebar_embed =>  @sidebar_embed, :privacy_string => @privacy}.to_json  
				render :text => @privacy
				
				return
		end
		
		if params[:video_aspect]
				params[:video_aspect] = Sanitize.clean(params[:video_aspect]).strip[0..8]
				
				aspect_str = set_aspect(params[:video_aspect], params[:video_id])
				
				render :layout => false, :inline => aspect_str
				
				return
		end
		
		if params[:video_movement]
				params[:video_movement] = Sanitize.clean(params[:video_movement]).strip[0..12]
				
				if !["car", "bike", "plane", "foot", "moto", "ship", "train", "misc"].include?(params[:video_movement])
					params[:video_movement] = "misc"
				end
				
				Video.update_all(["movement_type = ?", params[:video_movement]], ["user_id = ? AND id = ?", current_user.id, params[:video_id]])
				
				case params[:video_movement]
				when "car"
					render :layout => false, :inline => @vm_string_table[:movement_car]
				when "bike"
					render :layout => false, :inline => @vm_string_table[:movement_bike]
				when "plane"
					render :layout => false, :inline => @vm_string_table[:movement_plane]
				when "foot"
					render :layout => false, :inline => @vm_string_table[:movement_foot]
				when "moto"
					render :layout => false, :inline => @vm_string_table[:movement_moto]
				when "ship"
					render :layout => false, :inline => @vm_string_table[:movement_ship]
				when "train"
					render :layout => false, :inline => @vm_string_table[:movement_train]
				else
					render :layout => false, :inline => @vm_string_table[:movement_misc]
				end
				return
		end
		
		
		render :json => params and return
		
		rescue Exception => exc
			render :layout => false, :inline =>"#{exc.message}"
	end
	
end
