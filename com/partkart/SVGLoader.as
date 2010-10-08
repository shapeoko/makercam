package com.partkart{
	import flash.net.FileReference;
	import flash.net.FileFilter;
	
	import flash.events.IOErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flash.utils.ByteArray;
	
	import com.lorentz.SVG.*;
	
	public class SVGLoader{
		
		//FileReference Class well will use to load data
		private var fr:FileReference;
		public var svg_object:Object;
		
		//File types which we want the user to open
		private static const FILE_TYPES:Array = [new FileFilter("SVG File", "*.svg;*.xml")];
		
		private var main:Object;
		
		private var svg:XML;
		
		public function SVGLoader(m:Object){
			main = m;
		}
		
		public function load(svginput:* = null):void{
			if(svginput == null){
				//create the FileReference instance
				fr = new FileReference();
	
				//listen for when they select a file
				fr.addEventListener(Event.SELECT, onFileSelect);
	
				//listen for when then cancel out of the browse dialog
				fr.addEventListener(Event.CANCEL,onCancel);
	
				//open a native browse dialog that filters for text files
				fr.browse(FILE_TYPES);
			}
			else{
				XML.ignoreWhitespace = false;
				svg = new XML(svginput);
				XML.ignoreWhitespace = true;
				
				processSvg();
			}
		}
		
		//called when the user selects a file from the browse dialog
		private function onFileSelect(e:Event):void{
			//listen for when the file has loaded
			fr.addEventListener(Event.COMPLETE, onLoadComplete);

			//listen for any errors reading the file
			fr.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);

			//load the content of the file
			fr.load();
		}
		
		//called when the file has completed loading
		private function onLoadComplete(e:Event):void{
			
			XML.ignoreWhitespace = false;
			svg = new XML(fr.data);
			XML.ignoreWhitespace = true;

			processSvg();
		}
		
		private function processSvg():void{
			if(!svg.hasComplexContent()){
				main.startDialog(160, 50, new Array({type: "label", label:"Could not read SVG file"}), "error");
			}
			else{
				var parser:SVGParser = new SVGParser(svg);
				this.svg_object = parser.parse();
				
				if(this.svg_object == null){
					main.startDialog(160, 50, new Array({type: "label", label:"Could not read SVG file"}), "error");
				}
				else{
					//clean up the FileReference instance
					
					main.processFile(svg_object);
					main.loadCuts(svg);
					
					fr = null;
					
					var dispatcher:EventDispatcher = new EventDispatcher();
					dispatcher.dispatchEvent(new Event(Event.COMPLETE));
				}
			}
		}

		//called if an error occurs while loading the file contents
		private function onLoadError(e:IOErrorEvent):void{
			var dispatcher:EventDispatcher = new EventDispatcher();
			dispatcher.dispatchEvent(e);
		}
		
		//called when the user cancels out of the browser dialog
		private function onCancel(e:Event):void{
			fr = null;
		}



	}

}