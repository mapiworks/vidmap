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
			
			this.GLOBALS = new Object();
			this.MAP = new MAP();
			//this.VID = new VID();
			//this.MUTEX = new MUTEX();		
	
		},
		/** Init the application and web interface */
		InitControls:	function() {
			this.MAP.Init();
			//this.VID.Init();
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
		
		var parameters = {
				method: 'GET',
				asynchronous: asynch,
				parameters: params + "&js_return_var=" + variable,
				onFailure: function(response) {
						alert('Error ' + response.status + ' -- ' + response.statusText);
				},
				onSuccess: function(response) { 
					//response.responseText = response.responseText.replace(/},]/g, "}]");
					try {
						//$("encoded").insert("<br>Return: " + response.responseText);
						//aaa=response.responseText.evalJSON();
						
						//window[variable]  = response.responseText.evalJSON();
						//eval(variable) = response.responseText.evalJSON();
						//VM.GLOBALS[variable] = response.responseText;
						//$("encoded").update(VM.GLOBALS[variable][0].poly_points);
						
						//$("encoded").update(window[variable]);
						//eval(variable+"="+response.responseText);
						
						//response.responseText = response.responseText.replace("\\", "\\\\");

						eval(response.responseText);
						//$("encoded").insert("<br>VM.GLOBALS.receivedPolylines is: " + VM.GLOBALS.receivedPolylines[0].poly_points);
						
						!isUndefined(call_function) ? eval(call_function) : false;
					} catch(err) {alert(err)}
				},
				onLoading: function() {
	
				}

		}
		new Ajax.Request(url, parameters);
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
					!isUndefined(call_function) ? eval(call_function) : false;
				}
		}
		new Ajax.Request(url, parameters);
	}	
}



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
		this.playingPolylineShadow = false;
		this.playingMovementType = false;
		this.visiblePolylineOverlays = new Object();
		this.ePolylineClickedPoint = false;
		this.previewPolyline = false;
		this.previewRoutes = false;
		
		this.isPlaying = false;
		this.dragging = false;
		
		this.currentPlayingPolylineDistance = 0;

		this.startMarker = false;
		this.endMarker = false;
		this.playMarker = false;
		this.playShadowMarker = false;
		this.trackingTimer = false;
		
		this.waypoints = new Array();
		this.waypoints = new Array();
		
		this.direction = false;
		this.directionGPoly = false;
		this.directionPoints = new Array();
		this.directionEncoded = false;
		
	},
	/**  */
	Init: function(name, counter, action) {

		try {	
		  if (GBrowserIsCompatible()) {
			  
	
				
					this.map = new GMap2(document.getElementById("map"));
					this.map.polylines = new Object();
			
					this.map.addControl(new GSmallMapControl());
					this.map.addMapType(G_PHYSICAL_MAP);
					this.map.addControl(new GMapTypeControl(true));
					this.map.enableScrollWheelZoom();
					this.map.enableContinuousZoom();

				
					
					this.map.setCenter(new GLatLng(46.53902664609408,9.707794189453125), 9);
					
					//this.map.setMapType(G_HYBRID_MAP);
					
					this.map.getDragObject().setDraggableCursor("default");
					this.map.getDragObject().setDraggingCursor("pointer"); 
		 			
					this.direction= new GDirections(VM.MAP.map, null);
					GEvent.addListener(this.map,'click', VM.MAP.e_map_click);
					GEvent.addListener(this.direction, "load", VM.MAP.onGDirectionsLoad);
	
					this.load_polylines();
					this.load_joints();
					
		  }
		} catch (err) {alert("Could not start Google Maps:" + err)}
	},
	
	//When the map is clicked
	e_map_click: function(overlay,point){
		
		if (VM.MAP.waypoints.size() >= 20) return false;
		
		VM.MAP.waypoints.push(point);
		if (VM.MAP.waypoints.size()>1) {
			VM.MAP.direction.loadFromWaypoints(VM.MAP.waypoints, {preserveViewport:true});
		}
	},

	onGDirectionsLoad: function() {
		
		VM.MAP.directionGPoly = this.getPolyline();
		encoder = new PolylineEncoder(18, 2, 0.00001, true);
		
		VM.MAP.directionPoints = new Array();
		
		
		for (var i=0; i< VM.MAP.directionGPoly.getVertexCount(); i++) {
			VM.MAP.directionPoints.push(VM.MAP.directionGPoly.getVertex(i));
		}
		
		VM.MAP.directionEncoded = encoder.dpEncode(VM.MAP.directionPoints); 
	
		$("encoded").update("Points: <br>" + VM.MAP.directionEncoded.encodedPointsLiteral + "<p></p>Levels: <br>" + VM.MAP.directionEncoded.encodedLevels  + '<p></p>Length:' + VM.MAP.directionGPoly.getLength() + '<br>North:' + VM.MAP.directionGPoly.getBounds().getNorthEast().y + '<br>East:' + VM.MAP.directionGPoly.getBounds().getNorthEast().x + '<br>South:' + VM.MAP.directionGPoly.getBounds().getSouthWest().y + '<br>West:' + VM.MAP.directionGPoly.getBounds().getSouthWest().x);
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
			//baseIcon.maxHeight = 0;
		
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
				case "train":
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_train.png");				
					break;
				case "foot_shadow":
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_shadow_foot.png");		
					break;
				case "car_shadow":
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_shadow_car.png");				
					break;
				case "train_shadow":
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/marker_shadow_train.png");				
					break;
				default:
					result = new GIcon(baseIcon);				
			}
			
		} else if (icon_type == "joint") {

			switch(icon_variant) {
				case "start":
					baseIcon.iconSize=new GSize(16,16);
					baseIcon.iconAnchor=new GPoint(8,8);
					baseIcon.infoWindowAnchor=new GPoint(8,8);				
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/jointgreen.png");			
					break;
				case "stop":
					baseIcon.iconSize=new GSize(8,8);
					baseIcon.iconAnchor=new GPoint(4,4);
					baseIcon.infoWindowAnchor=new GPoint(4,4);				
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/jointred.png");				
					break;
				case "cross":
					baseIcon.iconSize=new GSize(14,14);
					baseIcon.iconAnchor=new GPoint(7,7);
					baseIcon.infoWindowAnchor=new GPoint(7,7);				
					result = new GIcon(baseIcon, "http://"+vidmap_api_path+"/images/jointpurple.png");				
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
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getPolylines', '', "VM.GLOBALS.receivedPolylines", true, "VM.MAP.savePolylines(); VM.MAP.drawPolylines()");
		
	},
	
	load_joints: function() {
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getJoints', '', "VM.GLOBALS.receivedJoints", true, "VM.MAP.drawJoints()");
		
	},

	savePolylines: function() {
		
		
		var polylines = VM.GLOBALS.receivedPolylines;
		var encodedPolyline = false;
		
		try {
			//$("encoded").insert("<br>" + typeof polylines);
			//$("encoded").insert("<br>Polylines#: " + polylines.size());
		} catch(err) {alert(err);}
		
		
		for (var i=0; i<polylines.size(); i++) {
			
			if (isUndefined(polylines[i])) continue;
			
			//console.log(polylines[i]);
			encodedPolyline = new GPolyline.fromEncoded({
				color: "#0060FF",
				weight: 8,
				opacity: 0.7,
				points: polylines[i].poly_points,
				levels: polylines[i].poly_levels,
				zoomFactor: polylines[i].poly_zoomFactor,
				numLevels: polylines[i].poly_numLevels 
			}); 
			
			//$("encoded").insert("<br>poly_points: #"+polylines[i].poly_points + "#");
			//$("encoded").insert("<br>poly_levels: #"+polylines[i].poly_levels + "#");
			//$("encoded").insert("<br>poly_zoomFactor:"+polylines[i].poly_zoomFactor);
			//$("encoded").insert("<br>poly_numLevels:"+polylines[i].poly_numLevels);
								
			//Appending id from database
			encodedPolyline.id = polylines[i].id;
			
			VM.MAP.map.polylines[encodedPolyline.id] = encodedPolyline;

		}

	},
	
	drawPolylines: function() {
		
		var polylist = Object.values(VM.MAP.map.polylines);
		
		for (var i=0; i<polylist.size(); i++) {
			//$("encoded").insert("<br>Drawing Polyline #:" +i);
			
			//console.log(polylist[i]);
			poly = polylist[i];
			GEvent.addListener(polylist[i],'click', VM.MAP.e_polyline_click);
			
			try {
				VM.MAP.map.addOverlay(polylist[i]);
			} catch(err) {
				alert(err);	
			}

		}

	},
	
	drawJoints: function(joints) {
		
		var joints = VM.GLOBALS.receivedJoints;
		
		for (var i=0; i<joints.size(); i++) {
			
			switch (joints[i].joint_type) {
				case "start":
					jointMarker = new GMarker(new GLatLng(joints[i].lat, joints[i].lng), {zIndexProcess:orderStartMarkers, icon: VM.MAP.getIcon("joint", "start"), draggable:false, bouncy:false}); 
					GEvent.addListener(jointMarker,'click', VM.MAP.e_jointmarker_click);
					break;
				case "stop":
					jointMarker = new GMarker(new GLatLng(joints[i].lat, joints[i].lng), {zIndexProcess:orderStopMarkers, icon:VM.MAP.getIcon("joint", "stop"),draggable:false,bouncy:false}); 
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
	},

	loadTrackData: function(video_id) {
		
		VM.MAP.map.enableAllPolylines();
		VM.MAP.map.removeAllPolylineOverlays();
		VM.MAP.currentPlayingPolylineDistance = 0;
		
		VM.VID.currentVideoID = video_id; 
				
		VM.MUTEX.Init('Load Video', 3, "VM.MAP.initTracking()");
		
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideoInfo', 'video_id=' + video_id, "receivedVideoInfo", true, "VM.MUTEX.Dec('Load Video')" );
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideoSpeed', 'video_id=' + video_id, "receivedVideoSpeed", true, "VM.MUTEX.Dec('Load Video')" );
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getRouteData', 'video_id=' + video_id, "receivedRouteData", true, "VM.MUTEX.Dec('Load Video')" );
	},
	
	initTracking: function() {
		
		var receivedRouteData = VM.GLOBALS["receivedRouteData"];
		var receivedVideoSpeed = VM.GLOBALS["receivedVideoSpeed"];
		var receivedVideoInfo = VM.GLOBALS["receivedVideoInfo"];
		
		VM.MAP.map.removeAllPolylineOverlays();

		//Build playingPolyline:
		var playingPolylinePoints = VM.MAP.assemblePlayingPolylinePoints(receivedRouteData);
		VM.MAP.playingPolyline = new GPolyline(playingPolylinePoints, "#FF8000", 9, 1);
		VM.MAP.playingPolylineShadow = new GPolyline(playingPolylinePoints, "#FF9090", 18, 0.4);
		
		VM.VID.playingVideoSpeed = receivedVideoSpeed;
		
		VM.VID.currentVideoFile = receivedVideoInfo.filename_flash; 
		VM.VID.currentVideoDuration = receivedVideoInfo.duration; 
		VM.MAP.playingMovementType = receivedVideoInfo.movement_type;
		
		VM.MAP.map.addOverlay(VM.MAP.playingPolylineShadow);
		VM.MAP.map.addOverlay(VM.MAP.playingPolyline);

		VM.VID.setCallback("Buffer.Full", "VM.MAP.startTracking", "");
		VM.VID.setCallback("Video.End", "VM.MAP.onVideoStop", "");
		VM.VID.setDuration(VM.VID.currentVideoDuration);		

		// set video position
		if (VM.MAP.ePolylineClickedPoint) {
			VM.MAP.currentPlayingPolylineDistance = VM.MAP.playingPolyline.intersectPoint(VM.MAP.ePolylineClickedPoint).atDistance;
			VM.MAP.set_playMarker(VM.MAP.playingPolyline.getPoint(VM.MAP.currentPlayingPolylineDistance));
			VM.VID.playVideo(VM.VID.currentVideoFile, VM.MAP.getCurrentTime());	
		}	else {
			VM.MAP.currentPlayingPolylineDistance = 0;
			VM.MAP.set_playMarker(VM.MAP.playingPolyline.getPoint(VM.MAP.currentPlayingPolylineDistance));
			VM.VID.playVideo(VM.VID.currentVideoFile);	
		}
		
		
		
	},	
	
	startTracking: function() {
		VM.MAP.trackVideo();
	},

	trackVideo: function() {
		
		if (VM.VID.isPlaying()) {
			try {
				VM.MAP.updateTracker();
			} catch(err) {}
			
			VM.MAP.trackingTimer = window.setTimeout('VM.MAP.trackVideo()',250);
		}
	},

	updateTracker:function(forcedDistance) {
		
			if (!isUndefined(forcedDistance))
				VM.MAP.currentPlayingPolylineDistance = forcedDistance;
			else
				VM.MAP.currentPlayingPolylineDistance = this.getCurrentDistance();
				//console.log("Current distance: " + this.getCurrentDistance())
			
			if (VM.VID.currentVideoDuration>0) {
				VM.MAP.currentPlayingPolylinePosition = VM.MAP.playingPolyline.getPoint(VM.MAP.currentPlayingPolylineDistance);
			} else {
				VM.MAP.currentPlayingPolylinePosition = VM.MAP.playingPolyline.getPoint(0);
			}
			
			if (VM.MAP.currentPlayingPolylinePosition && VM.MAP.map.getCenter() && (VM.MAP.map.getCenter().x != VM.MAP.currentPlayingPolylinePosition.x || VM.MAP.map.getCenter().y != VM.MAP.currentPlayingPolylinePosition.y)) {
				VM.MAP.set_playMarker(VM.MAP.currentPlayingPolylinePosition);
				VM.MAP.map.panTo(new GLatLng(VM.MAP.currentPlayingPolylinePosition.y,VM.MAP.currentPlayingPolylinePosition.x));
			}		
	},

	
	loadNearbyVideos: function(currentVideoID, pointOfInterest) {
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getNearbyVideos', 'current_video_id=' + currentVideoID + '&pointOfInterestLat=' + pointOfInterest.lat() + '&pointOfInterestLng=' + pointOfInterest.lng(), "receivedNearbyVideos", true, "VM.MAP.previewRoutes=VM.GLOBALS['receivedNearbyVideos'][0].routes; VM.VID.loadThumbs(VM.GLOBALS['receivedNearbyVideos'][0].videos)" );
	},
	
	removeVideoHighlight: function() {
		if (VM.MAP.previewPolyline) VM.MAP.map.removeOverlay(VM.MAP.previewPolyline);
		VM.MAP.previewPolyline = false;
		
		VM.MAP.map.returnToSavedPosition();
	},
	
	highlightVideo: function(video_id) {
		//console.log("highlight  for video_id "+video_id);
		
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
		VM.MAP.previewPolyline = new GPolyline(VM.MAP.assemblePlayingPolylinePoints(VM.MAP.previewPolylinePoints), "#FF8000", 9, 1);
		// Add highlight to map
		VM.MAP.map.addOverlay(VM.MAP.previewPolyline);
		
		VM.MAP.map.setZoom(VM.MAP.map.getBoundsZoomLevel(VM.MAP.previewPolyline.getBounds()));
   		VM.MAP.map.panTo(VM.MAP.previewPolyline.getBounds().getCenter());
	},
	
	// called from AS3 when video arrives at its end
	onVideoStop: function() {
		
		//Asume we are at the end of the playing polyline
		VM.MAP.map.savePosition();
		VM.VID.setActivityIndicator();
		VM.MAP.loadNearbyVideos(VM.VID.currentVideoID, VM.MAP.playingPolyline.getVertex(VM.MAP.playingPolyline.getVertexCount()-1));
		VM.MAP.resetPlayer();	
		
	},	
	
	resetPlayer: function() {
		// kill tracker
		window.clearTimeout(VM.MAP.trackingTimer);
		
		// remove overlays and markers
		VM.MAP.map.removeOverlay(VM.MAP.playingPolyline); 
		VM.MAP.map.removeOverlay(VM.MAP.playingPolylineShadow); 
		
		
		if (VM.MAP.playMarker) {
			VM.MAP.map.removeOverlay(VM.MAP.playMarker);
			VM.MAP.playMarker = false;
		}
	},	

	// called from JS when track changes or video arrives at its end
	stopVideo: function() {
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
		
		//console.log("listVideo");
		
		var info_text = "There are " + videos.size() + " videos playable at this point: <br>";
		var processedVideos = new Array();

		VM.MAP.stopVideo();
		
		VM.MAP.map.enableAllPolylines();
		VM.MAP.map.removeAllPolylineOverlays();
		
		VM.MAP.currentPlayingPolylineDistance = 0;
		
		for (var i=0; i<videos.size(); i++) {
			
			if (processedVideos.indexOf(videos[i].id) < 0) {
				processedVideos.push(videos[i].id);
				info_text += '<li><a href="#" onclick="VM.MAP.loadTrackData(\'' + videos[i].id + '\'); VM.MAP.map.closeInfoWindow();">' + videos[i].name + ' (' + videos[i].duration + 's)' + '</a> </li>';
			}
			
			
			
			if (videos[i].video_direction > 0) {
				videos[i].at_distance = !videos[i].at_distance ? videos[i].start_at_distance : videos[i].at_distance;	
				VM.MAP.map.getPolyline(videos[i].polyline_id).addPolylineOverlay("#FF8000", 9, 1, videos[i].at_distance, videos[i].end_at_distance);
			} else {
				videos[i].at_distance = !videos[i].at_distance ? videos[i].end_at_distance : videos[i].at_distance;			
				VM.MAP.map.getPolyline(videos[i].polyline_id).addPolylineOverlay("#FF8000", 9, 1, videos[i].start_at_distance, videos[i].at_distance);			
			}

			//VM.MAP.map.getPolyline(videos[i].polyline_id).disable();
		}
		
		

		VM.MAP.map.openInfoWindow(new GLatLng(lat,lng), info_text);
		GEvent.addListener(VM.MAP.map.getInfoWindow(),'closeclick', function() {VM.MAP.map.enableAllPolylines(); VM.MAP.map.removeAllPolylineOverlays();});

	},	

	//When a joint is clicked
	e_jointmarker_click: function() {

		VM.VID.clearThumbs();
		
		VM.MAP.ePolylineClickedPoint = false;
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideofromJoint', 'joint_id=' + this.id, "VM.MAP.receivedRouteData", true, "VM.MAP.listVideo(VM.MAP.receivedRouteData," + this.getPoint().y + "," + this.getPoint().x + ")" );
		
	},	
	
	//When a polyline is clicked
	e_polyline_click: function(point) {
		
		//console.log("e_polyline_click start");
		
		VM.VID.clearThumbs();
		
		//console.log("VM.VID.isPlayingOrPaused(): " + VM.VID.isPlayingOrPaused());
		
		if (VM.VID.isPlayingOrPaused()) {
			var intersection = VM.MAP.playingPolyline.intersectPoint(point);
			var intersectionPoint = VM.MAP.map.fromLatLngToDivPixel(intersection.point);
			var clickPoint = VM.MAP.map.fromLatLngToDivPixel(point);
			var distance = Math.sqrt(Math.pow(intersectionPoint.x - clickPoint.x,2) + Math.pow(intersectionPoint.y - clickPoint.y,2));
			
			//console.log("Clicked while playing. Distance from playing polyline: " + distance);	
			
			// Check if click was nearby the playing polyline
			if (distance <= 10) {
				VM.MAP.currentPlayingPolylineDistance = intersection.atDistance;
				VM.VID.setVideoPosition(VM.MAP.getCurrentTime());
				VM.MAP.updateTracker(VM.MAP.currentPlayingPolylineDistance);
				return;
			}
			
		}
		
		// To calculate starting distance
		VM.MAP.ePolylineClickedPoint = point;
		
		
		VM.getAjaxValue('http://'+vidmap_api_path+'/player/getVideofromPolyline', 'polyline_id=' + this.id + '&atDistance=' + this.intersectPoint(point).atDistance, "VM.MAP.receivedRouteData", true, "VM.MAP.listVideo(VM.MAP.receivedRouteData," + point.y + "," + point.x + ")" );
		
		//console.log("e_polyline_click end");
	},

	/* Setup of playmarker (video position indicator)
	*/
	set_playMarker: function(position) {

		if (!VM.MAP.playMarker) {
			VM.MAP.playMarker = new GMarker(position,{zIndexProcess:orderPlayerMarkers, icon:VM.MAP.getIcon("player", VM.MAP.playingMovementType), draggable:true, bouncy:true, dragCrossMove:true});
			GEvent.addListener(VM.MAP.playMarker,'dragend',this.e_playmarker_dragend);
			GEvent.addListener(VM.MAP.playMarker,'dragstart', this.e_playmarker_dragstart);
			GEvent.addListener(VM.MAP.playMarker,'drag',this.e_playmarker_drag);
			GEvent.addListener(VM.MAP.playMarker,'click',this.e_playmarker_click);
			GEvent.addListener(VM.MAP.playMarker,'mousedown',this.e_playmarker_mousedown);
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
		
		
		if (Prototype.Browser.Opera) {
			VM.VID.setVideoPosition(VM.MAP.getCurrentTime());
		}
			
		if (VM.MAP.isPlaying) {
			VM.VID.setCallback("Resume", "VM.MAP.trackVideo", "");
			VM.VID.resumeVideo(); 
		}
		
		VM.MAP.dragging = false;
	},
	
	/* On drag of playmarker (video position indicator)
	*/	
	e_playmarker_drag: function() {
		
		//console.log("e_playmarker_drag");
		
		var closestVertex = VM.MAP.playingPolyline.getClosestPoint(this.getPoint());
		
		if (!VM.MAP.playShadowMarker) {
			
			VM.MAP.playShadowMarker = new GMarker(closestVertex.point,{zIndexProcess:orderPlayerMarkers, icon:VM.MAP.getIcon("player", "knob"),draggable:false,bouncy:false, dragCrossMove:false, autoPan:false});
			VM.MAP.map.addOverlay(VM.MAP.playShadowMarker);
			VM.MAP.playShadowMarker.setLatLng(closestVertex.point);
		} else {
			
			VM.MAP.playShadowMarker.setLatLng(closestVertex.point);
			VM.MAP.currentPlayingPolylineDistance = closestVertex.atDistance;

			if (!Prototype.Browser.Opera) {
				VM.VID.setVideoPosition(VM.MAP.getCurrentTime());
			}

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
		return swfobject.getObjectById(playerID);
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
	
	setCallback: function(name, func, param) { 
		this.getMovie(this.playerID).nSetCallback(name, func, param); 
	},
	
	loadThumbs: function(videos) {
		this.getMovie(this.playerID).nLoadThumbs(videos);
	},
	
	clearThumbs: function() {
		this.getMovie(this.playerID).nClearThumbs();
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

