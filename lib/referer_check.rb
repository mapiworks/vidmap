module RefererCheck
  protected

    def check_valid_key_and_domain
	
		#render :text => "session[:valid_api_key]=" + session[:valid_api_key].to_s + " / session[:api_user_id] =" + session[:api_user_id].to_s
		#return
		session[:valid_api_key] = cookies[:valid_api_key] if cookies[:valid_api_key]
		session[:api_user_id] = cookies[:api_user_id] if cookies[:api_user_id]
		
		if (session[:valid_api_key] && session[:api_user_id]) || (cookies[:valid_api_key] && cookies[:api_user_id])
			return true
		else 
			return api_access_denied
		end
		
    end

    def api_access_denied
		headers["Status"]           = "Unauthorized"
		render :text => "Sorry, couldn't authenticate you.", :status => '401 Unauthorized'
	end	
		
	
end
