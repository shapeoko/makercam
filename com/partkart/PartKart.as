package com.partkart{
	
	import flash.external.ExternalInterface;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	import flash.net.URLRequestMethod;
	import flash.net.URLLoaderDataFormat;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.Event;
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import flash.display.BitmapData;
	import flash.utils.ByteArray;
	
	import com.tink.display.HitTest;
	import com.adobe.images.JPGEncoder;
	import com.adobe.serialization.json.*;
	
	public class PartKart{
		
		private var main:*;
		private var progressdialog:ProgressDialog;
		private var loader:URLLoader;
		private var posturl:String = "/factory/order";
		private var maxbitmap:int = 200;
		private var avoidoverlap:Boolean = false;
		
		public function PartKart(parent:*):void{
			main = parent;
			
			// attach external listeners
			try{
				ExternalInterface.addCallback("openfile", this.openfile);
				//ExternalInterface.call("alert", "partkam startup!");
			}
			catch(e:Error){
				// fail silently
			}
		}
		
		// when avoidoverlap = true, we will try to avoid overlaps by using a bounding rectangle
		public function openfile(url:String, overlap:Boolean = false):void{
			avoidoverlap = overlap;
			
			// don't do anything if currently in an operation
			if(Global.tool == 99){
				return;
			}

			var request:URLRequest = new URLRequest(url);
			
			loader = new URLLoader();
			
			try {
                loader.load(request);
            }
            catch (error:SecurityError)
            {
                main.startDialog(240, 50, new Array({type:"label", label:"could not open file"}), "error");
				return;
            }
			
			loader.addEventListener(IOErrorEvent.IO_ERROR, openfileError);
            loader.addEventListener(Event.COMPLETE, openfileComplete);
			loader.addEventListener(ProgressEvent.PROGRESS, openfileProgress);

			progressdialog = main.startProgressDialog(250, 75, "Opening File", "Cancel", openfileClose);
			progressdialog.init(1);
		}
		
		// runs when the user clicks "cancel" during file open
		protected function openfileClose():void{
			loader.close();
			progressdialog.stopDialog();
			progressdialog = null;
			
			loader.removeEventListener(IOErrorEvent.IO_ERROR, openfileError);
            loader.removeEventListener(Event.COMPLETE, openfileComplete);
			loader.removeEventListener(ProgressEvent.PROGRESS, openfileProgress);
			loader = null;
		}
		
		protected function openfileError(e:IOErrorEvent):void{
			openfileClose();
			main.startDialog(240, 50, new Array({type:"label", label:"could not open file"}), "error");
		}
		
		protected function openfileProgress(e:ProgressEvent):void{
			progressdialog.setProgress(e.bytesLoaded/e.bytesTotal);
		}
		
		protected function openfileComplete(e:Event):void{
			var data:* = loader.data;
			
			openfileClose();
			
			main.scene.setInactive();
			
			var sloader:SVGLoader = new SVGLoader(main);
			sloader.load(data);
			
			main.scene.redraw();
			
			// just-loaded cutpaths will be active, and the rest inactive
			main.scene.shiftActive();
			
			ExternalInterface.call("openComplete");
		}
		
		// connect to partkart factory
		public function order(cutlist:Array):void{
			
			if(!cutlist || cutlist.length == 0){
				main.startDialog(240, 50, new Array({type:"label", label:"no toolpaths to process"}), "error");
				return;
			}
			
			for each(var cut:* in cutlist){
				if(cut.stocksurface != 0 || cut.targetdepth >= 0){
					main.startDialog(340, 50, new Array({type:"label", label:"stock surface must be 0 and target depth must be negative!"}), "error");
					return;
				}
			}
			
			for each(cut in cutlist){
				cut.zeroOrigin();
				cut.drawNestBlank(0x000000, 0);
				cut.processed = false;
				
				// add paths to its cutpath so they will show up in the thumbnail
				/*for each(var path:Path in cut.pathlist){
					cut.addChild(path);
				}*/
			}
			
			var groups:Array = cutlist.slice();
			
			// merge overlapping cuts into a single object (we will treat these as individual units)
			for(var i:int=0; i<groups.length; i++){
				for(var j:int=0; j<groups.length; j++){
					if(i != j && HitTest.complexHitTestObject(groups[i], groups[j])){
						groups[i].addChild(groups[j]);
						groups.splice(j,1);
						if(i >= j){
							i--;
						}
						j--;
					}
				}
			}
			
			/*for each(cut in cutlist){
				cut.active = false;
				cut.redraw();
			}*/
			
			// at this point, each item in the groups array contains a nested tree of cutobjects, the root of which is an element in groups
			
			// list of json-encoded objects that will be sent to the server
			var objlist:Array = new Array();
			
			// array of arrays that match each element in group. Basically a flattened tree
			var groupedcuts:Array = new Array();
			
			// flatten out the group tree
			for(i=0; i<groups.length; i++){
				cut = groups[i];
				var glist:Array = new Array(cut);
				
				for(j=0; j<cutlist.length; j++){
					if(cutlist[j] != cut && cut.contains(cutlist[j])){
						glist.push(cutlist[j]);
					}
				}
				groupedcuts[i] = glist;
			}
			
			i=0;
			for each(cut in groups){
				// get the grouped cutlist
				/*var gcutlist:Array = new Array(cut);
				
				for(i=0; i<cutlist.length; i++){
					if(cutlist[i] != cut && cut.contains(cutlist[i])){
						gcutlist.push(cutlist[i]);
					}
				}*/
				var gcutlist:Array = groupedcuts[i];
				
				// get all the parent paths used in the grouped cutlist
				var gpathlist:Array = new Array();
				for(j=0; j<gcutlist.length; j++){
					for(var k:int=0; k<gcutlist[j].pathlist.length; k++){
						if(gpathlist.indexOf(gcutlist[j].pathlist[k]) == -1){
							gpathlist.push(gcutlist[j].pathlist[k]);
						}
					}
				}
				
				// create a dummy sprite to hold cut objects and paths for "snapshot"
				var dummy:Sprite = new Sprite();
				for each(var c:* in gcutlist){
					dummy.addChild(c);
					c.redraw();
					for each(var p:Path in c.pathlist){
						dummy.addChild(p);
						p.redraw();
					}
				}
				
				main.scene.addChild(dummy);
				
				// draw a bitmap for the thumbnail
				var region:Rectangle = dummy.getBounds(main.scene);
				
				var bitmapwidth:Number = region.width;
				var bitmapheight:Number = region.height;
				var scale:Number = 1;
				
				if(region.width > region.height){
					scale = maxbitmap/region.width;
					bitmapwidth = maxbitmap;
					bitmapheight = region.height*scale;
				}
				else{
					scale = maxbitmap/region.height;
					bitmapwidth = region.width*scale;
					bitmapheight = maxbitmap;
				}
				
				var trans:Matrix = new Matrix(scale,0,0,scale, -region.x*scale,-region.y*scale);
				
				var gthumb:BitmapData = new BitmapData(region.width*scale,region.height*scale,false);
				gthumb.draw(dummy, trans);
				
				// encode the thumbnail as a jpeg
				var enc:JPGEncoder = new JPGEncoder(80);
				var gthumbjpeg:ByteArray = enc.encode(gthumb);
				var gthumb64:String = Base64.encode(gthumbjpeg);
				
				gthumb.dispose();
				
				main.scene.removeChild(dummy);
				
				// generate svg file for the group
				var writer:SVGWriter = new SVGWriter(gpathlist, gcutlist);
				var svg:String = writer.parse();
				
				// list of generated g-code from each cut object in gcutlist
				/*var gcodelist:Array = new Array();
				// list of path lengths from each cut object
				var lengthlist:Array = new Array();
				var post:PostProcessor = new PostProcessor(null);
				
				for(i=0; i<gcutlist.length; i++){
					var children:Array = gcutlist[i].rootpath.getChildren();
					var cutlength:Number = 0;
					var gcode:String = "";
					for(j=0; j<children.length; j++){
						gcode += post.getLoopGcode(children[j], gcutlist[i].feedrate, gcutlist[i].docx, gcutlist[i].docy);
						if(j != children.length-1){
							gcode += '(break)';
						}
						cutlength += children[j].getLength();
					}
					gcodelist.push(gcode);
					lengthlist.push(cutlength);
				}*/
				
				var obj:Object = new Object();
				obj.svg = svg;
				obj.unit = (Global.unit == 'in' ? '0':'1');
				//obj.gcode = gcodelist;
				//obj.cutlength = lengthlist;
				obj.thumbnail = gthumb64;
				
				objlist.push(obj);
				
				i++;
			}
			
			// send the request to the server
			var url:URLRequest = new URLRequest(posturl);
			url.method = URLRequestMethod.POST;
			
			var variables:URLVariables = new URLVariables();
			variables.data = JSON.encode(objlist);
			url.data = variables;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			
			loader.addEventListener(Event.COMPLETE, orderComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, orderError);
			
			loader.load(url);
		}
		
		protected function orderError(e:IOErrorEvent):void{
			var loader:URLLoader = URLLoader(e.target);
			main.startDialog(200, 50, new Array({type:"label", label:loader.data}), "error");
		}
		
		protected function orderComplete(e:Event):void{
			var loader:URLLoader = URLLoader(e.target);
			if(loader.data == "success"){
				ExternalInterface.call("navigateParent","/user/orders/");
			}
			else{
				main.startDialog(200, 50, new Array({type:"label", label:loader.data}), "error");
			}
		}

	}
}