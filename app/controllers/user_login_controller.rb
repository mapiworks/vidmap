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
 
class UserLoginController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller
	
	require 'uri/http'
	require 'oauth'


	before_filter :check_language, :except => [:set_language]
		
  # If you want "remember me" functionality, add this before_filter to Application Controller
  # before_filter :login_from_cookie

  #def index
  #  redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  #  #redirect_to(:controller => 'application', :action => 'home')
  #end

  def activate 
  	
	return unless params[:activation_code]
	
	if getVidmapSetting("allowAccountActivation") == "false" 
		flash[:login_message] = @vm_string_table[:activation_closed]
		redirect_back_or_default(:controller => '/web', :action => 'index')
		return
	end
	
	@user = User.find_by_activation_code(params[:activation_code])	
	
	if @user
		
		flash[:login_message] = @vm_string_table[:account_activated]
		if @user.activated?
			@user.remember_me
			cookies[:auth_token] = { :value => @user.remember_token, :expires => @user.remember_token_expires_at, :domain => ".vidmap.de"}
			redirect_to(:controller => '/web', :action => 'index')
		else
			#User.update(@user.id, {:firstname => "testerio"})
			@user.activated = 1
			@user.save(false)
						
			self.current_user = @user
			self.current_user.remember_me
			
			cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at, :domain => ".vidmap.de"}
			self.current_user.set_last_login_date
			
			session[:vm_language] = self.current_user.language
			cookies[:vm_language] = {:value => self.current_user.language, :expires => 1.year.from_now, :domain => ".vidmap.de"}		
			redirect_to(:controller => '/web', :action => 'import')
		end
	else
		flash[:login_message] = @vm_string_table[:activation_failed]
		redirect_back_or_default(:controller => '/web', :action => 'index')
	end
	
  end	

  	
  def remove_user
  	
	if logged_in?
		User.destroy(self.current_user.id)
		cookies.delete(:auth_token, :domain => ".vidmap.de")
    	reset_session
		flash[:login] = @vm_string_table[:account_removed]
	end
	
	redirect_to(:controller => '/web', :action => 'index')
  end
  
  def social_login
  	
  	if getVidmapSetting("allowAccountLogin") == "false" 
  		flash[:login_message] = @vm_string_table[:login_closed]
  		redirect_back_or_default(:controller => '/web', :action => 'index')
  		return
  	end
  	
  	if logged_in?
  		redirect_to(:controller => '/web', :action => 'index')
  	else
  		if params[:twitter]
  			redirect_to :action => :oauth_register, :twitter => true and return
  		else
  			redirect_to :action => :oauth_register, :linkedin => true and return
  		end
  	end
  	
  	
  end
  
  def oauth_consumer_linkedin
  	return OAuth::Consumer.new("qx0mj8TQwG9TDQg_yA4UsRxd6ylMhqay6geoDPUJRqdjPObTbmvGE_qEuIQwVy9o","Nxp_5wKeTugV9mDUgzPQlO0BZwNL2xBqVu7iTyHDNd1WAMRUBJ8bl7HU_8srYMe4", {
  		:site=>"https://api.linkedin.com", 
  		:request_token_path => "/uas/oauth/requestToken",
  		:access_token_path => "/uas/oauth/accessToken",
  		:authorize_path => "/uas/oauth/authorize",
  		:scheme => :header,
     		:http_method => :post
  	})
  end
  
  def oauth_consumer_twitter
  	return OAuth::Consumer.new("rkEONVlClSeOx6oHgrwZhA","PQWOn8u63kIF4Q1N9JQVy0bWOuPh8q4vcEFHKqw", {
  		:site=>"https://api.twitter.com", 
  		:request_token_path => "/oauth/request_token",
  		:access_token_path => "/oauth/access_token",
  		:authorize_path => "/oauth/authenticate",
  		:scheme => :header,
     	:http_method => :post
  	})
  end
  
  def oauth_register
  	
  	if params[:twitter]
  		@consumer=oauth_consumer_twitter
  		@request_token=@consumer.get_request_token(:oauth_callback => "http://www.vidmap.de/user_login/oauth_callback?twitter=true")
  	else
  		@consumer=oauth_consumer_linkedin
  		@request_token=@consumer.get_request_token(:oauth_callback => "http://www.vidmap.de/user_login/oauth_callback?linkedin=true")
  	end
  	
  	
  	session[:request_token]=@request_token.token
    session[:request_token_secret]=@request_token.secret 
  	
  	redirect_to @request_token.authorize_url and return
  	
  end
  
  def oauth_callback
  	
  	begin 
	  	if params[:oauth_problem]
	  		redirect_to("/")
	  		return
	  	end
	  	
	  	if params[:denied]
	  		redirect_to(:controller => '/user_login', :action => 'login')
	  		return
	  	end
	  	
	  	if params[:twitter]
	  		@request_token=OAuth::RequestToken.new(oauth_consumer_twitter, session[:request_token], session[:request_token_secret]) 		
	  	else
	  		@request_token=OAuth::RequestToken.new(oauth_consumer_linkedin, session[:request_token], session[:request_token_secret]) 	
	  	end
	  	
	  	@access_token=@request_token.get_access_token(:oauth_verifier => params[:oauth_verifier])
	  	session[:token] = @access_token.token 
	  	session[:secret] = @access_token.secret 
	  	
	  	#render :text => {:token => @access_token.token, :secret => @access_token.secret} and return
	  	
	  	cookies[:token] = { :value => @access_token.token, :expires => 1.year.from_now, :domain => ".vidmap.de"}
	  	
	  	if params[:twitter]
	  		begin
		  		@profile=@access_token.get("https://api.twitter.com/1.1/account/verify_credentials.json")
		  		@profile = JSON.parse(@profile.body)
		  		session[:name] = @profile["screen_name"]
		  		session[:website] = @profile["url"]
		  		
		  		session[:profile_url] = "http://twitter.com/#!/" + @profile["screen_name"]
		  		service = "twitter"
		  	rescue Exception => e
		  		render :text => e.to_s + "<br>" + @profile.to_json and return
		  	end 
	  	else
	  		@profile=@access_token.get("http://api.linkedin.com/v1/people/~:(id,first-name,last-name,public-profile-url)", {"x-li-format" => "json"})
	  		@profile = JSON.parse(@profile.body)
	  		session[:name] = @profile["firstName"] + " " + @profile["lastName"]
	  		session[:profile_url] = @profile["publicProfileUrl"] ? @profile["publicProfileUrl"] : "#"
	  		session[:website] = @profile["publicProfileUrl"] ? @profile["publicProfileUrl"] : ""
	  		service = "linkedin"
	  	end
	  	
	  	session_user = User.find_or_create_by_token(:token => session[:token], :login => session[:name], :secret => session[:secret], :service => service, :profile_url => session[:profile_url], :website => session[:website])
	  	session_user.secret = session[:secret]
	  	session_user.service = service
	  	session_user.profile_url = session[:profile_url]
	  	
	  	session_user.save!
	  	
	  	session[:vm_login_name] = session[:name]
	  	
	  	self.current_user = session_user
	  	
	  	self.current_user.remember_me
	  	cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at, :domain => ".vidmap.de"}
	 
	
	  	self.current_user.set_last_login_date
	  	
	  	session[:vm_language] = self.current_user.language
	  	cookies[:vm_language] = {:value => self.current_user.language, :expires => 1.year.from_now, :domain => ".vidmap.de"}
	 
	 rescue Exception => e
	 	render :text => e.to_s and return
	 end 	
  	
  	redirect_back_or_default(:controller => '/web', :action => 'videos')
  end

  def login
  	
		if getVidmapSetting("allowAccountLogin") == "false" 
			flash[:login_message] = @vm_string_table[:login_closed]
			redirect_back_or_default(:controller => '/web', :action => 'index')
			return
		end
	
			#reset return_to & simply show the view if call through "Anmelden" link
			if !request.post?
				#session[:return_to] = nil
				render :action => 'login_'+@vm_language
				return
			end
		
		 # Remember previously entered login to avoid double entry
		 session[:vm_login_name] = params[:login]
		 
		 self.current_user = User.authenticate(params[:login], params[:password])
			
		 if logged_in?
			 
			#if params[:remember_me] == "1"
			self.current_user.remember_me
			cookies[:auth_token] = { :value => self.current_user.remember_token, :expires => self.current_user.remember_token_expires_at, :domain => ".vidmap.de"}
			# end
			
			self.current_user.set_last_login_date
			
			session[:vm_language] = self.current_user.language
			cookies[:vm_language] = {:value => self.current_user.language, :expires => 1.year.from_now, :domain => ".vidmap.de"}
				
			redirect_back_or_default(:controller => '/web', :action => 'videos')
			#redirect_to(:controller => '/web', :action => 'videos')
		else
			redirect_to(:controller => '/web', :action => 'index')
			flash[:login] = @vm_string_table[:login_failed]
		end

  end
	
  def signup
    
	if getVidmapSetting("allowAccountRegistration") == "false" 
		flash[:login_message] = @vm_string_table[:registration_closed]
		redirect_back_or_default(:controller => '/web', :action => 'index')
		return
	end

	session[:return_to] = request.fullpath
		
	# Request has to come from a form
	if  !request.post?
		flash[:login_message] = ""
		render :action => 'signup_'+@vm_language
		return
	end
	
	begin
		
		begin	
			params[:user][:website].strip!
			
			if params[:user][:website].length >=64
				raise(URI::InvalidURIError)
			end
			
			parsed_url = URI.parse(params[:user][:website])
	
			#render :text=> params[:user][:website] + " is valid" and return
			
		rescue URI::InvalidURIError => e
			#render :text=> params[:user][:website] + " is not valid (error: "+ e.message+")" and return
			params[:user][:website] = nil
		end
		
		@user = User.new(params[:user])
		
		if !["de", "en"].include?(@user.language)
			@user.language = "de"
		end
		
		if @user.save!
			
			#Set chosen language
			session[:vm_language] = @user.language
			cookies[:vm_language] = {:value => @user.language, :expires => 1.year.from_now, :domain => ".vidmap.de"}
			
			#Mailer.deliver_activation_code(@user, request.referer, @vm_string_table)
			send_activation_code(@user, request.referer, @vm_string_table)
			
			#User.update(@user.id, { :activation_mail_sent => 1})
			@user.activation_mail_sent = 1
			@user.save(false)
			
			@login_message = @vm_string_table[:mailer_mail_sent] + @user.email.to_s
			flash[:login_message] = @vm_string_table[:mailer_mail_sent] + @user.email.to_s
			redirect_to(:controller => '/web', :action => 'index')
		end
		
	rescue ActiveRecord::RecordInvalid => e
		flash[:login_message] = @vm_string_table[:account_could_not_create]
		render :action => 'signup_'+@vm_language
		return
	rescue Exception => e
		flash[:login_message] = @vm_string_table[:account_create_other_error]
		#Destroy user record
		User.delete(@user.id)
		#myDebug "ERROR in UserLoginController/signup:" + e.message
		render :action => 'signup_'+@vm_language
		return
	end
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete(:auth_token, :domain => ".vidmap.de")
    reset_session
    flash[:notice] = @vm_string_table[:logged_out]
		redirect_to(:controller => '/web', :action => 'index')
  end
	
private
	
	def send_activation_code(user, referer, translation)	
		ActivationMailer.activation_email(user, referer, translation).deliver
		user.activation_mail_sent = 1
		user.save(false)
		#Mailer.deliver_activation_code(user, referer, translation); 
	end
	
end
