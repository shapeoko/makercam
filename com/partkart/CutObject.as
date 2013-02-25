package com.partkart{

	import flash.display.Sprite;
	import flash.utils.getTimer;
	import com.greenthreads.*;
	import flash.geom.Point;
	import flash.display.BitmapData;

	// a cutobject is an atomic unit of a "cut operation" ie. profile, pocket, etc
	// it may contain a number of cutpaths arranged in a tree format, using the actionscript displaylist tree
	public class CutObject extends GreenThread{

		// the path objects that this cut object operates on
		public var pathlist:Array;
		public var active = false;

		protected var cutlist:Array;

		public var docx:Number = 0;
		public var docy:Number = 0;

		public var processed:Boolean = false;

		public var rootpath:CutPath;

		// values only used by the postprocessor that are in mm
		public var safetyheight:Number;
		public var stocksurface:Number;
		public var targetdepth:Number;
		public var stepover:Number;
		public var stepdown:Number;
		public var feedrate:Number;
		public var plungerate:Number;

		// values relevant to the offset algorithm that are in cm
		public var tooldiameter:Number;
		public var roughingclearance:Number;

		// used only for profile operations
		public var outside:Boolean = true;

		// used only for drilling operations

		// if true, use the centers of each cutpath
		public var center:Boolean = true;
		public var spacing:Number = 0;

		// direction 1 = counter clockwise direction 2 = clockwise
		public var dir:int = 1;

		public function CutObject():void{
			//this.mouseChildren = false;
			//this.mouseEnabled = false;
			super(false);
		}

		override protected function initialize():void{
			processed = true;

			if(rootpath && this.contains(rootpath)){
				removeChild(rootpath);
			}


			docx = 0;
			docy = 0;

			x=0;
			y=0;

			//zeroOrigin();

			cutlist = new Array();

			rootpath = new CutPath(); // container for nested cutpaths

			addChild(rootpath);

			for each(var inputpath:Path in pathlist){
				var seglist:Array = inputpath.linearize(true);

				if(seglist.length > 0){
					var cutpath:CutPath = new CutPath();
					cutpath.parentpath = inputpath;

					cutpath.addSegments(seglist);

					cutpath.docx = inputpath.docx;
					cutpath.docy = inputpath.docy;

					cutpath.redraw();

					rootpath.addChild(cutpath);
					cutlist.push(cutpath);
				}
			}

			/*for(var i:int=0; i<cutlist.length; i++){
				if(cutlist[i].seglist.length == 0){
					cutlist.splice(i,1);
					i--;
				}
			}*/
		}

		// return a list of path groups, where each group of paths are in contact with eachother
		// this is meant to prevent "archipelagos" of cutobjects that can't be nested
		public function group():Array{
			rootpath.nestPaths();

			// parentpaths are a list of the top-level boundary curves that enclose the rest of the paths
			var parentpaths:Array = new Array();
			for(var i:int=0; i<rootpath.numChildren; i++){
				if(rootpath.getChildAt(i) is CutPath){
					parentpaths.push(rootpath.getChildAt(i));
				}
			}

			var children:Array = rootpath.getChildren();

			var groups:Array = new Array();

			for(i=0; i<parentpaths.length; i++){
				groups.push(new Array(parentpaths[i].parentpath));
			}

			for(i=0; i<children.length; i++){
				var index:int = parentpaths.indexOf(children[i]);
				if(index == -1){
					// search parent list and see which parent contains this cutpath
					for(var j:int=0; j<parentpaths.length;j++){
						if(parentpaths[j].contains(children[i])){
							index = j;
							break;
						}
					}

					if(index != -1){
						groups[index].push(children[i].parentpath);
					}
				}
			}

			return groups;
		}

		/*public function reinitialize():Array{

			if(rootpath && this.contains(rootpath)){
				removeChild(rootpath);
			}

			this.rootpath = null;
			docx = 0;
			docy = 0;
			return initialize();
		}*/

		public function redraw():void{}

		public function setActive():void{
			if(processed == true && Global.viewcuts == false){
				active = true;
				var cutlist:Array = rootpath.getChildren();
				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						cutpath.setActive();
					}
				}
			}
		}

		public function setInactive():void{
			if(processed == true && Global.viewcuts == false){
				active = false;
				var cutlist:Array = rootpath.getChildren();
				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						cutpath.setInactive();
					}
				}
			}
		}

		public function inchToCm():void{
			unitConvert(2.54);

			paramsInchToCm();
		}

		public function paramsInchToCm():void{
			// convert inch to mm
			safetyheight *= 25.4;
			stocksurface *= 25.4;
			targetdepth *= 25.4;
			stepdown *= 25.4;
			feedrate *= 25.4;

			// convert inch to cm
			tooldiameter *= 2.54;
			roughingclearance *= 2.54;
		}

		public function cmToInch():void{
			unitConvert(1/2.54);

			paramsCmToInch();
		}

		public function paramsCmToInch():void{
			// convert mm to inch
			safetyheight /= 25.4;
			stocksurface /= 25.4;
			targetdepth /= 25.4;
			stepdown /= 25.4;
			feedrate /= 25.4;

			// convert inch to cm
			tooldiameter /= 2.54;
			roughingclearance /= 2.54;
		}

		protected function unitConvert(factor:Number):void{
			docx *= factor;
			docy *= factor;

			var children:Array = rootpath.getChildren();

			for each(var cutpath:CutPath in children){
				if(cutpath != null){
					cutpath.unitConvert(factor);
				}
			}
		}

		// draws a fill in the graphics object of the current cutobject, using the linearized versions of its child paths
		protected function drawBlank(linethickness:Number, linecolor:uint, linealpha:Number, fillcolor:uint, fillalpha:Number, fillbitmap:BitmapData = null):void{
			var children:Array = rootpath.getChildren();

			if(children.length > 0){

				this.graphics.lineStyle(linethickness,linecolor,linealpha);
				if(fillbitmap){
					this.graphics.beginBitmapFill(fillbitmap);
				}
				else{
					this.graphics.beginFill(fillcolor,fillalpha);
				}

				for each(var cutpath:CutPath in children){
					this.graphics.moveTo((cutpath.seglist[0].p1.x+cutpath.docx)*Global.zoom, (-cutpath.seglist[0].p1.y+cutpath.docy)*Global.zoom);

					for each(var seg:* in cutpath.seglist){
						if(seg is CircularArc){
							cutpath.renderFillArc(new CircularArc(new Point(seg.p1.x+cutpath.docx, seg.p1.y-cutpath.docy), new Point(seg.p2.x+cutpath.docx, seg.p2.y-cutpath.docy), new Point(seg.center.x+cutpath.docx, seg.center.y-cutpath.docy), seg.radius), Global.zoom, 3, true, this);
						}
						else{
							cutpath.renderFillLine(new Segment(new Point(seg.p1.x+cutpath.docx, seg.p1.y-cutpath.docy), new Point(seg.p2.x+cutpath.docx, seg.p2.y-cutpath.docy)), Global.zoom, true, this);
						}
					}

					cutpath.graphics.clear();
				}

				this.graphics.endFill();
			}
		}

		// zeros the origin of this cut object, and all of its paths
		public function zeroOrigin():void{
			if(pathlist){
				for(var i:int=0; i<pathlist.length; i++){
					pathlist[i].zeroOrigin();
				}
			}

			docx = 0;
			docy = 0;
			x = 0;
			y = 0;
		}

		public function removeActiveTabs():void{
			var children:Array = rootpath.getChildren();
			for(var i:int=0; i<children.length; i++){
				children[i].removeActiveTabs();
			}
		}
	}

}