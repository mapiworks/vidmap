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

class ApplicationController < ActionController::Base
  	protect_from_forgery
  
 	before_filter :set_p3p_header
	
	before_filter :set_cache_header


	#before_filter :get_client_country
	
	layout "layouts/standard"
	
	## Session management
	include AuthenticatedSystem
	
	## Referer management
	include RefererCheck	
	
	## Language management
	include LanguageCheck
	
	## Twitter OAuth
	#include TwitterOauth
	
	require 'uri'
	require 'net/http'
	require "net/https"
	
	#protect_from_forgery
	
	protected

		def getVidmapSetting(property) 
			Setting.find(:first, :conditions => ["property = ?", property]).value
		end 
		
		def set_cache_header
		  #response.headers['Content-Type'] = 'text/xml;'
		  response.headers['Cache-Control'] = 'cache, must-revalidate;'
		  #response.headers['Cache-Control'] = 'no-cache'
		  response.headers['Pragma'] = 'public'
		end
		
		def set_p3p_header
		  response.headers['P3P'] = 'CP="NOI DSP CURa ADMa DEVa TAIa OUR BUS IND UNI COM NAV INT"'
		end
		
		def get_client_country 
		
			#Country codes: http://www.iso.org/iso/english_country_names_and_code_elements
			# Debug code: session[:client_country]: <%= session[:client_country] %> / session[:client_country_evaluated]: <%= session[:client_country_evaluated] %> 
			if session[:client_country].nil? #Do it only once per session!
				uri = URI.parse('http://api.hostip.info/country.php?ip=' + remote_ip)

				req = Net::HTTP::Get.new(uri.to_s)
				req['User-Agent'] = "unknown"
				req['Keep-Alive'] = 'no'
				req['Connection'] = 'close'
				
				http = Net::HTTP::new(uri.host, uri.port)
				http.open_timeout = 1
				http.read_timeout = 1
				
				begin
				  	response = http.start do |http|
						http.request(req)
				  	end
				rescue Timeout::Error => e
				  session[:client_country] = "Timeout"
				  session[:client_country_evaluated] = true
				  return nil
				rescue Exception
					#Wrong adress or whatever
					session[:client_country] = "Exception"
				 	session[:client_country_evaluated] = true
					return nil
				end
				
				if response.body.strip.downcase == "xx"
					session[:client_country] = "No entry in database"
				  	session[:client_country_evaluated] = true
					return nil
				end
				
				session[:client_country] = response.body
				session[:client_country_evaluated] = false
			end
		end
	
		def remote_ip

		   trusted_proxies  	=  	/^127\.0\.0\.1$|^(10|172\.(1[6-9]|2[0-9]|30|31)|192\.168)\./i
		   
		   remote_addr_list =  request.env['REMOTE_ADDR'] &&  request.env['REMOTE_ADDR'].split(',').collect(&:strip)
		
		   unless remote_addr_list.blank?
			 not_trusted_addrs = remote_addr_list.reject {|addr| addr =~ trusted_proxies}
			 return not_trusted_addrs.first unless not_trusted_addrs.empty?
		   end
		   remote_ips =  request.env['HTTP_X_FORWARDED_FOR'] &&  request.env['HTTP_X_FORWARDED_FOR'].split(',')
		
		   if  request.env.include? 'HTTP_CLIENT_IP'
			 if remote_ips && !remote_ips.include?( request.env['HTTP_CLIENT_IP'])
			   # We don't know which came from the proxy, and which from the user
			   return "0.0.0.0"
			 end
		
			 return  request.env['HTTP_CLIENT_IP']
		   end
		
		   if remote_ips
			 while remote_ips.size > 1 && trusted_proxies =~ remote_ips.last.strip
			   remote_ips.pop
			 end
		
			 return remote_ips.last.strip
		   end
		
			request.env['REMOTE_ADDR']
		 end
 
end
