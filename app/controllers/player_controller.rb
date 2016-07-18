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

class PlayerController < ApplicationController
	layout "layouts/standard_player"
	
	## Referer management                                                   
	
	before_filter :check_valid_key_and_domain	#, :except => [:getSelectedVideosAS]
	before_filter :check_language, :only => [:get_translation]

	
	def get_translation
		 render :json => @vm_player_translation_table.to_json  
	end
	
	def getSelectedPolylinesAS
		#logger.info "getPolylinesAS for session[:api_user_id] = " +  session[:api_user_id].to_s

		
		
		if params[:videos] && !params[:videos].blank?
			
			#render :json => session[:api_user_id] and return
			
			@selectedVideos = ActiveSupport::JSON.decode(params[:videos])
						
			#@video = Video.find(@selectedVideos[0]) 
			#@isOwner = @video && current_user && @video.user_id == current_user.id ?  true : false
			#videoowner = User.find_by_id(session[:api_user_id])
			
			@selectedRoutes = Route.where({:video_id => @selectedVideos[0]})
			
			
			if @selectedRoutes.length > 0
				#Deliver selected polylines fitting to the current api user ID or fitting to public videos
					
				@polys = Polyline.find_by_sql(["SELECT polylines.id, poly_points, poly_zoomFactor, poly_levels, poly_numLevels,video_id FROM polylines inner join routes on polylines.id = routes.polyline_id inner join users on users.id = polylines.user_id where users.blocked = 0 AND ((user_id=? AND routes.id in (?)) OR routes.id in (SELECT routes.id FROM routes inner join videos on video_id = videos.id where routes.id in (?) AND videos.public = 1))", session[:api_user_id], @selectedRoutes, @selectedRoutes])
				
				@speed = Syncronisation.find_by_sql(["select time, distance from syncronisations where route_id in (select id from routes where polyline_id = ?) order by time", @polys[0].id])
				
				@bounds = Polyline.find_by_sql(["SELECT Min(bound_west) as min_bound_west, Max(bound_east) as min_bound_east, Max(bound_north) as min_bound_north, Min(bound_south) as min_bound_south from polylines inner join routes on polylines.id = routes.polyline_id where (user_id=? AND routes.id in (?)) OR routes.id in (SELECT routes.id FROM routes inner join videos on video_id = videos.id where routes.id in (?) AND videos.public = 1)", session[:api_user_id], @selectedRoutes, @selectedRoutes])
				@maptype = Route.find_by_sql(["SELECT map_type from routes where routes.id in (?)", @selectedRoutes])
				
				render :json => {:route_available => true, :video_id => @selectedVideos[0], :poly_id => @polys[0].id, :api_user_id => session[:api_user_id], :maptype => @maptype[0].map_type, :bounds => {:west => @bounds[0].min_bound_west, :east => @bounds[0].min_bound_east, :north => @bounds[0].min_bound_north, :south => @bounds[0].min_bound_south}, :polylines => @polys, :sync => @speed}.to_json
			else
				render :json => {:route_available => false, :video_id => @selectedVideos[0], :api_user_id => session[:api_user_id]}.to_json
			end
		end
		
		
	end
	
	def getVideoSpeedAS
		#logger.info "getVideoSpeedAS for session[:api_user_id] = " +  session[:api_user_id].to_s
		@video_speed = Syncronisation.find_by_sql(["select * from (select routes.id as route_id from (SELECT * FROM videos where id = ? and (user_id = ? or public = 1)) as t1 inner join routes on t1.id = routes.video_id) as t2 inner join syncronisations on t2.route_id = syncronisations.route_id order by time", params[:video_id], session[:api_user_id]])
		render :json => {:video_id => params[:video_id], :sync => @video_speed}.to_json
	
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
	
	def getVideoAS
		
		if !params[:video_id]
			render :json => {:error => "Missing parameter"}
			return false
		end
		
		#speed = Syncronisation.find_by_sql(["select time, distance from syncronisations where route_id in (select id from routes where polyline_id = ?) order by time", params[:poly_id]])
		#route = Route.find(:first, :conditions => [ "polyline_id = ?", params[:poly_id] ]);
		
		#render :json => {:video_id => route.video_id, :sync => speed, :video => Video.find(route.video_id)}.to_json
		
		render :json => {:video => Video.find(params[:video_id])}.to_json
	end
	
	def getAllVideosAS		
		@videos = Video.find(:all, :conditions => [ "user_id = ?", session[:api_user_id]])
		 render :json => @videos.to_json  
	end
	
	def getSelectedVideosAS	
		
		#render :text => (session[:valid_api_key] & session[:api_user_id]) and return
		
		if params[:routes] && !params[:routes].blank?
			
			#myDebug "getSelectedVideosAS --> params[:routes]: " + params[:routes]
			@routes = ActiveSupport::JSON.decode(params[:routes])
			
			if @routes && @routes.length > 0
				# Grab Videos by route IDs, conditions: api user ID fits to video owner OR video is set public
				@videos = Route.find_by_sql(["SELECT user_id, routes.id as routes_id, videos.id as id, videos.public, name, filename_flash, duration, width, height, DARX, DARY, PARX, PARY, filename_img  FROM routes inner join videos on routes.video_id = videos.id inner join users on users.id = videos.user_id where users.blocked = 0 AND videos.blocked = 0 AND (user_id = ? OR videos.public = 1) AND routes.id in (?)", session[:api_user_id],  @routes])
			else
				@videos = Route.find_by_sql(["SELECT user_id, routes.id as routes_id, videos.id as id, videos.public, name, filename_flash, duration, width, height, DARX, DARY, PARX, PARY, filename_img  FROM routes inner join videos on routes.video_id = videos.id inner join users on users.id = videos.user_id where users.blocked = 0 AND videos.blocked = 0 AND videos.public = 1 order by rand() limit 1"])
				#@videos = Video.find(:all, :conditions => [ "user_id = ?", session[:api_user_id]])
			end
			
		else
			@videos = Route.find_by_sql(["SELECT user_id, routes.id as routes_id, videos.id as id, videos.public, name, filename_flash, duration, width, height, DARX, DARY, PARX, PARY, filename_img  FROM routes inner join videos on routes.video_id = videos.id inner join users on users.id = videos.user_id where users.blocked = 0 AND videos.blocked = 0 AND videos.public = 1 order by rand() limit 1"])
			#@videos = Video.find(:all, :conditions => [ "user_id = ?", session[:api_user_id]]) 
		end
			
		 render :json => @videos.to_json  
	end
	
	def getJoints
		
		@js_return_var = params[:js_return_var]
		
		render :update do |page|
		   page.assign @js_return_var, Joint.find_by_sql(["select * from joints inner join (select joint_id from intersections inner join (select polylines.id as poly_id from polylines inner join users on users.id = polylines.user_id where users.id=?) as my_polys on intersections.polyline_id = my_polys.poly_id) as my_joints on joints.id = my_joints.joint_id", session[:api_user_id]])
  		end
		
		#render_text Joint.find_by_sql(["select * from joints inner join (select joint_id from intersections inner join (select polylines.id as poly_id from polylines inner join users on users.id = polylines.user_id where users.id=?) as my_polys on intersections.polyline_id = my_polys.poly_id) as my_joints on joints.id = my_joints.joint_id", session[:api_user_id]]).to_json
	end	
	
	def getVideofromPolyline
	
		@js_return_var = params[:js_return_var]
		
		@polyline_id = params[:polyline_id]
		@atDistance = params[:atDistance]
		
		#@video = Video.find_by_sql(["select * from videos inner join routes on videos.id = routes.video_id where polyline_id=? and ? between start_at_distance and end_at_distance", @polyline_id, @atDistance])
		@video = Video.find_by_sql(["select * from routes inner join videos on routes.video_id = videos.id where videos.user_id = ? and video_id in (select video_id from routes where polyline_id=? and ? between start_at_distance and end_at_distance) order by play_order", session[:api_user_id], @polyline_id, @atDistance])
		
		render :update do |page|
		    page.assign @js_return_var, @video
		end
					
		#render_text @video.to_json
	end
	
	def getVideofromJoint
		@joint_id = params[:joint_id]
		@js_return_var = params[:js_return_var]
		
		@video = Video.find_by_sql(["select id, user_id, play_order, polyline_id, start_at_distance, end_at_distance, at_distance, video_direction, videos.filename_flash as filename_flash, videos.duration as duration, videos.name as name, videos.movement_type as movement_type from videos inner join (select video_id, routes.polyline_id, start_at_distance, end_at_distance, at_distance, video_direction, play_order from routes inner join intersections on routes.polyline_id = intersections.polyline_id where joint_id=? and (routes.video_direction > 0 and intersections.at_distance >= routes.start_at_distance and intersections.at_distance < routes.end_at_distance or routes.video_direction < 0 and intersections.at_distance > routes.start_at_distance and intersections.at_distance <= routes.end_at_distance)) as routevids on videos.id = routevids.video_id where user_id = ?", @joint_id, session[:api_user_id]])
		
		render :update do |page|
		    page.assign @js_return_var, @video
		end
		
		#render_text @video.to_json
	end

	def getRouteData
		@video_id = params[:video_id]
		@js_return_var = params[:js_return_var]
		
		@route_data = Route.find_by_sql(["select * from routes where video_id in (select id from videos where id = ? and user_id = ?) order by play_order", @video_id, session[:api_user_id]])
		#find(:all, :conditions => { :video_id => @video_id }, :order => "play_order")
		
		render :update do |page|
		    page.assign @js_return_var, @route_data
		end

		#render_text @route_data.to_json
	end
	
	#def getMultiRouteData #
	#	@video_ids = JSON.parse(params[:video_id])
	#	
	#	@route_data = Route.find(:all, :conditions => { :video_id => @video_ids }, :order => "play_order")
	#
	#	render_text @route_data.to_json
	#end	

	def getVideoSpeed
		
		@js_return_var = params[:js_return_var]
		@video_id = params[:video_id]
		@video_speed = Syncronisation.find_by_sql(["select * from syncronisations where video_id in (select id from videos where id = ? and user_id = ?) order by time", @video_id, session[:api_user_id]])
		#find(:all, :conditions => { :video_id => @video_id }, :order => "time")

		render :update do |page|
		    page.assign @js_return_var, @video_speed
		end
		
		#render_text @video_speed.to_json
	end
	
	def getVideoInfo
		@js_return_var = params[:js_return_var]
		@video_id = params[:video_id]
		@video_info = Video.find(:first, :conditions => { :id => @video_id, :user_id => session[:api_user_id]})

		render :update do |page|
		    page.assign @js_return_var, @video_info
		end
				
		#render_text @video_info.to_json
	end
	
	def getNearbyVideos
		@js_return_var = params[:js_return_var]
		@current_video_id = params[:current_video_id]
		@pointOfInterestLat = params[:pointOfInterestLat]
		@pointOfInterestLng = params[:pointOfInterestLng]
		@video_ids = Array.new
		
		#@nearbyVideos = Video.find_by_sql(["select video_id, user_id, movement_type, filename_flash, distance from videos inner join (select video_id, distance from routes inner join (select polyline_id, joint_distances.distance from intersections inner join (select id,SQRT(pow(lat-?,2)+pow(lng-?,2)) as distance from joints) as joint_distances on joint_distances.id=joint_id group by polyline_id order by distance limit 4) as polyline_distances on polyline_distances.polyline_id = routes.polyline_id where video_id!=?) as video_distances on video_distances.video_id = videos.id where user_id = ?", @pointOfInterestLat, @pointOfInterestLng,  @current_video_id, session[:api_user_id]])
		@nearbyVideos = Video.find_by_sql(["select video_id, user_id, movement_type, filename_flash, distance from videos inner join (select video_id, distance from routes inner join (select polyline_id, joint_distances.distance from intersections inner join (select id,SQRT(pow(lat-?,2)+pow(lng-?,2)) as distance from joints) as joint_distances on joint_distances.id=joint_id group by polyline_id order by distance limit 4) as polyline_distances on polyline_distances.polyline_id = routes.polyline_id) as video_distances on video_distances.video_id = videos.id where user_id = ?", @pointOfInterestLat, @pointOfInterestLng, session[:api_user_id]])

		@nearbyVideos.each { |item|
			@video_ids.push(item.video_id);
		}
		
		#render_text @video_ids.to_json
		
		@route_data = Route.find(:all, :conditions => { :video_id => @video_ids }, :order => "play_order")
	
		render :update do |page|
		    page.assign @js_return_var, [:videos=>@nearbyVideos, :routes=>@route_data]
		end
		
		#render_text [:videos=>@nearbyVideos, :routes=>@route_data].to_json
	end
	
	
	def stats
		
		params[:type] = params[:type].nil? ? nil : params[:type].strip[0..32].to_s
		params[:video_id]  = params[:video_id].nil? ? false : params[:video_id].strip[0..16].to_s
		
		
		
		case params[:type]
			when "playback"
				
				@views_per_session = !params[:video_id] || session["stats_playback_" + params[:video_id]].nil? ? 0 : session["stats_playback_" + params[:video_id]].to_i
				
				if params[:video_id] && @views_per_session < 25
					Video.update_all("times_played=times_played+1, latest_playback = NOW()", ["id=?", params[:video_id]])
					session["stats_playback_" + params[:video_id]] = @views_per_session + 1
					render :text => "Event " + params[:type] + " recorded!", :layout => false				
					return
				end
		end
		
		render :text => "Event " + params[:type] + " was not recorded.", :layout => false
	end
	
##############	
##### OBSOLETE##


end
