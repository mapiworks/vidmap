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
 
module WebHelper

def self.parseDuration8601(str)

	obj = str.scan(/\d+/)
	duration = 0
	
	case obj.size
	when 1
		duration = obj[0].to_i
	when 2
		duration = obj[0].to_i*60 + obj[1].to_i
	when 3
		duration = obj[0].to_i*60*60 + obj[1].to_i*60 + obj[2].to_i
	else
	end
	
	return duration
	
end

def get_sidebar_listing_data
	
		#Frequent cities
		@cities = Route.find_by_sql("select locality as name, count(locality) as times from ((select routes.id, start_locality_" + @vm_language + " as locality from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0) union (select routes.id, end_locality_" + @vm_language + " as locality from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0)) as result group by locality having locality is not null ORDER BY times desc limit 60")
		
		#Frequent countries
		@countries = Route.find_by_sql("select country, count(country) as times from ((select routes.id, start_country_code as country from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0) union (select routes.id, end_country_code as country from routes inner join videos on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0)) as result group by country having country is not null order by times desc")
	
		#Frequent movement types
		@movements = Video.find_by_sql("SELECT movement_type as name, count(movement_type) as times FROM videos inner join routes on routes.video_id = videos.id where videos.public=1 AND videos.blocked=0 AND videos.disabled = 0 group by movement_type ORDER BY times desc")
		
		#Length histogram
		#@distances = Route.find_by_sql("SELECT sum(end_at_distance<=1000)/count(end_at_distance) as freq0, sum(end_at_distance>1000 AND end_at_distance<=5000)/count(end_at_distance) as freq1000, sum(end_at_distance>5000 AND end_at_distance<=10000)/count(end_at_distance) as freq5000, sum(end_at_distance>10000 AND end_at_distance<=50000)/count(end_at_distance) as freq10000, sum(end_at_distance>50000)/count(end_at_distance) as freq50000 FROM routes")[0]
	end
	
	def generateTagCloud(data, sortitem, translation = false)
		
		css_clouds = 6.0
		max = 1.0
		data.each{ |item|
			#item.times = 1 + (rand * 15).ceil
			max = item.times.to_i if item.times.to_i > max
		}
		
		cloud = ""
		data.each{ |item|
			if !translation
				item_name = item.name
			else
				item_name = translation[item.name] || "???"
			end
			cloud = cloud + '<a href="' + url_for(:controller => 'web', :action => 'video_listing', :sort =>sortitem, :find => item.name, :language_id => @vm_language) + '" class="cloud' + (item.times.to_f / (max / css_clouds)).ceil.to_s + '">' + item_name + '</a> '
		}
		return cloud
	end
	
	def decryptGeo(placemark)
		details = []
		places = ""
		
		if placemark["CountryName"]
			places = h(placemark["CountryName"])
			details.push(places)
		end
		
		if placemark["AdministrativeAreaName"]
			if placemark["SubAdministrativeAreaName"] && placemark["SubAdministrativeAreaName"] != placemark["AdministrativeAreaName"]
				#places = "(" + placemark["SubAdministrativeAreaName"] + " / " + placemark["AdministrativeAreaName"] + ", " + places + ")"
				places = "(" + h(placemark["AdministrativeAreaName"]) + ", " + places + ")"
			else
				places = "(" + h(placemark["AdministrativeAreaName"]) + ", " + places + ")"
			end
			details.push(places)
		else
			places = "(" + places + ")"
		end
		
		if placemark["LocalityName"]
			places = h(placemark["LocalityName"]) + " " + places
			details.push(places)
		end
		
		if placemark["ThoroughfareName"]
			places = h(placemark["ThoroughfareName"]) + ", " + places
			details.push(places)
		end
		
		return {:details => details, :places => places}
	end
	
	def formatExistanceSince(days, translation)
		years = days.to_i / 365
		months = days.to_i / 30
		weeks = days.to_i / 7
		days = days.to_i
		
		if years > 0
			return years.to_s + " " + (years == 1 ? translation[:year] : translation[:years])
		elsif	 months > 0
			return months.to_s + " " + (months == 1 ? translation[:month] : translation[:months])
		elsif weeks > 0
			return weeks.to_s + " " + (weeks == 1 ? translation[:week] : translation[:weeks])
		else
			return translation[:new] if days == 0
			return days.to_s + " " + (days == 1 ? translation[:day] : translation[:days])
		end
	end
	
	def formatDuration(duration)
		hours = (duration/60/60).floor
		minutes = (duration/60%60).floor
		seconds = (duration%60).floor.to_s
		
		result = ""
		
		if hours > 0 
			hours = hours.to_s
			hours = hours.length < 2 ? "0" + hours : hours
			result = hours + ":"
		end
		
		minutes = minutes.to_s
		minutes = minutes.length < 2 ? "0" + minutes : minutes
		result << minutes + ":"
		
	
		seconds = seconds.length < 2 ? "0" + seconds : seconds
		result << seconds
		
		return result
	end
	
	def formatDistance(distance, language="de")
		if language == "de"
			return ((distance.to_f / 100).ceil.to_f / 10).to_s + " km"
		else
			return ((distance.to_f*0.62137 / 100).ceil.to_f / 10).to_s + " mi"
		end
	end
	
	def formatSpeed(speed_in_meters_per_second, language="de")
		if language == "de"
			return (3.6*speed_in_meters_per_second.to_f).ceil.to_s + " km/h"
		else
			return (0.62137*3.6*speed_in_meters_per_second.to_f).ceil.to_s + " mph"
		end
	end
	
	def formatRouteSubtitle(data, captured_in, captured_from_to_in_country, captured_from_in_country_to_in_country)
		
		result = ""
		
		if !data.nil? && data.start_locality && data.start_country && data.end_locality && data.end_country 
	
			if data.start_locality == data.end_locality 
				result = captured_in.sub("<city>", data.start_locality).sub("<country>", data.start_country)
			else 
					if data.start_country == data.end_country 
							result = captured_from_to_in_country.sub("<city1>", data.start_locality).sub("<city2>", data.end_locality).sub("<country>", data.start_country)
					else 
							result = captured_from_in_country_to_in_country.sub("<city1>", data.start_locality).sub("<country1>", data.start_country).sub("<city2>", data.end_locality).sub("<country2>", data.end_country)
					end 
			end 
	
		end 

	end
	
end
