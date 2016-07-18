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
* Adds many overlays at once
*/

GMap2.prototype.addOverlays=function(a){
				
				var b=this;
        for (i=0;i<a.length;i++) {
                try {
                        this.overlays.push(a[i]);
                        a[i].initialize(this);
                        a[i].redraw(true);
                } catch(ex) {
                        alert('err: ' + i + ', ' + ex.toString());
                }
        }
        this.reOrderOverlays();

}; 

/**
* Return a certain polyline
*/

GMap2.prototype.getPolyline=function(id){
	
	return this.polylines[id];
	
	/*
	var result = this.l.filter(function(poly){return poly.id == id?true:false;})[0];
	
	return result == "" ? false : result;
	*/

}; 

/**
* Set a certain polyline
*/

GMap2.prototype.setPolyline=function(id, polyline){
	
	this.polylines[id] = polyline;

}; 


function orderStartMarkers (marker,b) {
	return GOverlay.getZIndex(marker.getPoint().lat()) + 3*1000000;
}
	
function orderStopMarkers (marker,b) {
	return GOverlay.getZIndex(marker.getPoint().lat()) + 1*1000000;
}

function orderCrossMarkers (marker,b) {
	return GOverlay.getZIndex(marker.getPoint().lat()) + 2*1000000;
}

function orderPlayerMarkers (marker,b) {
	return GOverlay.getZIndex(marker.getPoint().lat()) + 4*1000000;
}
			
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

						result.point = new GLatLng(a1.y + ua * (am.y), a1.x + ua * (am.x));
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

GPolyline.prototype.getDistanceofVertex = function(index) {
		
		var distance = 0;
		
		for (var i=0; i<index; i++) {
			distance += this.getVertex(i).distanceFrom(this.getVertex(i+1));	
		}		
		
		return distance;
};
	
GPolyline.prototype.getPoints = function(start_distance, end_distance) {
		
		var result = new Array();
		var totalDistance = start_distance;
		var startIndex = this.getIndex(start_distance);
		var endIndex = this.getIndex(end_distance);
		
		for (var i=startIndex; i<=endIndex; i++) {
			result.push(this.getVertex(i));
		}		
		
		return result;
};

GPolyline.prototype.intersectPoint = function(point) {
	
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

GPolyline.prototype.getClosestPoint = function(point) {
		
		result = this.intersectPoint(point);
		
		if (!result.intersection || result.d > result.closestVertex.distanceFrom(point)) {
			result.point = result.closestVertex;
			result.atDistance = result.closestVertexDistance;
		}

		return result;

},

GPolyline.prototype.getClosestVertex = function(point) {
	
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
	
/**
* Adds an overlay to the polyline
*	@param 	color the color
*	@param 	startAt the starting distance
*	@param 	stopAt the ending distance
* @return	GPolyline the new polyline object 
*/
GPolyline.prototype.addPolylineOverlay = function(color, weight, opacity, startAt, stopAt)	 {
	
	// Do nothing if Overlay already exists
	if (VM.MAP.map.getPolyline(this.id + "_Overlay")) 
		VM.MAP.map.getPolyline(this.id + "_Overlay").removeOverlay();
	
	if (startAt == stopAt) return false;
	
	isUndefined(startAt) ? startAt = 0 : false;
	isUndefined(stopAt) ? stopAt = this.getDistanceofVertex(this.getVertexCount()-1) : false;
	isUndefined(color) ? color = this.color : false;
	isUndefined(weight) ? weight = this.weight : false;
	isUndefined(opacity) ? opacity = this.opacity : false;
		
		
	startAt = Math.max(startAt, 0);
	stopAt = Math.min(stopAt, this.getDistanceofVertex(this.getVertexCount()-1));

	var latlngs = new Array();
	var distance = 0;
	var started = false;
	
	var i = 0;
	
	for (i=1; i< this.getVertexCount(); i++) {
		distance += this.getVertex(i).distanceFrom(this.getVertex(i-1));

		if (distance >= startAt) {
			
			if (!started) {
				
				var t = (startAt - this.getDistanceofVertex(i-1)) / (this.getDistanceofVertex(i) - this.getDistanceofVertex(i-1));
				if (t < 1) latlngs.push(new GLatLng(this.getVertex(i-1).lat() + t * (this.getVertex(i).lat() - this.getVertex(i-1).lat()), this.getVertex(i-1).lng() + t * (this.getVertex(i).lng() - this.getVertex(i-1).lng())));
			
				started = true;
			} 
			
			if (distance <= stopAt) 
				latlngs.push(this.getVertex(i));
			else
				break;
		}
		
		
	}
	
	i = Math.min(i, this.getVertexCount()-1);
	var lastDistance = this.getDistanceofVertex(i-1);
	var currentDistance = this.getDistanceofVertex(i);
	
	var t = (stopAt - lastDistance) / (currentDistance - lastDistance);
	latlngs.push(new GLatLng(this.getVertex(i-1).lat() + t * (this.getVertex(i).lat() - this.getVertex(i-1).lat()), this.getVertex(i-1).lng() + t * (this.getVertex(i).lng() - this.getVertex(i-1).lng())));

	
	var poly = new GPolyline(latlngs,  color,  weight,  opacity);
	poly.id =this.id + "_Overlay";
	
	VM.MAP.map.polylines[poly.id] = poly;
	VM.MAP.map.addOverlay(poly);
	
	VM.MAP.visiblePolylineOverlays[poly.id] = this.id;
	
	
	return poly;
}

/**
* Clear all polyline overlays
*/

GMap2.prototype.removeAllPolylineOverlays=function(){
		
	Object.values(VM.MAP.visiblePolylineOverlays).each(function(id){VM.MAP.map.getPolyline(id).removeOverlay()});
}; 


/**
* Remove overlay from polyline
*/
GPolyline.prototype.removeOverlay = function()	 {
	
	var overlay = VM.MAP.map.getPolyline(this.id + "_Overlay");
	if (overlay) {

		delete VM.MAP.visiblePolylineOverlays[overlay.id];
		delete VM.MAP.map.polylines[overlay.id];
		
		VM.MAP.map.removeOverlay(overlay);
		
		return true;
	} else
		return false;

}

GMap2.prototype.enableAllPolylines = function()	 {
	if (isUndefined(VM.MAP.map.disabledPolylines))
		return false;
		
	var polys = Object.keys(VM.MAP.map.disabledPolylines);
	polys.each(function(p){delete VM.MAP.map.disabledPolylines[p]; VM.MAP.map.addOverlay(VM.MAP.map.getPolyline(p))});
	
}

GPolyline.prototype.enable = function()	 {
	if (isUndefined(VM.MAP.map.disabledPolylines))
		return false;
		
	delete VM.MAP.map.disabledPolylines[this.id];
	VM.MAP.map.addOverlay(this);
}

GPolyline.prototype.disable = function()	 {
	if (isUndefined(VM.MAP.map.disabledPolylines))
		VM.MAP.map.disabledPolylines = new Object();
	
	VM.MAP.map.disabledPolylines[this.id] = true;
	VM.MAP.map.removeOverlay(this);
	
}

/**
* Sets the color of a polyline
*	@param 	color the color
* @return	GPolyline the new polyline object 
*/
GPolyline.prototype.setColor = function(color)	 {
	var poly = this.copy();
	poly.color = color;
	poly.id =this.id
	GEvent.addListener(poly,'click', VM.MAP.e_polyline_click);
	VM.MAP.map.addOverlay(poly);
	VM.MAP.map.removeOverlay(this);
	return poly;
}
	
/**
* Sets the color of a polyline
* @param 	polyline_id the polyline id
* @param 	color the color
* @return	GPolyline the new polyline object 
*/
GMap2.prototype.setPolylineColor = function(polyline_id, color)	 {
	var old_poly = this.getPolyline(polyline_id);
	this.setPolyline(polyline_id, old_poly.setColor(color));
}	
	
GPolyline.prototype.getPoint = function(distance) {
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
		var targetPoint = new GPoint();
		
		var currentPoint = this.getVertex(i);
		
		targetPoint.x = basePoint.x + t * (currentPoint.x - basePoint.x);
		targetPoint.y = basePoint.y + t * (currentPoint.y - basePoint.y);
		
		return targetPoint;		

};

GPolyline.prototype.getIndex = function(distance) {

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
