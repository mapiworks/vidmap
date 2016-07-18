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

class ApiController < ApplicationController

	## Session management                                                   
	#before_filter :login_required                                           
	
	## Referer management        					
	before_filter :check_valid_key_and_domain, :except => [:index]
	before_filter :check_language, :only => [:index]
	
	#session :off, :only => [:send_flash_file] 
																			
	def authorized?                                                         
			#current_user ? current_user.has_role?("admin") : false          
	end  
  
	def index

		@api_key = params[:vmkey]
		@api_app = params[:vmapp]
		@api_design = params[:vmdesign].nil? ? "" : params[:vmdesign]
		
		@server_name = request.referer.nil? ? "" : request.referer.downcase.gsub(/.*\/\//, '').gsub(/www\./, '').gsub(/\/.*/, '').gsub(/:.*/, '')
		#@server_name = request.referer.downcase.gsub(/.*\/\//, '').gsub(/www\./, '').gsub(/:.*/, '')
		
		if (@api_key || @server_name.include?("vidmap.de")) && request.referer && @api_app
		
			if @server_name.include?("vidmap.de")
				# home base
				@api_record = Api.find(:first, :conditions => { :key => @api_key})
			else
				# somewhere else
				#@api_record = Api.find_by_key_and_server(@api_key, @server_name) 
				@api_record = Api.find_by_key(@api_key) 
				
				if @api_record && @server_name === @api_record.server
					# api key fits to server
				elsif @api_record && User.find_by_id(@api_record.user_id).role.upcase === "SYSTEM"
					# public api key used
				
				else
					# invald api key
					@api_record = nil
				end
			end
			
			@api_valid_key = @api_record? "true" : "false"
			@api_adsense_channel = @api_record? @api_record.channel : ""
			@api_user_id = @api_record? @api_record.user_id.to_s : "false"
			
			
			if @api_app == "editor_html5" && current_user
				# user id used for editor mode
				@api_user_id = current_user.id
			end
			
			if @api_valid_key
				session[:valid_api_key] = @api_valid_key
				session[:api_user_id] = @api_user_id
				session[:api_adsense_channel] = @api_adsense_channel 
				
				cookies[:valid_api_key] = { :value => @api_valid_key, :expires => 1.year.from_now, :domain => ".vidmap.de"}
				cookies[:api_user_id] = { :value => @api_user_id, :expires => 1.year.from_now, :domain => ".vidmap.de"}
				cookies[:api_adsense_channel] = { :value => @api_adsense_channel, :expires => 1.year.from_now, :domain => ".vidmap.de"}
				
				#render :json => {}
				
				if @api_app === "player_html5"
					render :text => 'function result(){var player = "player_html5"}'
					
				elsif @api_app === "editor_html5"
					render :text => 'function result(){var player = "editor_html5"}'
					
				elsif @api_app === "editor_single"
		
					case @api_design
					when "youtube"
						send_file(Rails.root.to_s + "/app/views/api/editor_single_youtube.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'e'+Time.now.to_formatted_s(:number)+'.css' )
					else
						send_file(Rails.root.to_s + "/app/views/api/editor_single.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'e'+Time.now.to_formatted_s(:number)+'.css' )
					end
						
				else
			
					case @api_design
					when "youtube"
						send_file(Rails.root.to_s + "/app/views/api/player_youtube.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					when "youtube_tdmv"
						send_file(Rails.root.to_s + "/app/views/api/player_topdown_map_video_youtube.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					when "youtube_tdmv16"
						send_file(Rails.root.to_s + "/app/views/api/player_topdown_map_video_wide_youtube.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					when "tdmv"
						send_file(Rails.root.to_s + "/app/views/api/player_topdown_map_video.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					when "tdmv16"
						send_file(Rails.root.to_s + "/app/views/api/player_topdown_map_video_wide.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					else
						send_file(Rails.root.to_s + "/app/views/api/player.swf", :type => 'application/x-shockwave-flash', :stream => true, :status => "200 OK", :disposition => 'inline', :filename => 'p'+Time.now.to_formatted_s(:number)+'.swf' )
					end
					
				end
				
			else
				cookies.delete(:valid_api_key, :domain => ".vidmap.de")
				cookies.delete(:api_user_id, :domain => ".vidmap.de")
				session[:valid_api_key] = false
				session[:api_user_id] = false
				render :text => "Wrong host: " + @server_name, :layout => false, :content_type => 'text/html'
			end
	
		else
			cookies.delete(:valid_api_key, :domain => ".vidmap.de")
			cookies.delete(:api_user_id, :domain => ".vidmap.de")
			session[:valid_api_key] = false
			session[:api_user_id] = false
			render :text => "Invalid parameters!", :layout => false, :content_type => 'text/html'
			
		end	  
	
	end

end
