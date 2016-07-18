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
 
intersectLinePoint = function(a1, a2, b1) {

		var am = new Object();
		am.x = a2.x-a1.x;
		am.y = a2.y-a1.y;
		
		var bm = new Object();
		bm.x = -am.y;
		bm.y = am.x;
		
		return intersectLineLine(a1, am, b1, bm);
};

intersectLineLine = function(a1, am, b1, bm) {
    var result = new Object();
    
    var ua_t = (bm.x) * (a1.y - b1.y) - (bm.y) * (a1.x - b1.x);
    var ub_t = (am.x) * (a1.y - b1.y) - (am.y) * (a1.x - b1.x);
    var u_b  = (bm.y) * (am.x) - (bm.x) * (am.y);

    if ( u_b != 0 ) {
        var ua = ua_t / u_b;
        var ub = ub_t / u_b;

		result.point = new google.maps.LatLng(a1.y + ua * (am.y), a1.x + ua * (am.x));
		//result.point.x = a1.x + ua * (am.x);
		//result.point.y = a1.y + ua * (am.y);
		
		// Distance of the calculated point between two given points of the ray
		result.t = ua;
		
		// Distance from given point to ray
		result.d = result.point.distanceFrom(b1);
		
		// Distance from given point to basis
		result.atDistance = result.point.distanceFrom(a1);
						

    } else {
        result = false;
    }

    return result;
};

loadImage = function(path) {

	var xhr = new XMLHttpRequest();
	xhr.open('GET', path, true);
	xhr.responseType = 'blob';
	
	xhr.onload = function(e) {
	  if (this.status == 200) {
	    blob = new Blob([this.response]);
	    //console.log(blob.size)
	    
		readerB = new FileReader();
		readerB.onloadend = function () {
			//console.log("readerB.onload");
			bFile = new BinaryFile(this.result); 
			
			//console.log("Read EXIF")
			exif = EXIF.readFromBinaryFile(bFile);
			//console.log(exif);
			
			//console.log("Placing marker")
			
			latlng = new google.maps.LatLng(
				exif.GPSLatitude[0]+exif.GPSLatitude[1]/60+exif.GPSLatitude[2]/3600, 
				exif.GPSLongitude[0]+exif.GPSLongitude[1]/60+exif.GPSLongitude[2]/3600
			);
			
			//console.log(latlng.lat() + ", " + latlng.lng())
			
			create_icon_picture(latlng, path)
		}
		readerB.readAsBinaryString(blob);
	  }
	};
	
	xhr.send();
}


// MAP EXTENSIONS
 

google.maps.Map.prototype.setCenter2 = function(latlng, scale_lng, scale_lat) {
	off_lat = scale_lat == 100 ? 0 : (map.getBounds().getNorthEast().lat() - map.getBounds().getSouthWest().lat()) / (200/(100-scale_lat))
	off_lng = scale_lng == 100 ? 0 : (map.getBounds().getNorthEast().lng() - map.getBounds().getSouthWest().lng()) / (200/(100-scale_lng))
	
	this.setCenter(new google.maps.LatLng(latlng.lat() - off_lat, latlng.lng() + off_lng))
}

google.maps.Polyline.prototype.getDistanceofVertex = function(index) {
		
		var distance = 0;
		
		for (var i=0; i<index; i++) {
			distance += this.getVertex(i).distanceFrom(this.getVertex(i+1));	
		}		
		
		return distance;
};
	
google.maps.Polyline.prototype.getPoints = function(start_distance, end_distance) {
		
		var result = new Array();
		var totalDistance = start_distance;
		var startIndex = this.getIndex(start_distance);
		var endIndex = this.getIndex(end_distance);
		
		for (var i=startIndex; i<=endIndex; i++) {
			result.push(this.getVertex(i));
		}		
		
		return result;
};

google.maps.Polyline.prototype.intersectPoint = function(point) {
	
		if (this.getVertexCount() < 1) return false;
		
		var result = new Object();
		result.lastVertex = 0;
		result.nextVertex = 1;
		result.atDistance = 0;
		result.t = 0;
		result.d = this.getVertex(0).distanceFrom(point);
		result.point = this.getVertex(0);
		result.intersection = false;
		result.closestVertex = this.getVertex(0);
		result.closestVertexDistance = 0;
		
		var intersect;
		var totalDistance = 0;
		
		for (var i=0; i<this.getVertexCount()-1; i++) {
			
			
			intersect = intersectLinePoint(this.getVertex(i), this.getVertex(i+1), point);
			
			if (intersect.d <= result.d && intersect.t >= 0 && intersect.t <= 1) {
				result.lastVertex = i;
				result.nextVertex = i+1;
				

				result.atDistance = totalDistance + intersect.atDistance;
				result.t = intersect.t;					

				
				result.d = intersect.d;
				result.point = intersect.point;
				result.intersection = true;
			}
			
			totalDistance += this.getVertex(i).distanceFrom(this.getVertex(i+1));

			if (this.getVertex(i+1).distanceFrom(point) < result.closestVertex.distanceFrom(point)) {
				result.closestVertex = this.getVertex(i+1);
				result.closestVertexDistance = this.getDistanceofVertex(i+1);				
			}

		}		
		
		return result;

},

google.maps.Polyline.prototype.getClosestPoint = function(point) {
		
		result = this.intersectPoint(point);
		
		if (!result.intersection || result.d > result.closestVertex.distanceFrom(point)) {
			result.point = result.closestVertex;
			result.atDistance = result.closestVertexDistance;
		}

		return result;

},

google.maps.Polyline.prototype.getClosestVertex = function(point) {
	
	if (this.getVertexCount() < 2) return false;
	
	var result = new Object();
	result.point = this.getVertex(0);
	result.dist = point.distanceFrom(this.getVertex(0));
	result.vertexIndex = 0;
	
	for (var i=1; i< this.getVertexCount(); i++) {
		
		if (this.getVertex(i).distanceFrom(point) < result.dist) {
			result.point = this.getVertex(i);
			result.dist = this.getVertex(i).distanceFrom(point);
			result.vertexIndex = i;
		}

	}		
	
	return result;
},
	
google.maps.Polyline.prototype.getPoint = function(distance) {
		var numVertex = this.getVertexCount();
		var polyLength = this.getLength();
		distance = Math.min(distance, polyLength);
		
		var currentLength = 0;
		var i = 0;
		
		while (i<numVertex-1 && currentLength < distance ) {
			currentLength += this.getVertex(i).distanceFrom(this.getVertex(i+1));
			i++;
		}
		
		var baseLength = currentLength - this.getVertex(Math.max(0,i-1)).distanceFrom(this.getVertex(i));
		var basePoint = this.getVertex(Math.max(0,i-1));

		var t = (currentLength-baseLength) != 0 ? (distance-baseLength)/(currentLength-baseLength) : 0;
		
		var currentPoint = this.getVertex(i);
		var targetPoint = new google.maps.LatLng(basePoint.lat() + t * (currentPoint.lat() - basePoint.lat()), basePoint.lng() + t * (currentPoint.lng() - basePoint.lng()));	
		
		/*
		targetPoint.x = basePoint.x + t * (currentPoint.x - basePoint.x);
		targetPoint.y = basePoint.y + t * (currentPoint.y - basePoint.y);
		*/
		
		return targetPoint;		

};

google.maps.Polyline.prototype.getIndex = function(distance) {

		var numVertex = this.getVertexCount();
		var polyLength = this.getLength();
		distance = Math.min(distance, polyLength);

		var currentDistance = 0;
		var i = 0;
		
		while (i<numVertex-1 && currentDistance < distance ) {
			currentDistance += this.getVertex(i).distanceFrom(this.getVertex(i+1));
			i++;
		}
		
		return i;		

};

google.maps.Polyline.prototype.getBounds = function() {
  var bounds = new google.maps.LatLngBounds();
  this.getPath().forEach(function(e) {
    bounds.extend(e);
  });
  return bounds;
};

/**
* Checks weather a variable is undefined
*	@param 	a the variable
* @return	boolean value 
*/
function isUndefined(a) {
		return typeof a == 'undefined';
} 

/**
* Checks weather a variable is an array
* @param 	a the variable
* @return	boolean value 
*/
function isObject(a) {
	try {
		return typeof a == 'object' && !a.length;
	}
	catch(err) {
		return false;
	}
} 

/**
* Checks weather a variable is an array
*	@param 	a the variable
* @return	boolean value 
*/
function isArray(a) {
	try {
		return typeof a == 'object' && a.length;
	}
	catch(err) {
		return false;
	}
} 

/**
* Checks weather a variable is a string
*	@param 	a the variable
* @return	boolean value 
*/
function isString(a) {
		return typeof a == 'string';
} 

/**
* Checks weather a variable is a number
*	@param 	a the variable
* @return	boolean value 
*/
function isNum(a) {
		return typeof a == 'number';
} 

Array.prototype.sum = function(){
    var sum = 0;
    this.map(function(item){
        sum += item;
    });
    return sum;
}

Math.round_x = function(value, digits) {
	return Math.round(value * Math.pow(10,digits)) / Math.pow(10,digits)
}

Date.prototype.setISO8601 = function (string) {
    var regexp = "([0-9]{4})(-([0-9]{2})(-([0-9]{2})" +
        "(T([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?" +
        "(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?)?)?";
    var d = string.match(new RegExp(regexp));

    var offset = 0;
    var date = new Date(d[1], 0, 1);

    if (d[3]) { date.setMonth(d[3] - 1); }
    if (d[5]) { date.setDate(d[5]); }
    if (d[7]) { date.setHours(d[7]); }
    if (d[8]) { date.setMinutes(d[8]); }
    if (d[10]) { date.setSeconds(d[10]); }
    if (d[12]) { date.setMilliseconds(Number("0." + d[12]) * 1000); }
    if (d[14]) {
        offset = (Number(d[16]) * 60) + Number(d[17]);
        offset *= ((d[15] == '-') ? 1 : -1);
    }

    offset -= date.getTimezoneOffset();
    time = (Number(date) + (offset * 60 * 1000));
    this.setTime(Number(time));
}

/** Browser Check*/
jQuery.browser = {};
jQuery.browser.mozilla = /mozilla/.test(navigator.userAgent.toLowerCase()) && !/webkit/.test(navigator.userAgent.toLowerCase());
jQuery.browser.webkit = /webkit/.test(navigator.userAgent.toLowerCase());
jQuery.browser.opera = /opera/.test(navigator.userAgent.toLowerCase());
jQuery.browser.msie = /msie/.test(navigator.userAgent.toLowerCase());
jQuery.browser.iPad = /ipad/i.test(navigator.userAgent.toLowerCase());


google.maps.LatLng.prototype.toPoint = function(latLng, zoom, opt_point) {
  var me = this;
  var point = opt_point || new google.maps.Point(0, 0);
  var origin = me.pixelOrigin_;

  point.x = origin.x + latLng.lng() * me.pixelsPerLonDegree_;

  // Truncating to 0.9999 effectively limits latitude to 89.189. This is
  // about a third of a tile past the edge of the world tile.
  var siny = bound(Math.sin(degreesToRadians(latLng.lat())), -0.9999, 0.9999);
  point.y = origin.y + 0.5 * Math.log((1 + siny) / (1 - siny)) *
      -me.pixelsPerLonRadian_;
  var tiles_no = 1 << zoom;
  point.x *= tiles_no;
  point.y *= tiles_no;

  return point;
};

google.maps.LatLng.prototype.toPoint = function(map) {
	var topRight = map.getProjection().fromLatLngToPoint(map.getBounds().getNorthEast());
	var bottomLeft = map.getProjection().fromLatLngToPoint(map.getBounds().getSouthWest());
	var scale = Math.pow(2, map.getZoom());
	var worldPoint = map.getProjection().fromLatLngToPoint(this);
	return new google.maps.Point(Math.round((worldPoint.x - bottomLeft.x) * scale), Math.round((worldPoint.y - topRight.y) * scale));
}

google.maps.LatLng.prototype.distanceTo = function(map, latlng) {
	
	/*
	var p1 = map.getProjection().fromLatLngToPoint(this);
	var p2 = map.getProjection().fromLatLngToPoint(latlng);

	return Math.sqrt(Math.pow(p1.x-p2.x, 2) + Math.pow(p1.y-p2.y, 2));
	*/
	
	overlay = new google.maps.OverlayView();
	overlay.draw = function() {};
	overlay.setMap(map);
	
	var p1 = overlay.getProjection().fromLatLngToDivPixel(this); 
	var p2 = overlay.getProjection().fromLatLngToDivPixel(latlng); 
	
	return Math.sqrt(Math.pow(p1.x-p2.x, 2) + Math.pow(p1.y-p2.y, 2));
}