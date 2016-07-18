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
 
/**
* @class The root class of the application.
*/
var VM = Class.create();

VM.prototype = {
	/** @constructor */
	initialize: function() {
		
		this.MAP = new MAP();
		this.VID = new VID();
		this.MUTEX = new MUTEX();
		this.API = new API();
		this.ACTIVITY = new ACTIVITY();
		
		// Block map until flash managed to connect to red5
		this.ACTIVITY.addIndicator(); 
		new PeriodicalExecuter(function(pe) {							
		  if (VM.isready()) {
		  	VM.ACTIVITY.removeIndicator(); 
			pe.stop();
		  }
		}, 1);
		

	},
	
	isready: function() {
		try {
			if (VM.VID.getMovie(VM.VID.playerID).nVersion() && VM.MAP.map.isLoaded()) ;
			return true;
		} catch (error) {
			return false
		}
	},
	/** Init the application and web interface */
	InitControls:	function() {
		this.MAP.Init();
		this.VID.Init();
	}, 

	/** 
	*	Fetch an object from the server
	*	@param url The server address to contact.
	*	@param params Additional parameters wish are passed to Ajax.Request(url, params).
	*	@param variable The name of the variable whish receives the return value of the request.
	*	@param async Defines the type of the request (true = asynchronous, false = synchronous).
	*	@param call_function The name of the function wish should be called when the request has finished successfully.
	*	@param wait_message The message which will show up in the activity indicator.
	*/
		getAjaxValue: function(url, params, variable, asynch, call_function) {
			
			debug("getAjaxValue S");
			
			var parameters = {
					method: 'get',
					asynchronous: asynch,
					evalJS: 'force',
					parameters: "js_return_var=" + variable + "&" + params,
					onFailure: function(response) {
						debug("getAjaxValue_onFailure");
						//alert('Error ' + response.status + ' -- ' + response.statusText);
					},
					onException: function(requ, exception) {
						debug("ajax onException:" + exception);
					},
					onComplete: function(response) { 

							debug("getAjaxValue result:" + response.responseText);
							eval(response.responseText);
							
							if (!isUndefined(call_function)) eval(call_function);
							debug("getAjaxValue_onSuccess E");
							
					}
					
			};
			
			new Ajax.Request(url, parameters);
			
			debug("getAjaxValue E");
		},
	
	/**  
	*	Send an object to the server
	*	@param url The server address to contact.
	*	@param params Additional parameters wish are passed to Ajax.Request(url, params).
	*	@param async Defines the type of the request (true = asynchronous, false = synchronous).
	*	@param call_function The name of the function wish should be called when the request has finished successfully.
	*/
	setAjaxValue: function(url, params, asynch, call_function) {
		
		var parameters = {
				method: 'get',
				asynchronous: asynch,
				parameters: params,
				onFailure: function(response) {
						alert('Error ' + response.status + ' -- ' + response.statusText);
						result = false;
				},
				onSuccess: function(response) {
					if (!isUndefined(call_function)) {eval(call_function);}
				}
		};
		var myAjax = new Ajax.Request(url, parameters);
	}	
};



MAP  = Class.create();

/** 
* @class A class to provide map functionality
* @memberOf VM
*	@scope VM.MAP
*/
MAP.prototype = {
	/** @constructor */
	initialize: function() {
		this.map = false;
		
		this.playingPolyline = false;
		this.reducedPlayingPolyline = false;
		
		this.playingPolylineShadow = false;
		this.playingMovementType = false;
		this.receivedPolylines = false;
		this.receivedRouteData = false;
		this.receivedVideoInfo = false;
		this.visiblePolylineOverlays = new Object();
		this.ePolylineClickedPoint = false;
		this.previewPolyline = false;
		this.previewRoutes = false;
		
		this.isPlaying = false;
		this.dragging = false;
		this.waitWhileZooming = false;
		this.waitWhileMoving = false;
		
		this.currentPlayingPolylineDistance = 0;

		this.startMarker = false;
		this.endMarker = false;
		this.playMarker = false;
		this.playShadowMarker = false;
		this.trackingTimer = false;
		
		this.adsManager = false;
		this.trackTimeMeasure = false;
		
		this.trackingDelay =  1000;
		
		this.CONFIG = {poly_color:"#2238FF", poly_thickness: 8, poly_alpha: 0.7, poly_highlight_color:  "#FF0000", poly_highlight_thickness: 4, poly_highlight_alpha: 0.5, poly_highlight_shadow_thickness: 15, poly_highlight_shadow_alpha: 0.2};
				
	},
	/**  */
	Init: function(name, counter, action) {
	"bound_north:nomunge, bound_east:nomunge, bound_south:nomunge, bound_west:nomunge";

		debug("VM.MAP.Init S");
		
		try {	
		  if (GBrowserIsCompatible()) {
			  		
					this.map = new GMap2(document.getElementById("mapID"));
					this.map.polylines = new Object();
					
					this.trackTimeMeasure = new Date().getTime();
			
					this.map.addControl(new GSmallZoomControl());
					this.map.addMapType(G_PHYSICAL_MAP);
					this.map.addMapType(G_HYBRID_MAP);
					
					this.map.addControl(new GHierarchicalMapTypeControl(true));
					this.map.enableScrollWheelZoom();
					this.map.enableContinuousZoom();

					eval('bound_north = <%=@routes_bound_north%>');
					eval('bound_east = <%=@routes_bound_east%>');
					eval('bound_south = <%=@routes_bound_south%>');
					eval('bound_west = <%=@routes_bound_west%>');				
									
					var poly_bounds = new GLatLngBounds(new GLatLng(bound_north, bound_west), new GLatLng(bound_south, bound_east));
					this.map.setCenter(poly_bounds.getCenter(), this.map.getBoundsZoomLevel(poly_bounds));
					
					this.map.setMapType(G_NORMAL_MAP);
					
					this.map.getDragObject().setDraggableCursor("default");
					this.map.getDragObject().setDraggingCursor("pointer"); 
		 
					GEvent.addListener(this.map,'click', VM.MAP.e_map_click);
					GEvent.addListener(this.map,'mouseout', function(event){VM.MAP.map.savePosition();});
					GEvent.addListener(this.map,'zoomend', VM.MAP.e_map_zoomend);
					GEvent.addListener(this.map,'zoomstart', VM.MAP.e_map_zoomstart);
					GEvent.addListener(this.map,'dragend', VM.MAP.e_map_dragend);
					GEvent.addListener(this.map,'dragstart', VM.MAP.e_map_dragstart);
					
					this.adsManager = new GAdsManager(this.map, "ca-pub-0847622212746173", {maxAdsOnMap: 5, minZoomLevel: 1, channel: "<%=@api_adsense_channel%>"});
        			this.adsManager.enable();

					
					this.load_polylines();
					this.load_joints();
					
		  }
		} catch (err) {alert("Could not start Google Maps:" + err);}
		
		debug("VM.MAP.Init E");
	},
	
	//When the map is clicked
	e_map_click: function(point) {
		

	},

//When the map starts continuous zoom (mouse wheel)
	e_map_zoomstart: function() {
		//console.log("zoomstart");
		
		if (VM.VID.isPlaying() && !VM.MAP.waitWhileZooming) {
			VM.VID.setCallback("Resume", "VM.MAP.trackVideo", "");
			VM.VID.pauseVideo();
			VM.MAP.waitWhileZooming = true;
		}
	},	
	
	//When the map was zoomed
	e_map_zoomend: function() {
		//console.log("zoomend");
		
		if (VM.MAP.waitWhileZooming) {
			//resume playback
			VM.VID.resumeVideo();
			VM.MAP.waitWhileZooming = false;
		}
		
		//console.log("new zoom level: " + VM.MAP.map.getZoom());
		if ( VM.MAP.playingPolyline) VM.MAP.updateReducedPlayingPolyline();
	},	
	
	
	e_map_dragstart: function() {
		if (VM.VID.isPlaying() && !VM.MAP.waitWhileMoving) {
			VM.VID.setCallback("Resume", "VM.MAP.trackVideo", "");
			VM.VID.pauseVideo();
			VM.MAP.waitWhileMoving = true;
		}
	},	
	
	e_map_dragend: function() {
		if (VM.MAP.waitWhileMoving) {
			VM.VID.resumeVideo();
			VM.MAP.waitWhileMoving = false;
		}
	},	
	
	updateReducedPlayingPolyline: function() {
		VM.MAP.reducedPlayingPolyline = VM.MAP.playingPolyline.reduce();
		VM.MAP.reducedPlayingPolyline.vmType = "playing reduced";
	},
	
	getVehicleImage: function(icon_variant) {
		var result = "";
		
		switch(icon_variant) {
			case "knob":
					result = "http://"+vidmap_api_path+"/images/marker_knob.png";	
				break;				
			case "foot":
					result = "http://"+vidmap_api_path+"/images/marker_foot.png";		
				break;
			case "car":
					result = "http://"+vidmap_api_path+"/images/marker_car.png";				
				break;
			case "bike":
					result = "http://"+vidmap_api_path+"/images/marker_motorbike.png";	
				break;	
			case "bike_hover":
					result = "http://"+vidmap_api_path+"/images/marker_motorbike_hover.png";	
				break;		
			case "train":
					result = "http://"+vidmap_api_path+"/images/marker_train.png";				
				break;
			default:			
				break;
		}	
		
		return result;
	},
	
	getIcon: function(icon_type, icon_variant) {
	
			var baseIcon = new GIcon();
			var result = false;
	
		
		if (icon_type == "player") {
	
				baseIcon.iconSize=new GSize(26,26);
				baseIcon.iconAnchor=new GPoint(13,13);
				baseIcon.infoWindowAnchor=new GPoint(13,13);
				baseIcon.dragCrossImage = "http://"+vidmap_api_path+"/images/null.png";
				baseIcon.maxHeight = 8;
	
			switch(icon_variant) {
				case "knob":
						baseIcon.iconSize=new GSize(10,10);
						baseIcon.iconAnchor=new GPoint(5,5);
						baseIcon.infoWindowAnchor=new GPoint(5,5);					
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_knob.png");	
					break;				
				case "foot":
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_foot.png");		
					break;
				case "car":
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_car.png");				
					break;
				case "bike":
						baseIcon.iconSize=new GSize(50,32);
						baseIcon.iconAnchor=new GPoint(25,16);
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_motorbike.png");	
					break;	
				case "train":
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_train.png");				
					break;
				default:
						result = new GIcon(baseIcon);				
					break;
			}
			
		} else if (icon_type == "joint") {

			switch(icon_variant) {
				case "start":
						baseIcon.iconSize=new GSize(20,20);
						baseIcon.iconAnchor=new GPoint(10,10);
						baseIcon.infoWindowAnchor=new GPoint(10,10);				
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/joint_play.png");			
					break;
				case "stop":
						baseIcon.iconSize=new GSize(8,8);
						baseIcon.iconAnchor=new GPoint(4,4);
						baseIcon.infoWindowAnchor=new GPoint(4,4);				
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/joint_stop.png");				
					break;
				case "cross":
						baseIcon.iconSize=new GSize(14,14);
						baseIcon.iconAnchor=new GPoint(7,7);
						baseIcon.infoWindowAnchor=new GPoint(7,7);				
						result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/joint_crossing.png");				
					break;
				default:
						result = new GIcon(baseIcon);				
			}			
			
		} else {
				result = new GIcon(baseIcon);			
		}
		
		return result;
	},
	load_polylines: function() {
		VM.ACTIVITY.addIndicator();
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getPolylines', '', "VM.MAP.receivedPolylines", "true", "VM.MAP.savePolylines(VM.MAP.receivedPolylines); VM.MAP.drawPolylines(); VM.ACTIVITY.removeIndicator();");
		
	},
	
	load_joints: function() {
		VM.ACTIVITY.addIndicator();
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getJoints', '', "VM.MAP.receivedJoints", "true", "VM.MAP.drawJoints(VM.MAP.receivedJoints); VM.ACTIVITY.removeIndicator();");
	},

	savePolylines: function(polylines) {

		var encodedPolyline = false;
		
		//alert("Received poyls:" + polylines.size());
		
		for (var i=0; i<polylines.size(); i++) {
			
			if (isUndefined(polylines[i])) continue;
			
			//console.log(polylines[i]);
			encodedPolyline = new GPolyline.fromEncoded({
				color: VM.MAP.CONFIG["poly_color"],
				weight: VM.MAP.CONFIG["poly_thickness"],
				opacity: VM.MAP.CONFIG["poly_alpha"],
				points: polylines[i].poly_points,
				levels: polylines[i].poly_levels,
				zoomFactor: polylines[i].poly_zoomFactor,
				numLevels: polylines[i].poly_numLevels 
			}); 
			
			encodedPolyline.vmType = "normal";
			//Appending id from database
			encodedPolyline.id = polylines[i].id;
			
			VM.MAP.map.polylines[encodedPolyline.id] = encodedPolyline;

		}

	},
	
	drawPolylines: function() {
		
		try {
			
			var polylist = Object.values(VM.MAP.map.polylines);
			
			for (var i=0; i<polylist.size(); i++) {
				
				
				GEvent.addListener(polylist[i],'click', VM.MAP.e_polyline_click);
				GEvent.addListener(polylist[i],'mouseover', function(){});
				
				try {
					VM.MAP.map.addOverlay(polylist[i]);
				} catch(err) {
					//console.dir(err);	
				}
	
			}
		} catch(e) {alert(e);}

	},
	
	drawJoints: function(joints) {
		var jointMarker;
		
		try {
			for (var i=0; i<joints.size(); i++) {
				
				switch (joints[i].joint_type) {
					case "start":
						jointMarker = new GMarker(new GLatLng(joints[i].lat, joints[i].lng), {zIndexProcess:orderStartMarkers, icon: VM.MAP.getIcon("joint", "start"), draggable:false, bouncy:false}); 
						GEvent.addListener(jointMarker,'click', VM.MAP.e_jointmarker_click);
						GEvent.addListener(jointMarker,'mouseover', function(){this.setImage("http://"+vidmap_api_path+"/images/joint_play_highlight.png")});
						GEvent.addListener(jointMarker,'mouseout', function(){this.setImage("http://"+vidmap_api_path+"/images/joint_play.png")});
						break;
					case "stop":
						jointMarker = new GMarker(new GLatLng(joints[i].lat, joints[i].lng), {zIndexProcess:orderStopMarkers, icon:VM.MAP.getIcon("joint", "stop"),draggable:false,bouncy:false,clickable:false}); 
						break;
					case "cross":
						jointMarker = new GMarker(new GLatLng(joints[i].lat, joints[i].lng), {zIndexProcess:orderCrossMarkers, icon:VM.MAP.getIcon("joint", "cross"),draggable:false,bouncy:false}); 
						GEvent.addListener(jointMarker,'click', VM.MAP.e_jointmarker_click);
						break;
					default:
						alert("Unknown joint type");
					break;
				}
				
				
				//Appending id from database
				jointMarker.id = joints[i].id;
				VM.MAP.map.addOverlay(jointMarker);
	
			}
		} catch(e) {alert(e);}
	},

	loadTrackData: function(video_id) {
		
		VM.MAP.map.enableAllPolylines();
		VM.MAP.map.removeAllPolylineOverlays();
		VM.MAP.currentPlayingPolylineDistance = 0;
		
		VM.VID.currentVideoID = video_id; 
		
		VM.ACTIVITY.addIndicator();
		VM.MUTEX.Init('Load Video', 3, "VM.MAP.initTracking(VM.MAP.receivedRouteData, VM.MAP.receivedVideoSpeed, VM.MAP.receivedVideoInfo); VM.ACTIVITY.removeIndicator();");
		
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideoInfo', 'video_id=' + video_id, "VM.MAP.receivedVideoInfo", true, "VM.MUTEX.Dec('Load Video')" );
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideoSpeed', 'video_id=' + video_id, "VM.MAP.receivedVideoSpeed", true, "VM.MUTEX.Dec('Load Video')" );
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getRouteData', 'video_id=' + video_id, "VM.MAP.receivedRouteData", true, "VM.MUTEX.Dec('Load Video')" );
	},
	
	
	initTracking: function(receivedRouteData, receivedVideoSpeed, receivedVideoInfo) {
		VM.MAP.map.removeAllPolylineOverlays();

		//Build playingPolyline:
		var playingPolylinePoints = VM.MAP.assemblePlayingPolylinePoints(receivedRouteData);
		VM.MAP.playingPolyline = new GPolyline(playingPolylinePoints, VM.MAP.CONFIG["poly_highlight_color"], VM.MAP.CONFIG["poly_highlight_thickness"], VM.MAP.CONFIG["poly_highlight_alpha"]);
		VM.MAP.playingPolyline.vmType = "playing";
		
		VM.MAP.playingPolylineShadow = new GPolyline(playingPolylinePoints, VM.MAP.CONFIG["poly_highlight_color"], VM.MAP.CONFIG["poly_highlight_shadow_thickness"], VM.MAP.CONFIG["poly_highlight_shadow_alpha"]);
		VM.MAP.playingPolylineShadow.vmType = "playing shadow";
		
		VM.VID.playingVideoSpeed = receivedVideoSpeed;
		
		VM.VID.currentVideoFile = receivedVideoInfo.filename_flash; 
		VM.VID.currentVideoDuration = receivedVideoInfo.duration;
		VM.MAP.playingMovementType = receivedVideoInfo.movement_type;
		
		VM.MAP.map.addOverlay(VM.MAP.playingPolylineShadow);
		VM.MAP.map.addOverlay(VM.MAP.playingPolyline);
		GEvent.addListener(VM.MAP.playingPolyline,'mouseover', function(){});
		GEvent.addListener(VM.MAP.playingPolyline,'click', VM.MAP.e_playing_polyline_click);
		
		//console.log("generate reduced polyline - start");
		//Polyline can only be reduced to visible resolution if polyline overlay was added to the map previously 
		VM.MAP.updateReducedPlayingPolyline();
		//console.log("generate reduced polyline - end");
		
		VM.VID.setCallback("Buffer.Full", "VM.MAP.startTracking", "");
		VM.VID.setCallback("Video.End", "VM.MAP.onVideoStop", "");
		VM.VID.setDuration(VM.VID.currentVideoDuration);		

		
		
		if (VM.MAP.ePolylineClickedPoint) {
			//console.log("Clicked polyline. File: " + VM.VID.currentVideoFile);
			// set video position by reevaluating ePolylineClickedPoint and see its intersection with the newly generated playing polyline
			var intersection = VM.MAP.reducedPlayingPolyline.intersectPoint(VM.MAP.ePolylineClickedPoint);
			VM.MAP.currentPlayingPolylineDistance = intersection.atDistance; 
			VM.MAP.setPlayMarker(intersection.point);
			VM.VID.playVideo(VM.VID.currentVideoFile, VM.MAP.getCurrentTime());	
		
		}	else {
			//console.log("Clicked joint. File: " + VM.VID.currentVideoFile);
			VM.MAP.currentPlayingPolylineDistance = 0;
			VM.MAP.setPlayMarker(VM.MAP.reducedPlayingPolyline.getVertex(0));
			VM.VID.playVideo(VM.VID.currentVideoFile, 0);	
		}
	},	
	
	startTracking: function() {
		VM.MAP.trackVideo();
	},

	trackVideo: function() {
		
		if (VM.VID.isPlaying()) {
			try {
				VM.MAP.updateTracker();
				
				if (!isUndefined(VM.MAP.trackTimeMeasure)) {
					
					if (!isUndefined(VM.MAP.trackingDelay))
						VM.MAP.trackingDelay = (Math.abs(new Date().getTime() - VM.MAP.trackTimeMeasure) + VM.MAP.trackingDelay) / 2;
					else
						VM.MAP.trackingDelay = Math.abs(new Date().getTime() - VM.MAP.trackTimeMeasure);
						
					VM.MAP.trackingDelay  = Math.min(VM.MAP.trackingDelay, 1000);
				}
				
				VM.MAP.trackingTimer = window.setTimeout('VM.MAP.trackVideo()', VM.MAP.trackingDelay);
				VM.MAP.trackTimeMeasure = new Date().getTime();
			} catch(err) {alert(err.message)}
			
			
		}
	},

	updateTracker:function(forcedDistance) {
		
			if (!isUndefined(forcedDistance)) {
				VM.MAP.currentPlayingPolylineDistance = forcedDistance;
				//console.log("Tracking distance forced to " + VM.MAP.currentPlayingPolylineDistance);
			}	else {
				VM.MAP.currentPlayingPolylineDistance = VM.MAP.getCurrentDistance(); //ppl good
			}
			
			//console.log("Tracking distance  is " + VM.MAP.currentPlayingPolylineDistance);
			
			if (VM.VID.currentVideoDuration>0) {
				VM.MAP.currentPlayingPolylinePosition = VM.MAP.reducedPlayingPolyline.getPoint(VM.MAP.currentPlayingPolylineDistance); // Fehler
			} else {
				VM.MAP.currentPlayingPolylinePosition = VM.MAP.reducedPlayingPolyline.getPoint(0);
			}
			
			//console.log("Current currentPlayingPolylinePosition: (" + VM.MAP.currentPlayingPolylinePosition.x + " , " + VM.MAP.currentPlayingPolylinePosition.y + ")")
			
			if (VM.MAP.currentPlayingPolylinePosition && VM.MAP.map.getCenter() && (VM.MAP.map.getCenter().x != VM.MAP.currentPlayingPolylinePosition.x || VM.MAP.map.getCenter().y != VM.MAP.currentPlayingPolylinePosition.y)) {
				VM.MAP.setPlayMarker(VM.MAP.currentPlayingPolylinePosition);
				VM.MAP.map.panTo(new GLatLng(VM.MAP.currentPlayingPolylinePosition.y,VM.MAP.currentPlayingPolylinePosition.x));
			}		
	},

	
	loadNearbyVideos: function(currentVideoID, pointOfInterest) {
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getNearbyVideos', 'current_video_id=' + currentVideoID + '&pointOfInterestLat=' + pointOfInterest.lat() + '&pointOfInterestLng=' + pointOfInterest.lng(), "VM.MAP.receivedNearbyVideos", true, "VM.MAP.previewRoutes=VM.MAP.receivedNearbyVideos[0].routes; VM.VID.loadThumbs(VM.MAP.receivedNearbyVideos[0].videos)" );
	},
	
	removeVideoHighlight: function() {
		if (VM.MAP.previewPolyline) {
			GEvent.clearInstanceListeners(VM.MAP.previewPolyline);
			VM.MAP.map.removeOverlay(VM.MAP.previewPolyline);
		}
		VM.MAP.previewPolyline = false;
		
		VM.MAP.map.returnToSavedPosition();
	},
	
	highlightVideo: function(video_id) {
		
		
		//debug("highlight  for video_id "+video_id);
		
		// Check for existing highlight & remove if necessary xxx
		VM.MAP.removeVideoHighlight();
		
		VM.MAP.previewPolylinePoints = [];
		VM.MAP.ePolylineClickedPoint = false;
		
		for (var i=0; i<VM.MAP.previewRoutes.length; i++) {
			//console.log("Checking against video_id "+VM.MAP.previewRoutes[i].video_id);
			if (VM.MAP.previewRoutes[i].video_id == video_id) {
				VM.MAP.previewPolylinePoints.push(VM.MAP.previewRoutes[i]);
			}
		}
		
		
		
		// Assemble final polyline from route points. Assuming that the underlying polylines are in cache already!
		VM.MAP.previewPolyline = new GPolyline(VM.MAP.assemblePlayingPolylinePoints(VM.MAP.previewPolylinePoints), VM.MAP.CONFIG["poly_highlight_color"], VM.MAP.CONFIG["poly_highlight_thickness"], VM.MAP.CONFIG["poly_highlight_alpha"]);
		VM.MAP.previewPolyline.vmType = "preview";
		
		
		
		// Add highlight to map
		VM.MAP.map.addOverlay(VM.MAP.previewPolyline);
		
		VM.MAP.map.setZoom(VM.MAP.map.getBoundsZoomLevel(VM.MAP.previewPolyline.getBounds()));
   		VM.MAP.map.panTo(VM.MAP.previewPolyline.getBounds().getCenter());
	},
	
	// called from AS3 when video arrives at its end
	onVideoStop: function() {
		//console.log("onVideoStop");
		//Asume we are at the end of the playing polyline
		VM.MAP.map.savePosition();
		VM.VID.setActivityIndicator();
		VM.MAP.loadNearbyVideos(VM.VID.currentVideoID, VM.MAP.playingPolyline.getVertex(VM.MAP.playingPolyline.getVertexCount()-1));
		VM.MAP.resetPlayer();	
		
	},	
	
	resetPlayer: function() {
		
		//console.log("resetPlayer");
		
		// kill tracker
		window.clearTimeout(VM.MAP.trackingTimer);
		
		// remove overlays and markers
		GEvent.clearInstanceListeners(VM.MAP.playingPolyline);
		VM.MAP.map.removeOverlay(VM.MAP.playingPolyline);
		VM.MAP.playingPolyline = false;
		VM.MAP.reducedPlayingPolyline = false;
		
		VM.MAP.map.removeOverlay(VM.MAP.playingPolylineShadow); 
			
		VM.MAP.currentPlayingPolylineDistance = 0;		
		
		if (VM.MAP.playMarker) {
			VM.MAP.map.removeOverlay(VM.MAP.playMarker);
			VM.MAP.playMarker = false;
		}
	},	

	// called from JS when track changes or video arrives at its end
	stopVideo: function() {
		//console.log("stopVideo");
		
		VM.VID.stopVideo();		
		VM.MAP.resetPlayer();
	},


	getCurrentDistance: function() { 
		
		var currentTime = VM.VID.getTime();
		var syncPoints = VM.VID.getBoundingSyncPointsByTime(currentTime);
		
		var result = syncPoints.last.distance + (currentTime-syncPoints.last.time) * (syncPoints.next.distance-syncPoints.last.distance)/(syncPoints.next.time-syncPoints.last.time);
		
		//console.log("Current bounding sync-points: " + syncPoints.last.time + " s / " + syncPoints.next.time + " s. Current time: " + currentTime);
		return result;
		
	},
	
	getCurrentTime: function() { 
		
		var currentDistance = VM.MAP.currentPlayingPolylineDistance;
		var syncPoints = VM.VID.getBoundingSync(currentDistance);
		
		var result = (currentDistance - syncPoints.last.distance ) * (syncPoints.next.time-syncPoints.last.time)/(syncPoints.next.distance-syncPoints.last.distance) + syncPoints.last.time;
		
		//console.log("Current bounding sync-points: " + syncPoints.last.distance + " m / " + syncPoints.next.distance + " m. Current time: " + currentDistance);
		return result;
		
	},
	
	listVideo: function(videos, lat, lng) { 
		
		try {
			var info_text = '<div id="videoListHeading"><p>Available videos:</p></div>';
			var processedVideos = new Array();
			
			VM.MAP.stopVideo();
			
			VM.MAP.map.enableAllPolylines();
			VM.MAP.map.removeAllPolylineOverlays();
			
			VM.MAP.currentPlayingPolylineDistance = 0;
			
			for (var i=0; i<videos.size(); i++) {
				
				if (processedVideos.indexOf(videos[i].id) < 0) {
					processedVideos.push(videos[i].id);
					info_text += '<div id="videoListItem" style="cursor:pointer;" onclick="VM.MAP.loadTrackData(\'' + videos[i].id + '\'); VM.MAP.map.closeInfoWindow();"><img id="videoListImage" src="'+VM.MAP.getVehicleImage(videos[i].movement_type)+'"/><div id="videoListText">'+ videos[i].name + ' (' + formatDuration(videos[i].duration) + ' min)' + '</div><br class="clearfloat" /></div>';
				}
				
				if (videos[i].video_direction > 0) {
					videos[i].at_distance = !videos[i].at_distance ? videos[i].start_at_distance : videos[i].at_distance;	
					VM.MAP.map.getPolyline(videos[i].polyline_id).addPolylineOverlay(VM.MAP.CONFIG["poly_highlight_color"], VM.MAP.CONFIG["poly_highlight_thickness"], VM.MAP.CONFIG["poly_highlight_alpha"], videos[i].at_distance, videos[i].end_at_distance);
				} else {
					videos[i].at_distance = !videos[i].at_distance ? videos[i].end_at_distance : videos[i].at_distance;			
					VM.MAP.map.getPolyline(videos[i].polyline_id).addPolylineOverlay(VM.MAP.CONFIG["poly_highlight_color"], VM.MAP.CONFIG["poly_highlight_thickness"], VM.MAP.CONFIG["poly_highlight_alpha"], videos[i].start_at_distance, videos[i].at_distance);			
				}
	
				//VM.MAP.map.getPolyline(videos[i].polyline_id).disable();
			}
			
			VM.MAP.map.openInfoWindowHtml(new GLatLng(lat,lng), info_text);
			GEvent.addListener(VM.MAP.map.getInfoWindow(),'closeclick', function() {VM.MAP.map.enableAllPolylines(); VM.MAP.map.removeAllPolylineOverlays();});
		} catch(e) {alert(e);}
	},	

	//When a joint is clicked
	e_jointmarker_click: function() {
		
		VM.VID.clearThumbs();
		
		VM.ACTIVITY.addIndicator();
		
		VM.MAP.ePolylineClickedPoint = false;
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideofromJoint', 'joint_id=' + this.id, "VM.MAP.receivedRouteData", true, "VM.MAP.listVideo(VM.MAP.receivedRouteData," + this.getPoint().y + "," + this.getPoint().x + "); VM.ACTIVITY.removeIndicator();" );
		
	},	
	
	//When a polyline is clicked
	e_playing_polyline_click: function(point) {
		
		VM.VID.clearThumbs();
		
		if (VM.VID.isPlayingOrPaused()) { 
				
				// Find nearest point on playing polyline
				var intersection = VM.MAP.reducedPlayingPolyline.intersectPoint(point);
			
				//console.log("New distance is: " + intersection.atDistance + " / " + this.getLength());
				
				VM.MAP.currentPlayingPolylineDistance = intersection.atDistance;
				VM.VID.setVideoPosition(VM.MAP.getCurrentTime()); 
				VM.MAP.updateTracker(VM.MAP.currentPlayingPolylineDistance);
				return true;		
		}	
		
	},
	
	//When a polyline is clicked
	e_polyline_click: function(point) {
	
		
		//console.log(this.vmType);
		VM.VID.clearThumbs();
		
		VM.ACTIVITY.addIndicator();
		
		// To calculate starting distance
		VM.MAP.ePolylineClickedPoint = point;
		// Find nearest point on clicked polyline
		var intersection = this.intersectPoint(point); // Genauigkeit in Abhängigkeit vom Zoomlevel setzten (hier einzige Möglichkeit für speedup) xxx
		
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideofromPolyline', 'polyline_id=' + this.id + '&atDistance=' + intersection.atDistance, "VM.MAP.receivedRouteData", true, "VM.MAP.listVideo(VM.MAP.receivedRouteData," + point.y + "," + point.x + "); VM.ACTIVITY.removeIndicator();" );
	
	},
	

	/* Setup of playmarker (video position indicator)
	*/
	setPlayMarker: function(position) {

		if (!VM.MAP.playMarker) {
			VM.MAP.playMarker = new GMarker(position,{zIndexProcess:orderPlayerMarkers, icon:VM.MAP.getIcon("player", VM.MAP.playingMovementType), draggable:true, bouncy:true, dragCrossMove:true});
			GEvent.addListener(VM.MAP.playMarker,'dragend',this.e_playmarker_dragend);
			GEvent.addListener(VM.MAP.playMarker,'dragstart', this.e_playmarker_dragstart);
			GEvent.addListener(VM.MAP.playMarker,'drag',this.e_playmarker_drag);
			GEvent.addListener(VM.MAP.playMarker,'click',this.e_playmarker_click);
			GEvent.addListener(VM.MAP.playMarker,'mousedown',this.e_playmarker_mousedown);
			
			GEvent.addListener(VM.MAP.playMarker,'mouseover', function(){this.setImage(VM.MAP.getVehicleImage(VM.MAP.playingMovementType + "_hover"))});
			GEvent.addListener(VM.MAP.playMarker,'mouseout', function(){this.setImage(VM.MAP.getVehicleImage(VM.MAP.playingMovementType))});
						
			VM.MAP.map.addOverlay(VM.MAP.playMarker);
		} else {
			//console.log("Moving marker");
			VM.MAP.playMarker.setLatLng(new GLatLng(position.y,position.x));
			//VM.MAP.map.panTo(new GLatLng(position.y,position.x));
		}	
		
	},

	/* On mousedown of playmarker (video position indicator)
	*/
	e_playmarker_mousedown: function() {

		//console.log("e_playmarker_mousedown");
	
	
	},

	/* On click of playmarker (video position indicator)
	*/
	e_playmarker_click: function() {

		//console.log("e_playmarker_click");
		VM.VID.setCallback("Resume", "VM.MAP.trackVideo", "");
		VM.VID.toggleVideo();

	},

	/* On dragstart of playmarker (video position indicator)
	*/
	e_playmarker_dragstart: function() {
		VM.MAP.dragging = true;
		VM.MAP.isPlaying = VM.VID.isPlaying();
		VM.VID.pauseVideo();
		//console.log("e_playmarker_dragstart: VM.VID.isPlaying:" + VM.VID.isPlaying());
		//this.hide();
	},
	
	/* On dragend of playmarker (video position indicator)
	*/
	e_playmarker_dragend: function() {
		
		//console.log("e_playmarker_dragend");
		
		
		//this.show();
		
		// Set playmarker to new position
		VM.MAP.playMarker.setLatLng(VM.MAP.playShadowMarker.getPoint());
		
		// Remove and destroy
		VM.MAP.map.removeOverlay(VM.MAP.playShadowMarker);
		VM.MAP.playShadowMarker = false;
		
		
		//if (Prototype.Browser.Opera) {
			VM.VID.setVideoPosition(VM.MAP.getCurrentTime());
		//}
			
		if (VM.MAP.isPlaying) {
			VM.VID.setCallback("Resume", "VM.MAP.trackVideo", "");
			VM.VID.resumeVideo(); 
		}
		
		debug("distance: " +  VM.MAP.getCurrentDistance() + " ,time: " +  VM.MAP.getCurrentTime());
		
		VM.MAP.dragging = false;
	},
	
	/* On drag of playmarker (video position indicator)
	*/	
	e_playmarker_drag: function() {
		
		var closestPoint = VM.MAP.reducedPlayingPolyline.intersectPoint(this.getPoint());
		
		if (!VM.MAP.playShadowMarker) {
			
			VM.MAP.playShadowMarker = new GMarker(closestPoint.snapPoint,{zIndexProcess:orderPlayerMarkers, icon:VM.MAP.getIcon("player", "knob"),draggable:false,bouncy:false, dragCrossMove:false, autoPan:false});
			VM.MAP.map.addOverlay(VM.MAP.playShadowMarker);
			VM.MAP.playShadowMarker.setLatLng(closestPoint.snapPoint);
		} else {
			
			VM.MAP.playShadowMarker.setLatLng(closestPoint.snapPoint);
			VM.MAP.currentPlayingPolylineDistance = closestPoint.atDistance;

			/*
			if (!Prototype.Browser.Opera) {
				VM.VID.setVideoPosition(VM.MAP.getCurrentTime());
			}
			*/

		}			
	},
	
	assemblePlayingPolylinePoints: function(receivedRouteData) {
		var points = false;
		var result = new Array(); 

		for (var i=0; i<receivedRouteData.size(); i++) {
			points = VM.MAP.map.getPolyline(receivedRouteData[i].polyline_id).getPoints(receivedRouteData[i].start_at_distance, receivedRouteData[i].end_at_distance);
			
			if (receivedRouteData[i].video_direction < 0)
				points = points.reverse();
			
			result = result.concat(points);	
		}		
		
		return result;
	}	
};
	
	




VID  = Class.create();

/** 
* @class A class to provide video functionality
* @memberOf VM
*	@scope VM.VID
*/
VID.prototype = {
	/** @constructor */
	initialize: function() {
		
		this.playerID = "playerID";
		this.playingVideoSpeed = false;
		this.currentVideoFile = null;
		this.currentVideoID = null;
		this.currentVideoDuration = null;
		
		
	},
	/**  */
	Init: function(name, counter, action) {
	},
	
	/** This is a javascript handler for the player */
	getMovie: function(playerID) {
		//console.log("swfobject: " +  swfobject);
		//console.log("swfobject.getObjectById("+playerID+"): " +  swfobject.getObjectById(playerID));
		
		try {
			return swfobject.getObjectById(playerID);
		} catch(e) {}
		/*
		else	{      
			if(navigator.appName.indexOf('Microsoft') != -1)
			{
				return window[playerID];
			}
			else
			{
				return document[playerID];
			}
		}
		*/
	},	
	
	showHint: function(type) { 
		this.getMovie(this.playerID).nShowHint(type); 
	},
	
	disableHints: function() { 
		this.getMovie(this.playerID).nDisableHints(); 
	},	
	
	setCallback: function(name, func, param) { 
		this.getMovie(this.playerID).nSetCallback(name, func, param); 
	},
	
	loadThumbs: function(videos) {
		//console.log("Now calling AS to load thumbs");
		this.getMovie(this.playerID).nLoadThumbs(videos);
	},
	
	clearThumbs: function() {
		try {
			this.getMovie(this.playerID).nClearThumbs();
		} catch(e) {}
	},
	
	setActivityIndicator: function() {
		this.getMovie(this.playerID).nSetActivityIndicator(true);
	},
	
	getTime: function() { 
		return this.getMovie(this.playerID).nGetTime(); 
	},
	
	getDuration: function() { 
		return this.getMovie(this.playerID).nGetDuration(); 
	},
	setDuration: function(duration) { 
		return this.getMovie(this.playerID).nSetDuration(duration); 
	},	
	setVideoPosition: function(pos) { 
		return this.getMovie(this.playerID).nSeek(pos);
	},
	
	playVideo: function(file, pos, len) { 
		return this.getMovie(this.playerID).nPlay(file, pos, len);
	},
	
	pauseVideo: function() { 
		return this.getMovie(this.playerID).nPause();
	},
	resumeVideo: function() { 
		return this.getMovie(this.playerID).nResume();
	},	
	stopVideo: function() { 
		return this.getMovie(this.playerID).nStop();
	},	
	disconnect: function() { 
		return this.getMovie(this.playerID).nDisconnect();
	},	
	toggleVideo: function() { 
		return this.getMovie(this.playerID).nToggle(); 
	},	
	
	isPlaying: function() { 
		return this.getMovie(this.playerID).nIsPlaying();
	},
	isPlayingOrPaused: function() { 
		//console.log("isPlayingOrPaused: " + this.getMovie(this.playerID).nIsPlayingOrPaused());
		return this.getMovie(this.playerID).nIsPlayingOrPaused();
	},	
	
	getBoundingSyncPointsByTime: function(currentTime) { 
		
		// init sync points
		var result = new Object();
		result.last = new Object();
		result.next = new Object();
		result.last.distance = 0;
		result.last.time = 0;
		result.next.distance = VM.MAP.playingPolyline.getLength();
		result.next.time = this.getDuration();

		// No sync points available
		if (!this.playingVideoSpeed || this.playingVideoSpeed == "")	return result;
		
		// Current time is before first sync point
		if (this.playingVideoSpeed[0].time > currentTime) {
			result.next.distance = this.playingVideoSpeed[0].distance;
			result.next.time = this.playingVideoSpeed[0].time;			
			return result;	
		}
		
		
		for (var i=this.playingVideoSpeed.size()-1; i>=0; i--) {
			
			// First sync point found
			if (currentTime >= this.playingVideoSpeed[i].time) {
				result.last.distance = this.playingVideoSpeed[i].distance;
				result.last.time = this.playingVideoSpeed[i].time;				
				
				// Next sync point found
				if (i < this.playingVideoSpeed.size()-1) {
					result.next.distance = this.playingVideoSpeed[i+1].distance;
					result.next.time = this.playingVideoSpeed[i+1].time;						
				}
				
				break;
			}

		}
		
		return result;
		
	},
	
	getBoundingSync: function(currentDistance) { 
		
		// init sync points
		var result = new Object();
		result.last = new Object();
		result.next = new Object();
		result.last.distance = 0;
		result.last.time = 0;
		result.next.distance = VM.MAP.playingPolyline.getLength();
		result.next.time = this.getDuration();

		// No sync points available
		if (!this.playingVideoSpeed || this.playingVideoSpeed == "")	return result;
		
		// Current time is before first sync point
		if (this.playingVideoSpeed[0].distance > currentDistance) {
			result.next.distance = this.playingVideoSpeed[0].distance;
			result.next.time = this.playingVideoSpeed[0].time;			
			return result;	
		}
		
		
		for (var i=this.playingVideoSpeed.size()-1; i>=0; i--) {
			
			// First sync point found
			if (currentDistance >= this.playingVideoSpeed[i].distance) {
				result.last.distance = this.playingVideoSpeed[i].distance;
				result.last.time = this.playingVideoSpeed[i].time;				
				
				// Next sync point found
				if (i < this.playingVideoSpeed.size()-1) {
					result.next.distance = this.playingVideoSpeed[i+1].distance;
					result.next.time = this.playingVideoSpeed[i+1].time;						
				}
				
				break;
			}

		}
		
		return result;
		
	}	
	

};

MUTEX  = Class.create();

/** 
* @class A class to provide simple mutex functionality
* @memberOf VM
*	@scope VM.MUTEX
*/
MUTEX.prototype = {
	/** @constructor */
	initialize: function() {
		names = new Object();
	},
	/**  */
	Init: function(name, counter, action) {

		if (isUndefined(names[name]))	names[name] = new Object();
			
		names[name].counter = counter;
		names[name].action = action;

	},
	/**  */
	Dec: function(name) {
		names[name].counter --;
		if (names[name].counter == 0) eval(names[name].action);
	}
};


API  = Class.create();

API.prototype = {
	/** @constructor */
	initialize: function() {

	},
	
	EXEC: function(action, video_id) {
	
		switch (action) {
			case "START_VIDEO":
				VM.VID.clearThumbs();		
				VM.MAP.ePolylineClickedPoint = false;
				VM.MAP.map.closeInfoWindow();
				VM.MAP.stopVideo();
				VM.MAP.loadTrackData(video_id);
				break;
			default:
				break;
		}
		
	}
};

ACTIVITY  = Class.create();

ACTIVITY.prototype = {
	/** @constructor */
	initialize: function() {
		this.blockID = "vm_activity_indicator";
		this.stakes = 0;
	},
	
	addIndicator: function() {
		
		
		if (!$(this.blockID)) {
			$(vidmap_box_id).insert('<div id="'+this.blockID+'" class="vm_activity_layer"><img class="vm_activity_image" src="http://'+vidmap_api_path+'/images/ajax-loader.gif" align="middle" /></div>');
		} else {
			$(this.blockID).show();
		}
		
		this.stakes++;
	},
	
	removeIndicator: function() {
		
		if ($(this.blockID)) {
			this.stakes--;
			
			if (this.stakes <= 0) {
				$(this.blockID).hide();
				this.stakes = 0;
			}
			
		}
	}
};



