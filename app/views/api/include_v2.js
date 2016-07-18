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
 
var vidmap_api_path = "dev.vidmap.de";
var vidmap_flash_player_path = "http://dev.vidmap.de/newdrug.swf";
var debug_switch = false;
var vidmap_box_id = "vidmap";
var minimum_flash_version = "9.0.124";
var vm_api_ready = false;
var flash_check = false;

function vidmap_init(box) { 
	
	
	vidmap_box_id = box;
	
	adaptPrototype();
	
	//Attach onUnLoad event for cleaning up
	addEvent(window, 'unload', function(event){vidmap_unload()});
	
	new flensed.checkplayer(minimum_flash_version, integrate_flash);
	
}

function integrate_flash(flash_check_result) {
	flash_check = flash_check_result
	
	if (flash_check.checkPassed) {
		
		$(vidmap_box_id).addClassName("vidmap_player");
		importCSS("http://"+vidmap_api_path+"/stylesheets/player.css");
		
		$(vidmap_box_id).innerHTML = '<div id="mapID" style="width: 400px; height: 300px;"></div><div id="playerID_container"><div id="playerID_placeholder"></div></div><br class="clearfloat" />';
	
	} else {
		
		var install_flash_string = '<a href="#" onclick="update_flash()"><img src="http://' + vidmap_api_path + '/images/get_flash_player_button.jpg" border="0" /></a>';
		$(vidmap_box_id).innerHTML =   '<div align="center" style="background-color: #FFB7B7; width:350px; height:230px; padding-top:0px"><br><p><font face="Verdana, Arial, Helvetica, sans-serif">This video player needs </font></p><p><font face="Verdana, Arial, Helvetica, sans-serif">Adobe&copy; Flash&copy; Player </font></p><p><font face="Verdana, Arial, Helvetica, sans-serif">in Version 9.0.124 or higher.</font></p><p><p><font size="-1">(detected version is '+flash_check.playerVersionDetected+')</font></p>'+install_flash_string+'</p></div>';	
		return;
	}
	
	integrate_map();
	 
	var flashvars = {id:"playerID"}; //, onload:"newdrugonload"};
	var params = {wmode:"transparent", allowScriptAccess:"always", allownetworking:"all", menu:"false", scale:"noscale"};
	var attributes = { id:"playerID", name:"playerID" };

	// this next call will get queued until the library is ready and version check completed.
	flash_check.DoSWF(vidmap_flash_player_path, "playerID_placeholder", "400", "300", flashvars, params, attributes);
}

function update_flash() {
	
	if (flash_check.updateable) {
		flash_check.UpdatePlayer();
	} else {
		window.open("http://www.adobe.com/go/getflashplayer", "_self", "");
	}
		
}

function integrate_map() {
	VM=new VM(); 
	VM.InitControls();
}

function vidmap_unload() {
	
	//Stop Tracker
	try {
		window.clearTimeout(VM.MAP.trackingTimer);
	} catch (error) {
	}
	
	//Disconnect from streaming server
	try {
		VM.VID.disconnect();
	} catch (error) {
	}
	
	//Unload GMaps
	try {
		GUnload();
	} catch (error) {
	}
	
	try {
		$(vidmap_box_id).innerHTML = '';
	} catch (error) {
	}
}

function addEvent(obj, evType, fn){ 
	 if (obj.addEventListener){ 
	   obj.addEventListener(evType, fn, false); 
	   return true; 
	 } else if (obj.attachEvent){ 
	   var r = obj.attachEvent("on"+evType, fn); 
	   return r; 
	 } else { 
	   return false; 
 	}
}

function importCSS(path){ 
			
	var headID = document.getElementsByTagName("head")[0];         
	var cssNode = document.createElement('link');
	cssNode.type = 'text/css';
	cssNode.rel = 'stylesheet';
	cssNode.href = path;
	cssNode.media = 'all';
	headID.appendChild(cssNode);		
}

function adaptPrototype() {
	Ajax.getTransport = function() { 
		return new flensed.flXHR({instancePooling:true,autoUpdatePlayer:false,xmlResponseText:false,loadPolicyURL:"http://dev.vidmap.de/crossdomain.xml"}); 
		//return new XMLHttpRequest();
	}
}

// Function to interact with VidMap
function vidmap_control(action, video_id) {
	try {
		if(VM.isready()) {
			VM.API.EXEC(action, video_id);
		}
	} catch(e) {
		alert("Please wait for VidMap to finish library setup");
	}
	
	return true;
}

function debug(text) {
	if (!debug_switch) return;
	if (document.getElementById("debug_div"))
		document.getElementById("debug_div").innerHTML += text + '<br>'; 
}