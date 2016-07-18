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
	
function debug(text) {
	if (!debug_switch) return;
	if (document.getElementById("debug_div"))
		document.getElementById("debug_div").innerHTML += text + '<br>'; 
	//else
		//alert(text);
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

function importJS(path, followup){ 

	try {
			var oHead = document.getElementsByTagName('HEAD').item(0);
			var oScript= document.createElement("script");
			oScript.type = "text/javascript";
			oScript.src=path;
			if (typeof followup != 'undefined') {
				
				//Check for IE
				if (!!(window.attachEvent && !window.opera)) {
					oScript.onreadystatechange= function () {
						try {
							if (this.readyState == 'loaded' || this.readyState == 'complete') {
								eval(followup.call());
							}
						} catch(e) {alert(e)}
					};
				}
				
				//oScript.onload=eval(followup.call()); //IE only
				oScript.onload=followup; //non IE only
			}
			oHead.appendChild(oScript);		
	} catch (e) {alert(e)}
	
}

function appendJS(text){ 
	
		var oHead = document.getElementsByTagName('HEAD').item(0);
		var oScript= document.createElement("script");
		oScript.type = "text/javascript";
		oScript.text=text;
		oHead.appendChild(oScript);				  
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


function Mutex_Initialize() {
		Mutex_Names = {};
}

function Mutex_Init(name, counter, action) {

	if (typeof Mutex_Names[name] == 'undefined')	{Mutex_Names[name] = {};}
		
	Mutex_Names[name].counter = counter;
	Mutex_Names[name].action = action;

}

function Mutex_Dec(name) {
	if (typeof Mutex_Names[name] == 'undefined') return;
	
	Mutex_Names[name].counter --;
	if (Mutex_Names[name].counter === 0) {
		//debug("Firing mutex " + name);
		eval(Mutex_Names[name].action);
	}
}

function newdrugonload() {	
	//alert("JS: newdrugonload");
	debug("JS: newdrugonload S");
	Mutex_Dec("start_framework");
}

function inject_Flash_HTML() {
	
	
	try {
		$(vidmap_box_id).innerHTML =  '';
	} catch(e) {
		inject_Flash_HTML();
		return;
	}
	
	try {
		
		$(vidmap_box_id).innerHTML +=  '<div id="mapID" style="width: 400px; height: 300px"></div><div id="playerID_container"> <object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" id="playerID" name="playerID" style="visibility:visible"><param name="movie" value="'+vidmap_flash_player_path+'" /><param name="scale" value="noscale" /><param name="wmode" value="transparent" /><param name="swLiveConnect" value="true" /><param name="allowfullscreen" value="false" /><param name="allowscriptaccess" value="always" /><param name="allownetworking" value="all" /><param name="flashvars" value="id=playerID&amp;onload=newdrugonload" /><!--[if !IE]>--><object type="application/x-shockwave-flash" id="playerID" data="'+vidmap_flash_player_path+'"><param name="scale" value="noscale" /><param name="wmode" value="transparent" /><param name="swLiveConnect" value="true" /><param name="allowfullscreen" value="false" /><param name="allowscriptaccess" value="always" /><param name="allownetworking" value="all" /><param name="flashvars" value="id=playerID&amp;onload=newdrugonload" /><!--<![endif]--><a href="http://www.adobe.com/go/getflashplayer"><img src="http://' + vidmap_api_path + '/images/get_flash_player_button.jpg" /></a><!--[if !IE]>--></object><!--<![endif]--></object></div><br class="clearfloat" />';	
	
		//Mutex_Dec("register_swfhttp");
		Mutex_Dec("register_newdrug");
		
	
	} catch(e) {alert(e);}
	
}

function start_flash_update() {
	
	try {
		
		if (flash_check.updateable) {
			flash_check.UpdatePlayer();
		} else {
			window.open("http://www.adobe.com/go/getflashplayer", "_self", "");
		}
		
	} catch(e){alert(e)}
	
}

function inject_No_Flash_HTML() {
	
	var current_flash_version = "none";
	flash_check = flensed.checkplayer();
	
	var install_flash_string = '<a href="#" onclick="start_flash_update()"><img src="http://' + vidmap_api_path + '/images/get_flash_player_button.jpg" border="0" /></a>';
	
	try {
		current_flash_version = swfobject.getFlashPlayerVersion();
	} catch(e) {}
	
	try {
		$(vidmap_box_id).innerHTML =  '';
	} catch(e) {
		inject_No_Flash_HTML();
		return;
	}
	
	try {
		
		$(vidmap_box_id).innerHTML +=   '<div align="center" style="background-color: #FFB7B7; width:350px; height:230px; padding-top:0px"><br><p><font face="Verdana, Arial, Helvetica, sans-serif">This video player needs </font></p><p><font face="Verdana, Arial, Helvetica, sans-serif">Adobe&copy; Flash&copy; Player </font></p><p><font face="Verdana, Arial, Helvetica, sans-serif">in Version 9.0.124 or higher.</font></p><p><p><font size="-1">(detected version is '+current_flash_version.major+'.'+current_flash_version.minor+'.'+current_flash_version.release+')</font></p>'+install_flash_string+'</p></div>';	
	
	} catch(e) {alert(e);}
	
}

function addFlashDomLoadEvents() { 
	
	try {
		if (Prototype.Browser.IE)
			swfobject.addDomLoadEvent(inject_Flash_HTML());
		else
			swfobject.addDomLoadEvent(inject_Flash_HTML);
	} catch(e) {}
}

function addNoFlashDomLoadEvents() { 
	
	try {
		if (Prototype.Browser.IE)
			swfobject.addDomLoadEvent(inject_No_Flash_HTML());
		else
			swfobject.addDomLoadEvent(inject_No_Flash_HTML);
	} catch(e) {}
}


function check_flash() {
	try {
		if (swfobject.hasFlashPlayerVersion(minimum_flash_version)) {
			set_container_class();
			return true;
		} else {
			addNoFlashDomLoadEvents();
			return false;
		}
	} catch(e) {alert("Flash detection failed.")}
	
	return false;
}

function vidmap_init(box) { 
		
	vidmap_box_id = box;
	importCSS("http://"+vidmap_api_path+"/stylesheets/player.css");
	
	
	Mutex_Initialize();
	Mutex_Init("start_framework", 2, "VM=new VM(); VM.InitControls();");
	Mutex_Init("start_flash_embed", 1, 'addFlashDomLoadEvents();');
	Mutex_Init("register_newdrug", 2, 'swfobject.registerObject("playerID", "9.0.124"); $("playerID").style.visibility = "visible";');
	
	loadJSLibraries();	
	
	
	
	addEvent(window, 'load', function(event){register_flash();});
}

// We assume that the DOM is now fully loaded
function register_flash() {
	
	Mutex_Dec("register_newdrug");
	
}

function set_container_class() {
	//$(vidmap_box_id).setStyle({backgroundColor:"#000000"});
	$(vidmap_box_id).addClassName("vidmap_player");
}

function loadJSLibraries() {
	
	//console.log("Loading JS Libraries: loadJSLibraries");
	Mutex_Init("loadJSLibraries_l1", 1, "loadJSLibraries_l1()");
	
	importJS("http://"+vidmap_api_path+"/javascripts/prototype.js", function(){Mutex_Dec("loadJSLibraries_l1");});

}

function loadJSLibraries_l1() {
	
	//console.log("Loading JS Libraries: loadJSLibraries");
	Mutex_Init("loadJSLibraries_l2", 1, "loadJSLibraries_l2()");
	importJS("http://"+vidmap_api_path+"/javascripts/flxhr/swfobject.js", function(){Mutex_Dec("loadJSLibraries_l2");});
	
}

function Mutex_Dec_loadJSLibraries_l3() {
	Mutex_Dec("loadJSLibraries_l3");
}

function loadJSLibraries_l2() {
	
	//console.log("Loading JS Libraries: loadJSLibraries_l2");
	Mutex_Init("loadJSLibraries_l3", 4, "loadJSLibraries_l3()");	
	
	flensed_base_path = "http://"+vidmap_api_path+"/javascripts/flxhr/"; //obsolete
	importJS("http://"+vidmap_api_path+"/javascripts/flxhr/flXHR.js", function(){Mutex_Dec("loadJSLibraries_l3");});
	importJS("http://"+vidmap_api_path+"/javascripts/PolylineEncoder.js", function(){Mutex_Dec("loadJSLibraries_l3");});
	importJS("http://"+vidmap_api_path+"/api/extensions", function(){Mutex_Dec("loadJSLibraries_l3");});
	
	try {
		if (Prototype.Browser.IE)
			swfobject.addDomLoadEvent(Mutex_Dec_loadJSLibraries_l3());
		else
			swfobject.addDomLoadEvent(Mutex_Dec_loadJSLibraries_l3);
	} catch(e) {alert("Could not attach DomLoadEvent 2.");}	
	
}

function loadJSLibraries_l3() {
	Mutex_Init("loadJSLibraries_l4", 1, "loadJSLibraries_l4()");	
	
	if (check_flash()) {Mutex_Dec("start_flash_embed"); Mutex_Dec("loadJSLibraries_l4"); }
}

function loadJSLibraries_l4() {
	//console.log("Loading JS Libraries: loadJSLibraries_l3");
	adaptPrototype();
	importJS("http://"+vidmap_api_path+"/api/vm_player", function(){Mutex_Dec("start_framework");});
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

function adaptPrototype() {
	
	Ajax.getTransport = function() { 
		return new flensed.flXHR({instancePooling:true,autoUpdatePlayer:false,xmlResponseText:false,onerror:handleError,loadPolicyURL:"http://dev.vidmap.de/crossdomain.xml"});
		//return new flensed.flXHR({instancePooling:true,autoUpdatePlayer:true,xmlResponseText:false,loadPolicyURL:"http://api.vidmap.de/crossdomain.xml"}); 
		//return new XMLHttpRequest();
	}
}

function handleError(errObj) {
	alert("Error: "+errObj.number
		+"\nType: "+errObj.name
		+"\nDescription: "+errObj.description
		+"\nSource Object Id: "+errObj.srcElement.instanceId
	);
}
