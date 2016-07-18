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
 
class AdminController < ApplicationController

	## Session management                                                   
	before_filter :login_required
	before_filter :check_language                                           
																			
	def authorized?                                                         
			current_user ? current_user.has_role?("ADMIN") : false          
	end   

	def index
		@menuItem = "admin"
		@user_infos = User.find_by_sql("SELECT users.id as user_id,login, service, last_login, email, website, language, activated, activation_mail_sent, upload_errors_count, upload_errors_latest, video_count, upload_count  FROM users inner join (select vids.user_id, video_count, upload_count from (select users.id as user_id, service, count(videos.id) as video_count from users left join videos on users.id = videos.user_id group by users.id) as vids inner join (SELECT users.id as user_id, count(uploads.id) as upload_count FROM users left join uploads on uploads.user_id = users.id group by users.id) as ups on vids.user_id = ups.user_id) as vids_ups on users.id = vids_ups.user_id order by users.id desc")
		render :action => 'dashboard'
	end
	
	def routes
		session[:return_to] = request.fullpath
		@page_title = @vm_string_table[:web_title_routes]
		
		@videos = Video.find_by_user_id(current_user.id)
		
		render :action => 'routes_'+@vm_language
	end
	
	def switch_user
		
		self.current_user = User.find_by_id(params[:user_id])
		self.current_user.remember_me
		cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at, :domain => ".vidmap.de"}
		
		redirect_to :controller => '/web', :action => 'index'
	end
	
	def embed
		if  request.post?
			
			if !params[:server].strip.empty?
				@server_name = params[:server].strip.downcase.gsub(/.*\/\//, '').gsub(/www\./, '').gsub(/\/.*/, '').gsub(/:.*/, '')
				
				@api_result = Api.find_or_create_by_server_and_user_id(:server => @server_name, :key => Api.generateApiKey(@server_name), :channel => "", :user_id => current_user.id)
			
				@api_key = @api_result.key
				
				if params[:routes]
					@route_ids = "[" + params[:routes].join(",") + "]"
				else
					@route_ids = "[]"
				end
			else
				
			end
			
		else
			if params[:remove_id]
				Api.delete_all(["id = ? AND user_id = ?", params[:remove_id], current_user.id])
			end
			
			@route_ids = false
			@api_key = false	
		end
		
		session[:return_to] = request.fullpath
		@page_title = @vm_string_table[:web_title_embed]
		@embed = Video.find_by_sql(["select routes.id, user_id, name, filename_img from routes left join videos on videos.id = routes.video_id group by videos.id having user_id = ?",  current_user.id])
		@api_keys = Api.find_all_by_user_id(current_user.id)
		render :action => 'embed_'+@vm_language
	end
	
	def resend_activation_code	
		user = User.find_by_id(params[:user_id])
		ActivationMailer.activation_email(user, request.referer, @vm_string_table).deliver
		#Mailer.deliver_activation_code(User.find_by_id(params[:user_id]), request.referer, @vm_string_table); 
		
		user.activation_mail_sent = 1
		user.save(false)
		
		redirect_to :action => 'index'
	end
	
	#FORGOTTEN UPLOADS:
	#SELECT uploads.id FROM uploads left join videos on uploads.id = videos.upload_id where videos.id is NULL
end
