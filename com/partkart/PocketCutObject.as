package com.partkart{

	import flash.display.Sprite;
	import flash.utils.getTimer;
	import flash.geom.Point;
	import flash.display.BitmapData;

	public class PocketCutObject extends CutObject{

		public function PocketCutObject():void{
			super();
		}

		// all offsets combined in one array
		protected var offsetresult:Array;

		// currently processing offset paths
		protected var offsetlist:Array;

		// number of iterations we have been offseting
		protected var iteration:int;

		protected override function initialize():void{
			super.initialize();

			iteration = 0;
			_progress = 0;

			// we will use the display tree to store the nested cutpaths (ie. a cutpath will be the child of another cutpath if it is nested inside it)
			rootpath.nestPaths();
			rootpath.setChildrenDirection(1);

			// offset result contains all cutpaths
			offsetresult = new Array();

			rootpath.pocketdepth = iteration;
			offsetlist = rootpath.offset(cutlist, 0.5*tooldiameter + roughingclearance);
			offsetresult = offsetresult.concat(offsetlist);

			if(isNaN(_maximum)){
				// we have no idea how many iterations it will take, but give it an educated guess
				var max:Number = 0;
				for each(var path:Path in pathlist){
					if(path.width > max){
						max = path.width;
					}
					if(path.height > max){
						max = path.height;
					}
				}

				max /= Global.zoom;
				_maximum = 0.5*(max/(stepover*tooldiameter));
			}
		}

		protected override function run():Boolean{

			var cutpath:CutPath;

			iteration++;
			_progress = iteration;

			for each(cutpath in offsetlist){
				cutpath.pocketdepth = iteration;
			}

			// make deep copy of offset curves
			var newoffsetlist:Array = new Array();

			for each(cutpath in offsetlist){
				var newcutpath:CutPath = new CutPath();
				newcutpath.seglist = cutpath.seglist;
				newoffsetlist.push(newcutpath);
			}

			rootpath.pocketdepth = iteration;
			offsetlist = rootpath.offset(newoffsetlist, stepover*tooldiameter, true);
			offsetresult = offsetresult.concat(offsetlist);

			if(offsetlist.length == 0){
				finish();
				return false;
			}

			return true;
		}

		protected function finish():void{
			for each(var cutpath:CutPath in offsetresult){
				rootpath.addChild(cutpath);
			}

			// set the directionality of each loop
			for each(cutpath in offsetresult){
				cutpath.setDirection(dir);
				cutpath.resetSegments();
			}

			rootpath.nestPaths();
			rootpath.rotateChildren();

			cutlist = null;
			_maximum = iteration;

			redraw();
		}

		public override function redraw():void{

			this.graphics.clear();

			if(this.rootpath == null){
				super.initialize();
				processed = false;
			}

			if(processed == false){

				for each(var path:Path in pathlist){
					if(path.dirty == true){
						// first remove previous rootpath
						while(numChildren > 0){
							removeChildAt(0);
						}
						super.initialize();
						processed = false;

						docx = 0;
						docy = 0;

						x = 0;
						y = 0;

						break;
					}
				}
				var hatch:BitmapData = new BitmapData(6,6,true,0);
				if(active == false){
					hatch.floodFill(0,0,0x44ffff00);
				}
				else{
					hatch.floodFill(0,0,0x4400ddff);
				}
				hatch.setPixel32(0,0,0xFF000000);
				hatch.setPixel32(1,1,0xFF000000);
				hatch.setPixel32(2,2,0xFF000000);
				hatch.setPixel32(3,3,0xFF000000);
				hatch.setPixel32(4,4,0xFF000000);
				hatch.setPixel32(5,5,0xFF000000);

				drawBlank(2,0xffff00, 0.1, 0xffff00, 0.3, hatch);

				rootpath.visible = false;
			}
			else{
				var cutlist:Array = rootpath.getChildren();
				var prev:CutPath = cutlist[0];

				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						if(Global.viewcuts == false){
							cutpath.redraw();
							cutpath.drawStartArrow();
						}
						else{
							cutpath.redrawCuts(tooldiameter);
							var depthdiff:int = cutpath.pocketdepth - prev.pocketdepth;
							if(prev != cutpath && (depthdiff == -1 || depthdiff == 1) && prev.parent == cutpath && cutpath.getNumChildren() == 1){
								cutpath.redrawStartCut(prev.seglist[0].p1);
							}

							prev = cutpath;
						}
					}
				}
			}
		}

		// returns an array of grouped pocketcutobjects
		public override function group():Array{
			super.initialize();
			var groups:Array = super.group();
			var newcuts:Array = new Array();

			for(var i:int=0; i<groups.length; i++){
				var cut:PocketCutObject = this.clone();
				cut.name = this.name + "-" + i;
				cut.pathlist = groups[i];
				newcuts.push(cut);
			}

			return newcuts;
		}

		// copies parameters of this cutpath into a new cutpath
		protected function clone():PocketCutObject{
			var newcut:PocketCutObject = new PocketCutObject();

			newcut.safetyheight = safetyheight;
			newcut.stocksurface = stocksurface;
			newcut.targetdepth = targetdepth;
			newcut.stepover = stepover;
			newcut.stepdown = stepdown;
			newcut.feedrate = feedrate;
			newcut.plungerate = plungerate;

			newcut.tooldiameter = tooldiameter;
			newcut.roughingclearance = roughingclearance;

			newcut.dir = dir;

			return newcut;
		}

		// draws the total area taken up by this cutobject (used for nesting)
		public function drawNestBlank(color:uint = 0x000000, gap:Number = 0):void{
			this.graphics.clear();

			//for each(var path:Path in pathlist){
				//if(path.dirty == true){
					// first remove previous rootpath
					while(numChildren > 0){
						removeChildAt(0);
					}
					super.initialize();

					/*docx = 0;
					docy = 0;

					x = 0;
					y = 0;*/

					//break;
				//}
			//}

			drawBlank((gap*Global.zoom/2)+1,color, 1, color, 1);

			while(numChildren>0){
				removeChildAt(0);
			}
			rootpath.visible = false;
		}

		public override function setActive():void{
			if(processed == false){
				active = true;
				redraw();
			}
			else{
				super.setActive();
			}
		}

		public override function setInactive():void{
			if(processed == false){
				active = false;
				redraw();
			}
			else{
				super.setInactive();
			}
		}

		/*public override function setActive():void{
			active = true;
			var cutlist:Array = rootpath.getChildren();
			for each(var cutpath:CutPath in cutlist){
				if(cutpath != null){
					cutpath.setActive();
				}
			}
		}

		public function setInactive():void{
			active = false;
			var cutlist:Array = rootpath.getChildren();
			for each(var cutpath:CutPath in cutlist){
				if(cutpath != null){
					cutpath.setInactive();
				}
			}
		}

		public function reprocess():void{

			if(rootpath && this.contains(rootpath)){
				removeChild(rootpath);
			}

			this.rootpath = null;
			docx = 0;
			docy = 0;
			process(pathlist);
		}*/


	}

}