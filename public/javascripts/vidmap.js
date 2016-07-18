/**
 * The MIT License (MIT)
 * Copyright (c) 2014 MAPI.WORKS - Mario Pilz
 * URL: www.mapiworks.com
 * MAIL: mario@mapiworks.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
 * to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
 * and/or sell copies of  the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
 * FITNESS FOR  A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
 * IN THE  SOFTWARE.
 */
 
var DEBUG=false;


var map = false;
var searchBox = false;
var data = false;
var poly, poly_backup = false;
var mark = false;
var syncronisation = false;
var player;
var video_path = false;
var video_timer = false;
var editor_mode = false;
var start_marker, end_marker, poly_edit = false;
var video_id = false;
var youtube_player_ready, youtube_id, youtube_player = false;
var polyline_id = false;
var edit_mode = false;

PIC_MARKER_URLS = {start_marker: "/images/icons/start_marker.png", end_marker: "/images/icons/end_marker.png"};

var polyline_options_track = {
	  clickable: false,
      strokeColor: '#5555FF',
      strokeOpacity: 0.7,
      strokeWeight: 6,
      zIndex: 1
};

var marker_options_picture = {
      flat: true,
      draggable: false,
      zIndex: 2
};

function asyncLoader(scriptName) {
	var d=document,
	h=d.getElementsByTagName('head')[0],
	s=d.createElement('script');
	s.type='text/javascript';
	s.async=true;
	s.src = scriptName;
	h.appendChild(s);
}

/** Browser Check*/
jQuery.browser = {};
jQuery.browser.mozilla = /mozilla/.test(navigator.userAgent.toLowerCase()) && !/webkit/.test(navigator.userAgent.toLowerCase());
jQuery.browser.webkit = /webkit/.test(navigator.userAgent.toLowerCase());
jQuery.browser.opera = /opera/.test(navigator.userAgent.toLowerCase());
jQuery.browser.msie = /msie/.test(navigator.userAgent.toLowerCase());
jQuery.browser.iPad = /ipad/i.test(navigator.userAgent.toLowerCase());


var Ajax = {};
Ajax.Request = function(path, params){
	
	$.post(path, params.parameters, 
	    function(returnedData){
	    	params.onSuccess(returnedData);
	});
}

function debug(txt) {
	if (DEBUG && window.console && typeof console.log != "undefined") {
		console.log(txt);
	}
}

function init_vidmap(video, editor) {
	editor_mode = editor;
	video_id = video;
	init_map();
	if (video != false) load_route(video);
} 

function init_map() {
	var mapOptions = {
	  zoom: 1,
	  maxZoom: 18,
	  center: new google.maps.LatLng(42.553080288955826, -35.859375),
	  mapTypeId: google.maps.MapTypeId.ROADMAP,
	  panControl:false,
	  zoomControl:true,
	  mapTypeControl:false,
	  scaleControl:false,
	  streetViewControl:false,
	  overviewMapControl:false,
	  rotateControl:false,
	  zoomControlOptions: {
          style: google.maps.ZoomControlStyle.SMALL,
          position: google.maps.ControlPosition.LEFT_CENTER
      }  
	};
	
	map = new google.maps.Map(document.getElementById('map_canvas'), mapOptions);
	searchBox = new google.maps.places.SearchBox(document.getElementById('location'));
	
	google.maps.event.addListener(searchBox, 'places_changed', function() {
	    var places = searchBox.getPlaces();
	    map.setCenter(places[0].geometry.location);
	    
	    var bounds = new google.maps.LatLngBounds();
	    bounds.extend(places[0].geometry.location);
	    map.fitBounds(bounds);
	});
	
	google.maps.event.addListener(map, 'click', function(event){
		debug("click");
		
		if (!edit_mode) return false;
		
		if (!start_marker) {
		
			var marker_icon = {
				url: PIC_MARKER_URLS["start_marker"], 
				size: new google.maps.Size(16, 16),
				scaledSize: new google.maps.Size(12, 12),
				origin: new google.maps.Point(0, 0),
				anchor: new google.maps.Point(6, 6)
			};
			
			start_marker = new google.maps.Marker($.extend(marker_options_picture,{position: event.latLng, map: map, icon: marker_icon, opacity: 1, cursor: "hand"}));
			
			$("#cancel").show();
		
		} else if (!end_marker) {
			
			var marker_icon = {
				url: PIC_MARKER_URLS["end_marker"], 
				size: new google.maps.Size(16, 16),
				scaledSize: new google.maps.Size(12, 12),
				origin: new google.maps.Point(0, 0),
				anchor: new google.maps.Point(6, 6)
			};
			
			end_marker = new google.maps.Marker($.extend(marker_options_picture,{position: event.latLng, map: map, icon: marker_icon, opacity: 1, cursor: "hand"}));
			
			poly = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: [start_marker.getPosition(), end_marker.getPosition()]}));
			
			poly_edit = poly;
			
			start_marker.setVisible(false);
			end_marker.setVisible(false);
			
			poly_edit.setEditable(true);
			
			$("#save").show();
		}
		 
	});
	
	google.maps.event.addListenerOnce(map, 'idle', function(){
		debug("idle");
	    $("#gm_attr").append($(".gmnoprint")[0]);
	    $("#gm_attr").append($(".gmnoprint")[0]);
	    
	    if (video_id) {
	    	$("#save").hide();
	    	$("#cancel").hide();
	    	if (editor_mode) $("#edit").show();
	    	$("#location").hide();
	    }   
	});
	
	$("#save").bind("click", function() {

	  var geocode_ok = 0;
	  var geocode_start = false;
	  var geocode_end = false;
	  
	  $("#save").hide();
	  $("#cancel").hide();

	  start_marker.setPosition(poly_edit.getPath().getAt(0));
	  end_marker.setPosition(poly_edit.getPath().getAt(poly_edit.getPath().getLength()-1));
	    
	  var encoder = new PolylineEncoder(18, 2, 0.00001, true);
	  poly_encoded = encoder.dpEncode(poly_edit.getPath().getArray());
	  
	  geocoder = new google.maps.Geocoder();
	  geocoder.geocode({'location': poly_edit.getPoint(0)}, function(results, status) {
	  	
	  	debug(status);
	  	debug(results);
	  	geocode_start = results;
	  	
	  	if (status == "OK") geocode_ok++;
	  	
	  	geocoder.geocode({'location': poly_edit.getPoint(poly_edit.getLength()-1)}, function(results, status) {
	  		debug(status);
	  		debug(results);
	  		geocode_end = results;
	  		
	  		if (status == "OK") geocode_ok++;
	  		
	  		if (geocode_ok == 2) {
	  			$("#edit").show();
	  			$("#location").hide();
	  			
	  			edit_mode = false;
	  			
	  			debug("saving...");
	  			start_marker.setVisible(true);
	  			end_marker.setVisible(true);
	  			poly_edit.setEditable(false);
	  			
	  			poly_backup = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: poly.getPath()}));
	  			poly_backup.setVisible(false);
	  			
	  			var bounds = poly_edit.getBounds();
	  			
	  			var save_path = polyline_id ? '/editor/update_track' : '/editor/create_track';
	  			
	  			new Ajax.Request(save_path, {
	  				parameters: {
	  					video_id: 			video_id,
	  					poly_id:			polyline_id,
	  					end_at_distance: 	poly_edit.getLength(),
	  					encodedPoints: 		poly_encoded.encodedPoints,
	  					encodedLevels:		poly_encoded.encodedLevels,
	  					numLevels: 			18,
	  					zoomFactor:			2,
	  					maptype: 			1,
	  					bound_north:		bounds.getNorthEast().lat(),
	  					bound_south:		bounds.getSouthWest().lat(),
	  					bound_west:			bounds.getSouthWest().lng(),
	  					bound_east:			bounds.getNorthEast().lng(),
	  					geocode:			{	"start": geocode_start.map(function(item){return item.address_components}), 
	  											"end": geocode_end.map(function(item){return item.address_components}),
	  											"formatted_address_start": geocode_start[0].formatted_address,
	  											"formatted_address_end": geocode_end[0].formatted_address
	  										},
	  					
	  					waypoints: 			JSON.stringify(poly_edit.getPath().getArray().map(function(item){return {"align":true, "latlng":{"lat":item.lat(), "lng":item.lng()}}}))
	  				},
	  			 	onSuccess: function(transport) {
	  			 		debug("Saved!");
	  			 		debug(transport);
	  			 	}
	  			});
	  			
	  		} else {
	  		
	  			debug("save canceled...");
	  			$("#save").show();
	  			$("#cancel").show();
	  			
	  			edit_mode = true;
	  				
	  			poly = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: poly_backup.getPath()}));
	  			poly_edit = poly;
	  			
	  			start_marker.setPosition(poly_edit.getPath().getAt(0));
	  			end_marker.setPosition(poly_edit.getPath().getAt(poly_edit.getPath().getLength()-1));
	  			
	  		}
	  	})
	  })
	  
	  
	    
	});
	
	$("#cancel").bind("click", function() {
	  debug("cancel");
	  
	  $("#save").hide();
	  $("#cancel").hide();
	  $("#edit").show();
	  $("#location").hide();
	  
	  edit_mode = false;
	  
	  poly_edit.setEditable(false);
	  
	  poly.setMap(null);
	  
	  
	  if (poly_backup) {
	  	
	  	poly = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: poly_backup.getPath().getArray()}));
	  	poly_edit = poly;
	  	
		start_marker.setPosition(poly_edit.getPath().getAt(0));
		end_marker.setPosition(poly_edit.getPath().getAt(poly_edit.getPath().getLength()-1));
		  
		start_marker.setVisible(true);
		end_marker.setVisible(true);
	  } else {
	  	start_marker = false;
	  	end_marker = false;
	  }
	  
	});
	
	$("#edit").bind("click", function() {
	  debug("edit");
	  
	  if (start_marker) start_marker.setVisible(false);
	  if (end_marker) end_marker.setVisible(false);
	  
	  $("#save").show();
	  $("#cancel").show();
	  $("#edit").hide();
	  $("#location").show();
	  
	  edit_mode = true;
	  
	  setPlaybackOn(false);
	  
	  if (poly_edit) poly_edit.setEditable(true);	  
	});
}

function update_track(currentTime, duration) {
	
	
	if (!poly) return;
	
	var length = poly.getLength();
	var last_sync_index = false
	var next_sync_index = false
	
	var latlng = poly.getPoint(currentTime/duration * length);

	
	if (mark == false) {

		var image = {
			url: PIC_MARKER_URLS["end_marker"], 
			size: new google.maps.Size(16, 16),
			scaledSize: new google.maps.Size(12, 12),
			origin: new google.maps.Point(0, 0),
			anchor: new google.maps.Point(7, 7)
		};
		
		mark = new google.maps.Marker($.extend(marker_options_picture,{position: latlng, map: map, icon: image, opacity: 1}));
		
		//mark = new google.maps.Marker($.extend(marker_options_picture, {position: latlng, map: map, icon: image, opacity: 1}));
			
	} else {
		
		var current_progress = currentTime/duration
		latlng = poly.getPoint(current_progress * length);
		
		
		if (syncronisation && syncronisation.length>0) {
		
			var sync_1 = syncronisation[0];
			var sync_2 = syncronisation[0];
			
			$.each(syncronisation, function(index, sync) {
				
				sync_1 = sync_2;
				sync_2 = sync;
				
				if (sync["time"]>=currentTime) {	
					return false;
				}
			});
			
			if ((sync_2["time"]-sync_1["time"]) != 0) {
				var t = (currentTime-sync_1["time"]) / (sync_2["time"]-sync_1["time"])
				var p1 = sync_1["distance"]
				var p2 = sync_2["distance"]
				var dist = p1 * (1-t) + p2 * (t)
				latlng = poly.getPoint(dist);
			}
		}
				
		mark.setPosition(latlng);
		map.panTo(latlng);
	}


}

function onVideoProgress(e) {

	update_track(this.currentTime, this.duration)
		
}


function onPlayerReady(event) {
		debug("Youtube Player ready");
		
		youtube_player_ready = true;
		
		youtube_player = event.target;
		
		if (editor_mode) setPlaybackOn(false);
		 
		if (!jQuery.browser.iPad && !editor_mode) {
			event.target.playVideo();
		}
		
		
	}
	
function onPlayerStateChange(event) {
	
	var state = player.getPlayerState();
	
	if (state == 1 && !video_timer) {
		
		video_timer = setInterval(function () {
			update_track(player.getCurrentTime(), player.getDuration())
			
		}, 500);
		
	} else if (state != 1 && video_timer) {
		window.clearInterval(video_timer);
		video_timer = false;
	}
}
	
function onYouTubeIframeAPIReady() {
	debug("Youtube API ready");
	
	player = new YT.Player('video_youtube', {
	  	height: '360',
		width: '640',
		videoId: video_path,
		playerVars: {'autoplay': 0, 'controls': 1, 'rel': 0, 'wmode': 'transparent'},
		events: {
			'onReady': onPlayerReady,
			'onStateChange': onPlayerStateChange
		}
	});
	
	$("#video_youtube").show();
}

function load_video(video_id) {

	new Ajax.Request('/player/getVideoAS', {
		parameters: { video_id: video_id},
	 	onSuccess: function(transport) {
	 		debug(transport);
	 		
	 		var data = transport.video;
	 		
	 		
	 		if (data.youtube) {
	 			 			
	 			video_path = data.filename_flash;
	 			youtube_id = video_path;
	 			
	 			asyncLoader("https://www.youtube.com/iframe_api");
	 			$("#video_youtube").show();
	 			            
	 		} else {
	 			
	 			youtube_id = false;
	 			
	 			video_path = "/videos/" + data.filename_flash.replace(".flv","") + ".mp4";
		 		$("#video")[0].src = "/videos/" + data.filename_flash.replace(".flv","") + ".mp4";
		 		if (!editor_mode) $("#video")[0].play();
		 		
		 		$("#video").bind('timeupdate', onVideoProgress);
		 		
		 		$("#video").show();
		 	}
		 	
		 	new Ajax.Request('/player/stats', {
		 		parameters: { type: "playback", video_id: data.id},
		 		onSuccess: function(transport) {}
		 	});
		 	
	 	}
	 });
	
	
}

function load_route(video_id) {

	new Ajax.Request('/player/getSelectedPolylinesAS', {
		parameters: { videos: "["+video_id+"]"},
	 	onSuccess: function(transport) {
	 		debug(transport);
	 		
	 		syncronisation = transport.sync;
	 		
	 		data = transport;
	 		
	 		polyline_id = data.poly_id;
	 		
	 		// LOAD_VIDEO
	 		load_video(video_id); 
	 		
	 		if (data.route_available) {
		 		var track = google.maps.geometry.encoding.decodePath(data.polylines[0].poly_points.replace(/\\\\/g,"\\"));
		 		var bounds = new google.maps.LatLngBounds(new google.maps.LatLng(data.bounds.south, data.bounds.west), new google.maps.LatLng(data.bounds.north, data.bounds.east));
	
		 		map.fitBounds(bounds);
		 		poly = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: track}));
		 		poly_edit = poly;
		 		poly_backup = new google.maps.Polyline($.extend(polyline_options_track, {map: map, path: track}));
				poly_backup.setVisible(false);
		 		
		 		var marker_icon = {
		 			url: PIC_MARKER_URLS["start_marker"], 
		 			size: new google.maps.Size(16, 16),
		 			scaledSize: new google.maps.Size(12, 12),
		 			origin: new google.maps.Point(0, 0),
		 			anchor: new google.maps.Point(6, 6)
		 		};

		 		
		 		start_marker = new google.maps.Marker($.extend(marker_options_picture,{position: poly.getPath().getAt(0), map: map, icon: marker_icon, opacity: 1, cursor: "hand"}));
		 		
		 		end_marker = new google.maps.Marker($.extend(marker_options_picture,{position: poly.getPath().getAt(poly.getPath().getLength()-1), map: map, icon: marker_icon, opacity: 1, cursor: "hand"}));
		 	}	
	 		
	 				
	 	}
	 });

}

function youtube_enabled() {
	return youtube_id ? true : false;
}

function youtube_ready() {
	return youtube_enabled() && youtube_player_ready;
}

function get_video() {
	return $("#video")
}

function setPlaybackOn(play) {

	if (youtube_enabled()) {	
		play ? youtube_player.playVideo() : youtube_player.pauseVideo();
	} else {	
		play ? get_video()[0].play() : get_video()[0].pause();
	}

}
