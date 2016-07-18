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

 
class WebController < ApplicationController

	require 'sanitize'  
		
	layout "layouts/standard", :except => [:feed, :sidebar_listing, :get_youtube_video_data, :check_video_health, :embed, :embed_upgrade]
  
	before_filter :login_required, :except => [:index, :get_youtube_video_data, :forum, :disclaimer, :terms, :set_language, :image, :video, :video_listing, :sidebar_listing, :feed, :help, :about, :new, :check_video_health, :send_comment, :impressum, :embed, :embed_upgrade]
	before_filter :login_from_cookie, :only => [:index, :disclaimer, :terms, :video, :video_listing, :help, :welcome, :account, :embed_upgrade]
	before_filter :check_language, :except => [:set_language, :image]
	
	session :off, :only => [:image] 
  	
	SQL_GET_ALL_USER_VIDEOS = "select result.start_locality_en, result.end_locality_en, result.start_country_en, result.end_country_en, result.start_locality_de, result.end_locality_de, result.start_country_de, result.end_country_de, upload_id, youtube, times_played, result.id as id, result.name, public, result.movement_type, result.duration, filename_img, result.route_id as route_id, result.user_id as user_id, result.DARX, result.DARY, distance, DATEDIFF(now(), submitted_at) as existance_days from (select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, upload_id, youtube, times_played, videos.id as id, name, public, movement_type, duration, filename_img, routes.id as route_id, videos.user_id as user_id, DARX, DARY, end_at_distance as distance from videos left join routes on videos.id = routes.video_id group by videos.id) as result inner join uploads on uploads.id = result.upload_id having result.user_id = ? order by result.name"
	
	def isAdmin?                                                         
		if logged_in? && current_user.has_role?("ADMIN")
			return true
		else
			return false
		end        
	end  
	
	## replace old flash code
	def embed_upgrade
		
		@top_level_domain = ENV['RAILS_ENV'] == 'development' ? 'dev' : 'www'
		
		@video_id = Route.find(params[:route_id]).video_id

		@vmkey = (params[:loader_url].to_s.match /vmkey=(.*)/).to_s.gsub("vmkey=","")
	end
		
	## Define a home action, this is where /config/routes.rb should point to normally
	def index
		
		#session[:test] = "xxx"
		#render :text => session[:valid_api_key] and return 
		
		@menuItem = "home"
		
		#if request.fullpath.include?("/lang/")
		#	redirect_to("/")
		#	return
		#enA
		
		if params[:route]
			result = Route.find_by_sql(["select video_id from routes where id = ? limit 1", params[:route]])
			redirect_to(:action => 'video', :video_id => result[0].video_id) and return if (result && result.length == 1 && result[0].video_id)
		end
		
		session[:return_to] = request.fullpath
		@page_title = @vm_string_table[:web_title_index]
		
		flash[:login] ? @login_message = flash[:login] : @login_message = ""
	
		#New tracks
		@videos_new = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, submitted_at, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by submitted_at desc limit 4")
	
		#Popular tracks
		@videos_popular = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, times_played/(DATEDIFF(now(), submitted_at)+1) as performance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by performance desc limit 4")
		
		#Recently played
		@videos_recently = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on videos.upload_id = uploads.id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by latest_playback desc limit 4")
	
		#Random route
		@random_route = Route.find_by_sql("SELECT videos.youtube, times_played, routes.id as route_id FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by rand() limit 1")[0]
		
		#Slider
		@slider = Video.find_by_sql("select * from (SELECT content, start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, times_played/(DATEDIFF(now(), submitted_at)+1) as performance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id inner join contents on contents.city like end_locality_en where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by performance desc limit 20) tab order by rand()")
		#######
				
		render :action => 'startpage_'+@vm_language
	end 
	
	def about
		session[:return_to] = request.fullpath
		render :action => 'about_'+@vm_language
	end
	
	def impressum
		session[:return_to] = request.fullpath
		render :action => 'impressum_de'
	end
	
	def welcome
		session[:return_to] = request.fullpath
		render :action => 'welcome_'+@vm_language
	end
	
	def help
		session[:return_to] = request.fullpath
		render :action => 'help_'+@vm_language
	end
	
	def feed
		@new_videos = Video.find_by_sql("SELECT videos.id as video_id, videos.duration, videos.name as title, end_at_distance as distance, DATE_FORMAT(submitted_at,'%a, %d %b %Y %H:%i:%S GMT') as submission_date, users.login as user_name, videos.movement_type, start_locality_" + @vm_language + " as start_locality, end_locality_" + @vm_language + " as end_locality, start_country_" + @vm_language + " as start_country, end_country_" + @vm_language + " as end_country FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 order by submitted_at desc limit 10")
		@top_level_domain = ENV['RAILS_ENV'] == 'development' ? 'dev' : 'www'
		render :action => 'feed_'+@vm_language
	end
	
	def video_listing
		
		@page_title = @vm_string_table[:web_title_search]
		
		session[:return_to] = request.fullpath
		
		params[:sort] ? @sort = params[:sort] : @sort = "recent"
		
		case @sort
			when "recent"
				@video_list = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on videos.upload_id = uploads.id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by latest_playback desc limit 16")
				@heading = @vm_string_table[:video_listing_recent]
				@page_description = @heading
			when "new"
				@video_list = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, submitted_at, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 AND videos.disabled = 0 and videos.visible = 1 order by submitted_at desc limit 16")
				@heading = @vm_string_table[:video_listing_new]
				@page_description = @heading
			when "popular"
				@video_list = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, times_played/(DATEDIFF(now(), submitted_at)+1) as performance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by performance desc limit 16")
				@heading = @vm_string_table[:video_listing_popular]
				@page_description = @heading
			when "all"
				@video_list = Video.find_by_sql("SELECT start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, times_played/(DATEDIFF(now(), submitted_at)+1) as performance, DATEDIFF(now(), submitted_at) as existance_days FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id inner join uploads on uploads.id = videos.upload_id where public = 1 and videos.blocked = 0 and users.blocked = 0 and videos.disabled = 0 and videos.visible = 1 order by performance desc")
				@heading = @vm_string_table[:video_listing_popular]
				@page_description = @heading
			when "country"
				@video_list = Video.find_by_sql("select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, DATEDIFF(now(), submitted_at) as existance_days from (select * from (select country, count(country) as times from ((select id, start_country_code as country from routes) union (select id, end_country_code as country from routes)) as result group by country having country is not null ) as sort right join routes on sort.country = routes.start_country_code) as countries inner join videos on countries.video_id = videos.id inner join uploads on videos.upload_id = uploads.id where public = 1 and blocked = 0 AND videos.disabled = 0 and videos.visible = 1 order by times desc limit 16")
				@heading = @vm_string_table[:video_listing_country]
				@page_description = @heading
			when "city"
				@video_list = Video.find_by_sql(["select result.start_locality_en, result.end_locality_en, result.start_country_en, result.end_country_en, result.start_locality_de, result.end_locality_de, result.start_country_de, result.end_country_de, youtube, upload_id, times_played, city, public, result.DARX, result.DARY, video_id as id, filename_img, result.duration, result.name, distance, DATEDIFF(now(), submitted_at) as existance_days from ((select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, upload_id, times_played, routes.id, start_locality_"+@vm_language+" as city, videos.id as video_id, youtube, videos.DARX, videos.DARY, filename_img, videos.duration, videos.name, end_at_distance as distance, public from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0) union (select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, upload_id, times_played, routes.id, end_locality_"+@vm_language+" as city, videos.id as video_id, youtube, videos.DARX, videos.DARY, filename_img, duration, name, end_at_distance as distance, public from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0)) as result inner join uploads on uploads.id = result.upload_id where city is not null AND city = ? ORDER BY city limit 16", params[:find]])
				@heading = @vm_string_table[:video_listing_place] + params[:find]
				@page_description = @heading
			when "movement"
				@page_title = "Vidmap: " + @vm_string_table[:movement_expression] + " " + @vm_string_table[:movement_types][params[:find]]
				@video_list = Video.find_by_sql(["select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.movement_type, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, DATEDIFF(now(), submitted_at) as existance_days from (select count(movement_type) as times, movement_type from videos group by movement_type) as t1 right join videos on t1.movement_type = videos.movement_type inner join routes on routes.video_id = videos.id inner join uploads on uploads.id = videos.upload_id where public = 1 AND blocked = 0 AND videos.disabled = 0 AND videos.movement_type = ? order by times desc limit 16", params[:find]])
				@heading = @vm_string_table[:movement_expression] + " " + @vm_string_table[:movement_types][params[:find]]
				@page_description = @heading
			when "length"
				@video_list = Video.find_by_sql("select start_locality_en, end_locality_en, start_country_en, end_country_en, start_locality_de, end_locality_de, start_country_de, end_country_de, youtube, times_played, videos.DARX, videos.DARY, videos.public, videos.id as id, filename_img, videos.duration, videos.name, end_at_distance as distance, DATEDIFF(now(), submitted_at) as existance_days from videos inner join routes on routes.video_id = videos.id inner join uploads on uploads.id = videos.upload_id where public = 1 AND blocked = 0 AND videos.disabled = 0 order by distance desc limit 16")
			 
			#else
				#@video_list = Video.find_by_sql("SELECT DARX, DARY, videos.public, videos.id as id, filename_img, duration, name, end_at_distance as distance FROM videos inner join routes on videos.id = routes.video_id inner join users on user_id = users.id where public = 1 and videos.blocked = 0 and users.blocked = 0 order by latest_playback desc")
		end
		
		#twitterauth = TwitterOauth.new(session, cookies)		
		#@twitter_comments = twitterauth.search("http://search.twitter.com/search.json?q=%23" + (ENV['RAILS_ENV'] == 'development' ? 'vi_dev_all' : 'vi_all') + "&show_user=true&rpp=10")["results"]
			
		render :action => 'video_listing_'+@vm_language
	end
	
	def account
		
		if  request.post?
			
			# Set Language
			if params[:language]
				if ["de", "en"].include?(params[:language])
					session[:vm_language] = params[:language]
					cookies[:vm_language] = {:value => params[:language], :expires => 1.year.from_now, :domain => ".vidmap.de"}
					
					@vm_language =  params[:language]
					User.update(current_user.id, { :language => params[:language]})
				else
					session[:vm_language] = "de"
					cookies[:vm_language] = {:value => "de", :expires => 1.year.from_now, :domain => ".vidmap.de"}
					@vm_language = "de"
					User.update(current_user.id, { :language => "de"})
				end
				
				fill_string_table
			end
		
			# Set Website
			if params[:website]
				params[:website] = Sanitize.clean(params[:website]).downcase.lstrip.rstrip
				params[:website] = "http://" + params[:website] if (params[:website][0,7] != "http://" && params[:website][0,8] != "https://")
				User.update(current_user.id, { :website => params[:website]})
			end
			
			# Add authorized server
			if params[:server] && !params[:server].strip.empty?
				@server_name = params[:server].strip.downcase.gsub(/.*\/\//, '').gsub(/www\./, '').gsub(/\/.*/, '').gsub(/:.*/, '')
				#@server_name = params[:server].strip.downcase.gsub(/.*\/\//, '').gsub(/www\./, '').gsub(/:.*/, '')
				@api_result = Api.find_or_create_by_server_and_user_id(:server => @server_name, :key => Api.generateApiKey(current_user.login), :channel => "", :user_id => current_user.id)
			end
			
			redirect_to :action => 'account'
			return
				
		else
			# Remove authorized server
			if params[:remove_id]
				Api.delete_all(["id = ? AND user_id = ?", params[:remove_id], current_user.id])
			end
		end
	
		@api_keys = Api.find_all_by_user_id(current_user.id)
		
		render :action => 'account_'+@vm_language
	end
	

	
	def get_youtube_video_data
		
		search = CGI::escape(params[:search].gsub(/^.*?v=|&.*/, '').strip)

		begin
			problem = nil
			video_information = {}
			uri = URI.parse("https://www.googleapis.com/youtube/v3/search?part=snippet&q="+search+"&type=video&key=AIzaSyB-2fVdGYnZb6L8v8embnKiDP-2G2GkfEo")
			
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
			http.verify_mode = OpenSSL::SSL::VERIFY_NONE
			
			request = Net::HTTP::Get.new(uri.request_uri)
			
			response = http.request(request).body
			video_information = ActiveSupport::JSON.decode(response)
			
			key = video_information["items"][0]["id"]["videoId"]
			
			public = !video_information["items"].nil?
			
			#Realtime check because search results are updates only once a day...:
			#raise "ERROR::Not available on youtube." if ActiveSupport::JSON.decode(Net::HTTP.get_response(URI.parse("http://gdata.youtube.com/feeds/api/videos/" + key + "?alt=json")).body)['entry'].nil?
				
		rescue Exception => error
			problem = error.message
			key = nil
			public = false
		end
		
		begin
			search_is_valid_key = false #Net::HTTP.get_response(URI.parse("http://img.youtube.com/vi/" + search + "/1.jpg")).body.empty? ? false : true
		rescue
			search_is_valid_key = false
		end
		
		if !key && search_is_valid_key
			key = search
		end
	
		render :json => ActiveSupport::JSON.encode({:search =>search , :key => key, :public => public, :video_information => video_information['items'], :problem => problem})
   end
	
	def new
		redirect_to :action => "import" and return
		
		session[:return_to] = request.fullpath
		
		@page_title = "New - Vidmap" 
		@menuItem = "new"
		
		render :action => 'new_'+@vm_language
	end
	 
	def import
		session[:return_to] = request.fullpath
		
		@page_title = "Import Youtube Video - Vidmap" 
		@menuItem = "new"
		
		if request.post?
		
			search = CGI::escape(params[:video_link].gsub(/^.*?v=|&.*/, '').strip)
			name = params[:name]	
			movement_type= params[:movement_type]
			video_public = params[:video][:public]
			terms_accepted = params[:terms_accepted]
			
			if !search || !name || !movement_type || !video_public || !terms_accepted
				#catch missing parameters
				flash[:upload_result] = @vm_string_table[:import_missing_input]
				render :action => 'import_'+@vm_language
				return
			end
			
			if !["car", "bike", "plane", "foot", "moto", "ship", "train", "misc"].include?(movement_type)
				movement_type = "misc"
			end
			
			if video_public.to_s == '0'
				 video_public = 0
			else
				video_public = 1
			end
			
			#render :json => {:search => search, :name => name, :movement_type => movement_type, :video_public => video_public, :terms_accepted => terms_accepted}
			#return
			
			begin
				uri = URI.parse("https://www.googleapis.com/youtube/v3/search?part=snippet&q="+search+"&type=video&key=AIzaSyB-2fVdGYnZb6L8v8embnKiDP-2G2GkfEo")
				
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				
				request = Net::HTTP::Get.new(uri.request_uri)
				
				response = http.request(request).body
				video_information = ActiveSupport::JSON.decode(response)
				
				key = video_information["items"][0]["id"]["videoId"]
				
				
				uri = URI.parse("https://www.googleapis.com/youtube/v3/videos?id="+key+"&part=snippet,contentDetails&key=AIzaSyB-2fVdGYnZb6L8v8embnKiDP-2G2GkfEo")
				
				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = true
				http.verify_mode = OpenSSL::SSL::VERIFY_NONE
				
				request = Net::HTTP::Get.new(uri.request_uri)
				
				response = http.request(request).body
				video_information = ActiveSupport::JSON.decode(response)
			
				obj = video_information["items"][0]["contentDetails"]["duration"].scan(/\d+/)
				
				
				case obj.size
				when 1
					duration = obj[0].to_i
				when 2
					duration = obj[0].to_i*60 + obj[1].to_i
				when 3
					duration = obj[0].to_i*60*60 + obj[1].to_i*60 + obj[2].to_i
				else
					duration = 0
				end
				
				#render :json => duration and return
				
				#Realtime check because search results are updates only once a day...:
				#raise "ERROR::Not available on youtube." if ActiveSupport::JSON.decode(Net::HTTP.get_response(URI.parse("http://gdata.youtube.com/feeds/api/videos/" + key + "?alt=json")).body)['entry'].nil?
		
			rescue
				key = nil
			end	
		
			begin
				search_is_valid_key = false #Net::HTTP.get_response(URI.parse("http://img.youtube.com/vi/" + search + "/1.jpg")).body.empty? ? false : true
			rescue
				search_is_valid_key = false
			end
			
			if !key && search_is_valid_key
				key = search
				duration = 60
			end
			
			if !key
				#Catch no results from youtube
				flash[:upload_result] = @vm_string_table[:import_no_video_found]
				render :action => 'import_'+@vm_language
				return
			end
	
			@upload = Upload.new(:user_id => @current_user.id, :content_type => "video/youtube", :size => 111111, :filename => key, :video_flash_present => 2, :video_thumb_present => 2, :video_img_present => 2, :transcoder_state => 2, :PARX => 1, :PARY => 1, :DARX => 4, :DARY => 3, :duration => duration, :name => name, :transcoder_message => "youtube", :submitted_at => Time.now.utc, :terms_accepted => "YES", :movement_type => movement_type, :code => "0000", :video_public => video_public)
			@upload.save! 
			
			@video = Video.new(:user_id => @current_user.id, :upload_id => @upload.id, :youtube => 1, :duration => duration, :name => name, :movement_type => movement_type, :blocked => 0, :filename_flash => key, :filename_thumb => key, :filename_img => key, :movement_type => movement_type, :public => video_public)
			@video.save!
			
			redirect_to :action => 'videos'
			return
		end
		
		render :action => 'import_'+@vm_language
		
		rescue Exception => exc
			flash[:upload_result] = exc.message
			render :action => 'import_'+@vm_language
	end
	
	def check_video_health
		
		if !params[:video_unavailable] || params[:video_unavailable].to_i != 1
			params[:video_unavailable] = 0
		end	
		
		if !params[:video_id] || !Video.find_by_id(params[:video_id])
				render :text => {:message => "Wrong parameters.", :video_key => params[:video_key], :video_type => params[:video_type],  :video_id => params[:video_id]}.to_json
				return
		end
		
		if current_user != false && current_user.has_video?(params[:video_id])
			#Instantly disable/enable video (reason: playback error/success)
			#xxxVideo.update(params[:video_id], {:disabled => params[:video_unavailable].to_i, :disabled_cause => params[:video_unavailable].to_i == 1 ? 1 : 0})
			render :text => {:message => "Video belongs to user", :video_unavailable => params[:video_unavailable]}.to_json
			return
		else
			#Check youtube api (private youtube videos are always disabled)
			begin
				key = Video.find_by_id(params[:video_id]).filename_flash
				
				#Realtime check because search results are updates only once a day...:
				raise "ERROR::Not available on youtube." if ActiveSupport::JSON.decode(Net::HTTP.get_response(URI.parse("http://gdata.youtube.com/feeds/api/videos/" + key + "?alt=json")).body)['entry'].nil?
	
				#xxxVideo.update(params[:video_id], {:disabled => 0, :disabled_cause => 0})
				render :text => {:message => "Video is available on youtube.", :video_unavailable => params[:video_unavailable]}.to_json
				return
			rescue Exception => error
				#xxxVideo.update(params[:video_id], {:disabled => 1, :disabled_cause => 1})
				render :text => {:message => "Video is not available on youtube. Deactivate video.", :video_unavailable => params[:video_unavailable]}.to_json
				return
			end	
		
		end
		
		rescue Exception => error
			render :text => "Error: " + error.message
	end
	
		  
	def disclaimer
		session[:return_to] = request.fullpath
		@page_title = @vm_string_table[:web_disclaimer_routes]
		render :action => 'disclaimer_'+@vm_language
	end
	
	def terms
		session[:return_to] = request.fullpath
		@page_title = @vm_string_table[:web_terms_routes]
		render :action => 'terms_'+@vm_language
	end
	
	def privacy
		#session[:return_to] = request.fullpath
		#@page_title = @vm_string_table[:web_privacy]
		#render :action => 'privacy_'+@vm_language
	end
	
	def set_language
		if params[:language_id]
			session[:vm_language] = params[:language_id]
			cookies[:vm_language] = {:value => params[:language_id], :expires => 1.year.from_now, :domain => ".vidmap.de"}
			#fill_string_table
		end
		
		session[:return_to] ? redirect_to(session[:return_to]) : redirect_to("/")
	end
	
	def embed
		
		@video = Video.find_by_id(params[:video_id])
		
		@isPublic = @video && @video.public ?  true : false
		@isOwner = @video && current_user && @video.user_id == current_user.id ?  true : false
		@isAdmin = isAdmin? 
		
		
		@vmkey = params[:vmkey]
		
		if !@video || (@video.blocked && !@isOwner)
			redirect_to :action => "index"
			return
		end
		
		# Language
		@vm_language_inverse = (@vm_language == "en" ? "de" : "en")
		video_url = url_for(:controller => 'web', :action => 'video', :video_id => params[:video_id], :language_id => @vm_language_inverse, :desc => "watch")
		@custom_language_switch_url = @vm_string_table[:language_switch_template].sub("[#url]", video_url)
		##########
		
		@route = Route.find_by_sql(["select * from videos inner join routes on routes.video_id = videos.id where videos.id = ? LIMIT 1", params[:video_id]])[0]
		@hasRoute = !@route.nil?
		
		@user_name = User.find_by_sql(["select users.login from videos inner join users on user_id = users.id where videos.id = ? AND users.blocked = 0", params[:video_id]])[0].login
		@user_website = User.find_by_sql(["select users.website from videos inner join users on user_id = users.id where videos.id = ? AND users.blocked = 0", params[:video_id]])[0]
		
		@api_key = @vmkey && !@vmkey.empty? && Api.find_by_key(@vmkey) ? Api.find_by_key(@vmkey).key : Api.find_by_user_id(User.find_by_role("SYSTEM").id, :order => "id desc").key
		#@api_key = Api.find_by_user_id(current_user ? current_user.id : User.find_by_role("SYSTEM").id, :order => "id desc").key
		
		
		
		if @isOwner
			@private_api_key = Api.find_by_user_id(current_user.id)
			@private_api_key = @private_api_key ? @private_api_key.key : nil
		else 
			@private_api_key = nil
		end
		
		#render :json => @api_key
	end
	
	def video
		session[:return_to] = request.fullpath
		
		@top_level_domain = ENV['RAILS_ENV'] == 'development' ? 'dev' : 'www'
		
		# Entweder muss Nutzer eingeloggt sein & das Video zum Nutzer passen 
		# ODER muss das Video freigegeben sein für jedermann
		# video view wird dann reagieren & entweder editor / player oder Warnung ausgeben
		
		# Only show non-blocked videos
		@video = Video.find_by_id(params[:video_id])
		
		@isPublic = @video && @video.public ?  true : false
		@isOwner = @video && current_user && @video.user_id == current_user.id ?  true : false
		@isAdmin = isAdmin? 
		
		if !@video || (@video.blocked && !@isOwner)
			redirect_to :action => "index"
			return
		end
		
		# Language
		@vm_language_inverse = (@vm_language == "en" ? "de" : "en")
		video_url = url_for(:controller => 'web', :action => 'video', :video_id => params[:video_id], :language_id => @vm_language_inverse, :desc => "watch")
		@custom_language_switch_url = @vm_string_table[:language_switch_template].sub("[#url]", video_url)
		##########
		
		@route = Route.find_by_sql(["select * from videos inner join routes on routes.video_id = videos.id where videos.id = ? LIMIT 1", params[:video_id]])[0]
		@hasRoute = !@route.nil?
		
		@user_name = User.find_by_sql(["select users.login from videos inner join users on user_id = users.id where videos.id = ? AND users.blocked = 0", params[:video_id]])[0].login
		@user_website = User.find_by_sql(["select users.website from videos inner join users on user_id = users.id where videos.id = ? AND users.blocked = 0", params[:video_id]])[0]
		
		if !@user_website.nil?
			@user_website = @user_website.website
			@user_website = "http://" + @user_website if !@user_website.nil? && !@user_website.empty? && @user_website.downcase[0,7] != "http://" && @user_website.downcase[0,8] != "https://"
		end
		
		@submission_date = Video.find_by_sql(["select DATE_FORMAT(submitted_at, '%d.%m.%y') as date from videos inner join uploads on upload_id = uploads.id where videos.id = ?", params[:video_id]])[0]
		@submission_date = @submission_date ? @submission_date.date : "06.07.08"
		
		
		@api_key = Api.find_by_user_id(current_user && !current_user.apis.empty? ? current_user.id : User.find_by_role("SYSTEM").id, :order => "id desc").key

		if @isOwner
			@private_api_key = Api.find_by_user_id(current_user.id)
			@private_api_key = @private_api_key ? @private_api_key.key : nil
		else 
			@private_api_key = nil
		end
		
		#Page title
		@page_title = (render_to_string :layout => false, :template => "web/title_video_" + @vm_language).strip
		@page_description = (!@video.description.nil? && @video.description.length>0) ? @video.description : (render_to_string :layout => false, :template => "web/title_video_" + @vm_language).strip
		
		#Twitter stuff
		#	twitterauth = TwitterOauth.new(session, cookies)		
		#	@twitter_comments = twitterauth.search("http://search.twitter.com/search.json?q=%23" + (ENV['RAILS_ENV'] == 'development' ? 'vi_dev_' : 'vi_') + params[:video_id].to_s + "&show_user=true&rpp=20")["results"]
		#	@twitter_status = twitterauth.status?
		#	@twitter_status_updated = session[:twitter_status_updated]
		#	@max_comment_length = (ENV['RAILS_ENV'] == 'development' ? 96 : 100)
			
		#	session[:twitter_status_updated] = nil
		 ########
		 
		 #Publisher stuff
		 @publisher_links = []
		 if @hasRoute && @route.start_locality_en && @route.start_country_en
			 keywords = Keyword.find(:all, :conditions => ["city = ? OR country = ?", @route.start_locality_en.downcase, @route.start_country_en.downcase])
			 if !keywords.nil?
				keywords.each {|keyword|
					links = keyword.links
					
					if !links.nil?
						links.each {|item|
							@publisher_links.push({:link => item.link, :link_text => item.link_text, :link_comment => item.link_comment})
						}
					end
					
				}
			 end
		 end
		 ########
		 
		 
		#Content stuff
		if @route && @route.start_country_en && @route.start_locality_en
			@content = Content.getContent(@route.start_country_en, @route.start_locality_en)
			@content = nil if @content && @content.strip.empty?
			@start_country_en = @route.start_country_en
			@start_locality_en = @route.start_locality_en
		else
			@content = nil
		end
		#############
		 
		
		 
		if (!@isPublic && !@isOwner) || (!@hasRoute && !@isOwner)  
			redirect_to :action => "index"
		else
			@sidebar_embed = render_to_string :layout => false, :template => "web/sidebar_embed_" + @vm_language
			@sidebar_video = render_to_string :layout => false, :template => "web/sidebar_video_" + @vm_language
			render :action => 'video_'+@vm_language
		end

	end
	
	def videos 
		session[:return_to] = request.fullpath
		@menuItem = "videos"
		
		@page_title = "Videos - Vidmap" 
		#@videos = Video.find(:all, :conditions => [ "user_id = ?", current_user.id])
		@videos = Video.find_by_sql([SQL_GET_ALL_USER_VIDEOS,  current_user.id])
		
		#@upload = Upload.find(:all, :conditions => ["UNIX_TIMESTAMP(submitted_at) >= (UNIX_TIMESTAMP(now())-60*60*3) AND user_id = ?", current_user.id], :order => "submitted_at desc", :limit => 1)
		@upload = Upload.find(:all, :conditions => ["UNIX_TIMESTAMP(submitted_at) >= (UNIX_TIMESTAMP(now())-60*60*24*7) AND transcoder_state != 2 AND user_id = ?", current_user.id], :order => "submitted_at desc")
		
		## Catalogues
		#Frequent cities
		#@cities = Route.find_by_sql("select locality as name, count(locality) as times from ((select routes.id, start_locality_" + @vm_language + " as locality from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0) union (select routes.id, end_locality_" + @vm_language + " as locality from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0)) as result group by locality having locality is not null ORDER BY RAND()")
		
		#Frequent countries
		#@countries = Route.find_by_sql("select country, count(country) as times from ((select id, start_country_code as country from routes) union (select id, end_country_code as country from routes)) as result group by country having country is not null order by times desc")
	
		#Frequent movement types
		#@movements = Video.find_by_sql("SELECT movement_type, count(movement_type) as times FROM videos inner join routes on routes.video_id = videos.id group by movement_type order by times desc limit 5")
		
		#Length histogram
		#@distances = Route.find_by_sql("SELECT sum(end_at_distance<=1000)/count(end_at_distance) as freq0, sum(end_at_distance>1000 AND end_at_distance<=5000)/count(end_at_distance) as freq1000, sum(end_at_distance>5000 AND end_at_distance<=10000)/count(end_at_distance) as freq5000, sum(end_at_distance>10000 AND end_at_distance<=50000)/count(end_at_distance) as freq10000, sum(end_at_distance>50000)/count(end_at_distance) as freq50000 FROM routes")[0]
		
		# Twitter
		#	twitterauth = TwitterOauth.new(session, cookies)		
		#	@twitter_comments = twitterauth.search("http://search.twitter.com/search.json?q=%23" + (ENV['RAILS_ENV'] == 'development' ? 'vi_dev_all' : 'vi_all') + "&show_user=true&rpp=5")["results"]
		######
			
		redirect_to :action => "import" and return if !@videos || @videos.nil? || @videos.length == 0
				
		render :action => 'videos_'+@vm_language
	end
	
	def video_visible
		@video = Video.find_by_id(params[:video_id])
		
		if !@video || !isAdmin? 
			redirect_to :action => "index"
			return
		end
		
		Video.update(@video.id, {:visible => params[:visible] == "true"})
		
		render :json => {:visible => params[:visible]}
		
	end
	
	def video_update
		
		@video = Video.find_by_id(params[:video_id])
		
		if !@video
			redirect_to :action => "index"
			return
		end
		
		@isPublic = @video && @video.public ?  true : false
		@isOwner = @video && @video.user_id == current_user.id ?  true : false
		
		@route = Route.find_by_sql(["select * from videos inner join routes on routes.video_id = videos.id where videos.id = ? LIMIT 1", params[:video_id]])[0]
		@hasRoute = !@route.nil?
		
		@user_name = User.find_by_sql(["select users.login from videos inner join users on user_id = users.id where videos.id = ?", params[:video_id]])[0].login
		@submission_date = Video.find_by_sql(["select DATE_FORMAT(submitted_at, '%d.%m.%y') as date from videos inner join uploads on upload_id = uploads.id where videos.id = ?", params[:video_id]])[0]
		@submission_date = @submission_date ? @submission_date.date : "00.00.00"
		
		
		@api_key = Api.find_by_user_id(User.find_by_role("SYSTEM").id, :order => "id desc").key
		
		if @isOwner
			@private_api_key = Api.find_by_user_id(current_user.id)
			@private_api_key = @private_api_key ? @private_api_key.key : nil
		else 
			@private_api_key = nil
		end
		
		if (!@isPublic && !@isOwner) || (!@hasRoute && !@isOwner)  
			redirect_to :action => "index"
		else
			@sidebar_embed = render_to_string :layout => false, :template => "web/sidebar_embed_" + @vm_language
			render :json => {:privacy => @isPublic? "public": "private", :aspect =>@video.DARX.to_s + ":" + @video.DARY.to_s, :movement => @video.movement_type,  :places => (render_to_string :layout => false, :template => "web/_places_video_" + @vm_language), :sidebar =>  (render_to_string :layout => false, :template => "web/sidebar_video_" + @vm_language)}.to_json  
		end
	
	end
	
	def transcoder_update
		@upload = Upload.find(:all, :conditions => ["UNIX_TIMESTAMP(submitted_at) >= (UNIX_TIMESTAMP(now())-60*60*24*7) AND transcoder_state != 2 AND user_id = ?", current_user.id], :order => "submitted_at desc")
		
		@server_current_uploads = (@upload.collect {|up| up.id }).sort
		params[:current_uploads] ? @client_current_uploads = ActiveSupport::JSON.decode(params[:current_uploads]).sort : @client_current_uploads = []
			
		@result = []
		@upload.each{ |item|
			@result.push({:transcoder_state => item.transcoder_state, :transcoder_state_description => render_to_string(:partial => "web/upload_progress_" + @vm_language + ".rhtml", :locals => {:upload_item => item}) }		)
		}
		
		if ((@server_current_uploads | @client_current_uploads) - (@server_current_uploads & @client_current_uploads)).empty?
			render :json => {:uploads => @result, :video_list => nil, :current_uploads => @server_current_uploads.to_json}
		else
			@videos = Video.find_by_sql([SQL_GET_ALL_USER_VIDEOS,  current_user.id])
			render :json => {:uploads => @result, :video_list => render_to_string(:partial => "web/video_list_"+@vm_language+".rhtml", :locals => {:items => @videos, :rows => 4}), :current_uploads => @server_current_uploads.to_json}
		end
	
	end
	
	def videos_plain		
		@videos = Video.find(:all, :conditions => [ "user_id = ?", current_user.id], :order => "name")
		 render :json => @videos.to_json  
	end
	
	def delete_video
		Video.destroy_all([ "user_id = ? AND id = ?", current_user.id, params[:video_id]])
	
		redirect_to :action => 'videos'
	end
	
	def image
			
		if !params[:image].nil? && !params[:image].empty?
			params[:image] = params[:image].gsub("/", "").gsub("\\", "").gsub("..", "")
		end

		send_file('/usr/share/red5/webapps/vmStream/streams/'+params[:image], :type => 'image/jpeg', :disposition => 'inline', :filename => 'video.jpeg', :stream => false ) 
	
		rescue Exception => exc
			send_file(Rails.root.to_s + '/public/images/content_not_found.jpg', :type => 'image/jpeg', :disposition => 'inline', :filename => 'image_not_found.jpeg', :stream => false ) 
	end
	

end
