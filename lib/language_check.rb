# coding: utf-8

module LanguageCheck
  protected
	
	DEFAULT_LANGUAGE = "en"
	
	def reset_language
		@vm_language = DEFAULT_LANGUAGE
		session[:vm_language] = DEFAULT_LANGUAGE
		cookies[:vm_language] = {:value => DEFAULT_LANGUAGE, :expires => 1.year.from_now, :domain => ".vidmap.de"}
	end
	
	def check_language
	
		if params[:language_id]
			session[:vm_language] = params[:language_id]
			cookies[:vm_language] = {:value => params[:language_id], :expires => 1.year.from_now, :domain => ".vidmap.de"}
			@vm_language = params[:language_id]
			
		elsif cookies[:vm_language] || session[:vm_language]
			@vm_language = cookies[:vm_language] || session[:vm_language]
			session[:vm_language] = @vm_language if session[:vm_language] != @vm_language
			cookies[:vm_language] = {:value => @vm_language, :expires => 1.year.from_now, :domain => ".vidmap.de"} if cookies[:vm_language] != @vm_language
			
		elsif session[:client_country] && !session[:client_country_evaluated]
			
			case session[:client_country].downcase
				when "de", "ch", "at" then
					@vm_language = "de"
					
				when "gb", "us", "ie" then
					@vm_language = "en"
					
				else
					@vm_language = DEFAULT_LANGUAGE
				
			end
			
			session[:vm_language] = @vm_language
			cookies[:vm_language] = {:value => @vm_language, :expires => 1.year.from_now, :domain => ".vidmap.de"}
			
			session[:client_country_evaluated] = true
		
		else
			reset_language
		end
		
		 if !["de", "en"].index(@vm_language)
		 	reset_language
		 end
		
		fill_player_translation_table
		fill_editor_translation_table 	 
		fill_string_table #bei jedem request für die website!
		
	end	
	
	def fill_player_translation_table
		 
		if !@vm_player_translation_table
			@vm_player_translation_table = {} 
		end
		
		@vm_player_translation_table[:language] = @vm_language
		
		case @vm_language.downcase
			when "de" then
				@vm_player_translation_table[:youtube_video_removed] = "Das Video wurde auf Youtube entfernt! "
			when "en" then
				@vm_player_translation_table[:youtube_video_removed] = "This video has been removed on Youtube!"
		end	
	end
	
	def fill_editor_translation_table
		 
		if !@vm_editor_translation_table
			@vm_editor_translation_table = {} 
		end
		
		@vm_editor_translation_table[:language] = @vm_language
		
		case @vm_language.downcase
			
			when "de" then
				@vm_editor_translation_table[:walker_mode] = "Fussgänger"
				
				@vm_editor_translation_table[:sync_mode] = "Synchronisation"
				@vm_editor_translation_table[:sync_mode_exit] = "Fertig"
				@vm_editor_translation_table[:sync_remove] = "Löschen"
				@vm_editor_translation_table[:sync_cancel] = "Abbrechen"
				@vm_editor_translation_table[:sync_ok] = "Ok"
				@vm_editor_translation_table[:sync_add] = "Hinzufügen"
				@vm_editor_translation_table[:sync_mode_heading] = "Punkt zur Video <-> Strecken Synchronisation hinzufügen?"
				
				@vm_editor_translation_table[:track_play] = "Abspielen"
				@vm_editor_translation_table[:track_edit] = "Editieren"
				@vm_editor_translation_table[:track_delete] = "Löschen"
				
				@vm_editor_translation_table[:route_new] = "Neue Strecke"
				@vm_editor_translation_table[:route_save] = "Strecke speichern"
				@vm_editor_translation_table[:route_cancel] = "Abbrechen"
				
				@vm_editor_translation_table[:drag_to_change_route] = "Hier ziehen zum\nÄndern der Strecke."
				@vm_editor_translation_table[:drag_to_change_route_start] = "Hier ziehen zum Ändern\ndes Streckenanfangs."
				@vm_editor_translation_table[:drag_to_change_route_end] = "Hier ziehen zum Ändern\ndes Streckenendes."
				@vm_editor_translation_table[:click_to_change_sync] = "Hier klicken zum Anpassen\nder Synchronisation."
				@vm_editor_translation_table[:drop_to_place_sync] = "Verschieben zum Anpassen\nder Stelle."
				
				@vm_editor_translation_table[:marker_want_to_delete] = "Punkt entfernen?"
				@vm_editor_translation_table[:marker_delete] = "Löschen"
				
				@vm_editor_translation_table[:hint_create_button] = "Zeichne dein Video jetzt\nauf der Karte ein!"
				@vm_editor_translation_table[:hint_return_button] = "Abbrechen"
				@vm_editor_translation_table[:hint_save_button] = "Speichern"
				
				@vm_editor_translation_table[:video_menue_title] = "Video Menü"
				
				# ERRORS
				@vm_editor_translation_table[:youtube_video_removed] = "Das Video wurde auf Youtube entfernt! "
				
			when "en" then
				@vm_editor_translation_table[:walker_mode] = "Pedestrian"
				
				@vm_editor_translation_table[:sync_mode] = "Synchronization"
				@vm_editor_translation_table[:sync_mode_exit] = "Finish"
				@vm_editor_translation_table[:sync_remove] = "Remove"
				@vm_editor_translation_table[:sync_cancel] = "Cancel"
				@vm_editor_translation_table[:sync_ok] = "Ok"
				@vm_editor_translation_table[:sync_add] = "Add Sync Point"
				@vm_editor_translation_table[:sync_mode_heading] = "Add point to Video <-> Route synchronization?"
				
				@vm_editor_translation_table[:track_play] = "Play"
				@vm_editor_translation_table[:track_edit] = "Edit"
				@vm_editor_translation_table[:track_delete] = "Delete"
				
				@vm_editor_translation_table[:route_new] = "New track"
				@vm_editor_translation_table[:route_save] = "Save track"
				@vm_editor_translation_table[:route_cancel] = "Cancel"
				
				@vm_editor_translation_table[:drag_to_change_route] = "Drag to change route."
				@vm_editor_translation_table[:drag_to_change_route_start] = "Drag to change\nstart of route."
				@vm_editor_translation_table[:drag_to_change_route_end] = "Drag to change\nend of route."
				@vm_editor_translation_table[:click_to_change_sync] = "Click to modify\nsynchronisation point."
				@vm_editor_translation_table[:drop_to_place_sync] = "Drag & drop to modify."
				
				@vm_editor_translation_table[:marker_want_to_delete] = "Delete waypoint?"
				@vm_editor_translation_table[:marker_delete] = "Delete"
				
				@vm_editor_translation_table[:hint_create_button] = "Draw your video onto the map!"
				@vm_editor_translation_table[:hint_return_button] = "Cancel"
				@vm_editor_translation_table[:hint_save_button] = "Save"
				
				@vm_editor_translation_table[:video_menue_title] = "Video Menu"
				
				#ERRORS
				@vm_editor_translation_table[:youtube_video_removed] = "This video has been removed on Youtube!"
			end	
	end
		
	def fill_string_table
		
		if !@vm_string_table
			@vm_string_table = {}
		end
		
		@vm_string_table[:language] = @vm_language
		
		case @vm_language.downcase
			when "de" then
	
				#Titles
				@vm_string_table[:web_title_index] = "Geotagging von Youtube Videos"
				@vm_string_table[:web_title_embed] = "Einbetten - Vidmap"
				@vm_string_table[:web_title_routes] = "Strecken - Vidmap"
				@vm_string_table[:web_title_search] = "Vidmap - Video Suche"
				@vm_string_table[:web_disclaimer_routes] = "Haftungsauschluss - Vidmap"
				@vm_string_table[:web_terms_routes] = "Nutzungsbedingungen - Vidmap"
				@vm_string_table[:web_privacy] = "Datenschutzerklärung -Vidmap"
				
				#Import
				@vm_string_table[:import_no_video_found] = "Fehler: Das Video konnte auf Youtube nicht gefunden werden."
				@vm_string_table[:import_missing_input] = "Fehler: Bitte fülle alle Felder aus."
				
				#Upload
				@vm_string_table[:upload_failed] = "Upload leider fehlgeschlagen! Der Fehler wurde registriert und wird von uns umgehend behandelt. Danke für dein Verständnis!"
				
				#Bookmarks
				@vm_string_table[:bookmark_url] = "http%3A%2F%2Fwww.vidmap.de%2Flang%2Fde"
				@vm_string_table[:bookmark_title] = "Vidmap%3A%20Geo-Tagging%20F%C3%BCr%20Videos!"
				
				#Website General
				@vm_string_table[:meta_lang] = "de"
				@vm_string_table[:feed_lang] = "de-DE"
				
				@vm_string_table[:site_description] = "Vidmap.de ist Geo-Tagging für Videos. Videos werden in ihrem gesamten Verlauf auf einer Karte eingetragen. Die Positionen im Video werden permanent auf der Karte aktualisiert."
				@vm_string_table[:site_keywords] = "vidmap, video geotag, geotagging video, geotaging video, video geotagging, geotags ins video"
				
				@vm_string_table[:disclaimer] = "Haftungsausschluss"
				@vm_string_table[:terms] = "Nutzungsbedingungen"
				@vm_string_table[:beta_partners] = "Partner"
				@vm_string_table[:contact] = "Kontakt"
				@vm_string_table[:solutions] = "<h1>Ein Produkt von Mapi.Works</h1><a href='http://www.mapiworks.com' alt='Link zu Mapiworks.com'>MapiWorks.com</a>"
				
				@vm_string_table[:follow_us] = "Connect"
				@vm_string_table[:language_switch] = '<a title="Click to change language to &quot;English&quot;." href="/lang/en"><img src="/images/flags/en_disabled.gif" alt="English" border="0" /></a>&nbsp;<img src="/images/flags/de.gif" alt="Deutsch" border="0" />'
				@vm_string_table[:language_switch_direct] = '<a title="Click to change language to &quot;English&quot;." href="/web/set_language?language_id=en"><img src="/images/flags/en_disabled.gif" alt="English" border="0" /></a>&nbsp;<img src="/images/flags/de.gif" alt="Deutsch" border="0" />'
				@vm_string_table[:language_switch_template] = '<a title="Click to change language to &quot;English&quot;." href="[#url]"><img src="/images/flags/en_disabled.gif" alt="English" border="0" /></a>&nbsp;<img src="/images/flags/de.gif" alt="Deutsch" border="0" />'
				@vm_string_table[:remember_me] = "Eingeloggt bleiben"
				@vm_string_table[:password] = "Passwort"
				@vm_string_table[:login] = "Anmelden"
				@vm_string_table[:logout] = "Abmelden"
				@vm_string_table[:register] = "Registrieren"
				@vm_string_table[:help] = "Hilfe"
				
				@vm_string_table[:public] = "Öffentlich"
				@vm_string_table[:private] = "Privat"
				@vm_string_table[:cancel] = "Abbrechen"
				@vm_string_table[:saving] = "Sichern"
				@vm_string_table[:more] = "Mehr"
				
				
				#Menu
				@vm_string_table[:menu_home] = "Startseite"
				@vm_string_table[:menu_upload] = "Video Hochladen"
				@vm_string_table[:menu_videos] = "Meine Vidmaps"
				@vm_string_table[:menu_routes] = "Meine Strecken"
				@vm_string_table[:menu_embed] = "Vidmap einbetten"
				@vm_string_table[:menu_account] = "Mein Konto"
				@vm_string_table[:menu_create] = "Neue Vidmap erstellen"
				
				#Mailer
				@vm_string_table[:mailer_reply_to] = "'Vidmap Aktivierung' "
				@vm_string_table[:mailer_subject] = "Aktivierung deines Kontos bei Vidmap.de"
				@vm_string_table[:mailer_from] = "'Vidmap Aktivierung'"
				@vm_string_table[:mailer_mail_sent] = "Eine Aktivierungsmail wurde gesendet an "
			
				#Account
				@vm_string_table[:account_removed] = "Dein Benutzerkonto wurde gelöscht."
				@vm_string_table[:login_failed] = "Login fehlgeschlagen."
				@vm_string_table[:activation_closed] = "Aktivierung zur Zeit nicht möglich."
				
				@vm_string_table[:login_closed] = "Login aufgrund von Wartungsarbeiten im Moment nicht möglich."
				
				@vm_string_table[:account_activated] = "Dein Konto wurde erfolgreich aktiviert."
				@vm_string_table[:activation_failed] = "Aktivierung ungültig."
				@vm_string_table[:registration_closed] =  "Anmeldung zur Zeit nicht möglich."
				@vm_string_table[:account_could_not_create] = "Fehler: Nutzername oder Email existieren bereits."
				@vm_string_table[:account_create_other_error] = "Falsche E-Mail Adresse. Bitte wiederholen."
				@vm_string_table[:logged_out] = "Du bist abgemeldet."		
				
				#Upload
				@vm_string_table[:upload_complete] = "Video Upload erfolgreich!"
				
				#Dictionary
				@vm_string_table[:verbs_read] = "lesen"
				
				#Movement types
				@vm_string_table[:movement_car] = "Auto"
				@vm_string_table[:movement_bike] = "Fahrrad"
				@vm_string_table[:movement_plane] = "Flugzeug"
				@vm_string_table[:movement_foot] = "Fußgänger"
				@vm_string_table[:movement_moto] = "Motorrad"
				@vm_string_table[:movement_ship] = "Schiff"
				@vm_string_table[:movement_train] = "Zug"
				@vm_string_table[:movement_misc] = "Andere"
				
				@vm_string_table[:movement_types] = {"car" => "Auto", "moto" => "Motorrad", "foot" => "Fußgänger", "bike" => "Fahrrad", "plane" => "Flugzeug", "ship" => "Schiff", "train" => "Zug", "misc" => "Andere"}
				@vm_string_table[:movement_expression] = "Fortbewegung"
				
				@vm_string_table[:video_listing_recent] = "Kürzlich Abgespielte Videos"
				@vm_string_table[:video_listing_new] = "Neue Videos"
				@vm_string_table[:video_listing_popular] = "Beliebte Videos"
				@vm_string_table[:video_listing_country] = "Vidmap Länder"
				@vm_string_table[:video_listing_place] = "Videos in "
				
			when "en" then
	
				#Titles
				@vm_string_table[:web_title_index] = "Geotagging of Youtube videos"
				@vm_string_table[:web_title_embed] = "Embed - Vidmap"
				@vm_string_table[:web_title_routes] = "Routes - Vidmap"
				@vm_string_table[:web_title_search] = "Vidmap - Video Search"
				@vm_string_table[:web_disclaimer_routes] = "Disclaimer - Vidmap"
				@vm_string_table[:web_terms_routes] = "Terms - Vidmap"
				@vm_string_table[:web_privacy] = "Privacy Policy -Vidmap"
				
				#Import
				@vm_string_table[:import_no_video_found] = "Error: The video could not be found on Youtube."
				@vm_string_table[:import_missing_input] = "Error: Please fill in all necessary information."
				
				#Upload
				@vm_string_table[:upload_failed] = "Sorry, upload failed! We will look into this issue and will come back to you shortly. Thanks!"
				
				#Bookmarks
				@vm_string_table[:bookmark_url] = "http%3A%2F%2Fwww.vidmap.de%2Flang%2Fen"
				@vm_string_table[:bookmark_title] = "Vidmap%3A%20Geo-Tagging%20For%20Videos!"
				
				#Website General
				@vm_string_table[:meta_lang] = "en"
				@vm_string_table[:feed_lang] = "en-US"
				
				@vm_string_table[:site_description] = "Vidmap.de is geo tagging for videos. Videos are mapped on the globus and played side by side with a google map which synchronously shows the progress of the playing clip."
				@vm_string_table[:site_keywords] = "vidmap, video geotag, geotagging video, geotaging video, video geotagging, geotags ins video"
				
				@vm_string_table[:disclaimer] = "Disclaimer"
				@vm_string_table[:terms] = "Terms of service"
				@vm_string_table[:beta_partners] = "Partners"
				@vm_string_table[:contact] = "Contact"
				@vm_string_table[:solutions] = "<h1>Made by Mapi.Works</h1><a href='http://www.mapiworks.com' alt='Link to Mapiworks.com'>MapiWorks.com</a>"
				
				@vm_string_table[:follow_us] = "Connect"
				@vm_string_table[:language_switch] = '<img src="/images/flags/en.gif" alt="English" border="0" />&nbsp;<a title="Klick zum &Auml;ndern der Sprache in &quot;Deutsch&quot;." href="/lang/de"><img src="/images/flags/de_disabled.gif" alt="Deutsch" border="0" /></a>'
				@vm_string_table[:language_switch_direct] = '<img src="/images/flags/en.gif" alt="English" border="0" />&nbsp;<a title="Klick zum &Auml;ndern der Sprache in &quot;Deutsch&quot;." href="/web/set_language?language_id=de"><img src="/images/flags/de_disabled.gif" alt="Deutsch" border="0" /></a>'
				@vm_string_table[:language_switch_template] = '<img src="/images/flags/en.gif" alt="English" border="0" />&nbsp;<a title="Klick zum &Auml;ndern der Sprache in &quot;Deutsch&quot;." href="[#url]"><img src="/images/flags/de_disabled.gif" alt="Deutsch" border="0" /></a>'
				@vm_string_table[:remember_me] = "Remember me"
				@vm_string_table[:password] = "Password"
				@vm_string_table[:login] = "Sign in"
				@vm_string_table[:logout] = "Logout"
				@vm_string_table[:register] = "Register"
				@vm_string_table[:help] = "Help"
				
				@vm_string_table[:public] = "Public"
				@vm_string_table[:private] = "Private"
				@vm_string_table[:cancel] = "cancel"
				@vm_string_table[:saving] = "Saving"
				
				@vm_string_table[:more] = "More"
				
				#Menu
				@vm_string_table[:menu_home] = "Home"
				@vm_string_table[:menu_upload] = "Video Upload"
				@vm_string_table[:menu_videos] = "My Vidmaps"
				@vm_string_table[:menu_routes] = "My Routes"
				@vm_string_table[:menu_embed] = "Embed Vidmap"
				@vm_string_table[:menu_account] = "My Account"
				@vm_string_table[:menu_create] = "Create a Vidmap"
				
				#Mailer
				@vm_string_table[:mailer_reply_to] = "'Vidmap Activation' "
				@vm_string_table[:mailer_subject] = "Activation of your account at vidmap.de"
				@vm_string_table[:mailer_from] = "'Vidmap Activation'"
				@vm_string_table[:mailer_mail_sent] = "An activation mail has been sent to "
				
				#Account
				@vm_string_table[:account_removed] = "Your account has been removed."
				@vm_string_table[:login_failed] = "Login failed."
				@vm_string_table[:activation_closed] = "Activation currently closed."
				
				@vm_string_table[:login_closed] = "Login temporarily not possible due to maintenance work."
				
				@vm_string_table[:account_activated] = "Your account has been activated."
				@vm_string_table[:activation_failed] = "Invalid activation code."
				@vm_string_table[:registration_closed] =  "Registration currently closed."
				@vm_string_table[:account_could_not_create] = "Error: Login name or Email address already taken."
				@vm_string_table[:account_create_other_error] = "E-mail address possibly wrong. Retry please!"
				@vm_string_table[:logged_out] = "You have been logged out."		
				
				#Upload
				@vm_string_table[:upload_complete] = "Video upload complete!"	
				
				#Dictionary
				@vm_string_table[:verbs_read] = "read"
				
				#Movement types
				@vm_string_table[:movement_car] = "Car"
				@vm_string_table[:movement_bike] = "Bicycle"
				@vm_string_table[:movement_plane] = "Airplane"
				@vm_string_table[:movement_foot] = "Pedestrian"
				@vm_string_table[:movement_moto] = "Motorbike"
				@vm_string_table[:movement_ship] = "Ship"
				@vm_string_table[:movement_train] = "Train"
				@vm_string_table[:movement_misc] = "Other"
				@vm_string_table[:movement_expression] = "Transportation"
				
				@vm_string_table[:movement_types] = {"car" => "Car", "moto" => "Motorbike", "foot" => "Pedestrian", "bike" => "Bicycle", "plane" => "Airplane", "ship" => "Ship", "train" => "Train", "misc" => "Other"}
				
				@vm_string_table[:video_listing_recent] = "Recently Played Videos"
				@vm_string_table[:video_listing_new] = "New Videos"
				@vm_string_table[:video_listing_popular] = "Popular Videos"
				@vm_string_table[:video_listing_country] = "Vidmap Countries"
				@vm_string_table[:video_listing_place] = "Videos in "
		end
	

		
	end	
	
end
