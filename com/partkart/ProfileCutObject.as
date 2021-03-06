﻿package com.partkart{

	import flash.display.Sprite;
	import flash.utils.getTimer;

	public class ProfileCutObject extends CutObject{

		public function ProfileCutObject():void{
			super();
		}

		protected override function run():Boolean{
			//var cutlist:Array = super.initialize();

			// we will use the display tree to store the nested cutpaths (ie. a cutpath will be the child of another cutpath if it is nested inside it)
			rootpath.nestPaths();
			rootpath.setChildrenDirection(1);

			var offset:Number;

			if(outside == true){
				offset = -0.5*tooldiameter;
			}
			else{
				offset = 0.5*tooldiameter;
			}

			var offsetlist:Array = rootpath.offset(cutlist, offset);

			var cutpath:CutPath;

			for each(cutpath in offsetlist){
				rootpath.addChild(cutpath);
			}

			// set the directionality of each loop
			for each(cutpath in offsetlist){
				cutpath.setDirection(dir);
				cutpath.resetSegments();
			}

			rootpath.nestPaths();

			cutlist = null;

			redraw();

			// stop after a single iteration (we do not really need or implement green threading for profile operations)
			return false;
		}

		public override function redraw():void{
			this.graphics.clear();

			if(processed == false){
				// simply draw a stroke around pathlist
				//this.graphics.lineStyle(Global.zoom*tooldiameter,0xffff00,0.3);

				//for each(var path:Path in pathlist){
					/*if(path.dirty == true){
						path.zeroOrigin();
						docx = 0;
						docy = 0;
					}*/
					//path.render(this);
				//}

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

				if(active){
					drawBlank(2,0x00ddff, 0.1, 0x00ddff, 0.3);
				}
				else{
					drawBlank(2,0xffff00, 0.1, 0xffff00, 0.3);
				}

				rootpath.visible = false;
			}
			else{
				rootpath.visible = true;
				var cutlist:Array = rootpath.getChildren();
				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						if(Global.viewcuts == false){
							cutpath.redraw();
							cutpath.redrawTabs();
							cutpath.drawStartArrow();
						}
						else{
							cutpath.redrawCuts(tooldiameter);
						}
					}
				}
				rootpath.visible = true;
			}
		}

		// returns an array of grouped profilecutobjects
		public override function group():Array{
			super.initialize();
			var groups:Array = super.group();
			var newcuts:Array = new Array();

			for(var i:int=0; i<groups.length; i++){
				var cut:ProfileCutObject = this.clone();
				cut.name = this.name + "-" + i;
				cut.pathlist = groups[i];
				newcuts.push(cut);
			}

			return newcuts;
		}

		// copies parameters of this cutpath into a new cutpath
		protected function clone():ProfileCutObject{
			var newcut:ProfileCutObject = new ProfileCutObject();

			newcut.safetyheight = safetyheight;
			newcut.stocksurface = stocksurface;
			newcut.targetdepth = targetdepth;
			newcut.stepover = stepover;
			newcut.stepdown = stepdown;
			newcut.feedrate = feedrate;
			newcut.plungerate = plungerate;

			newcut.tooldiameter = tooldiameter;
			newcut.roughingclearance = roughingclearance;

			newcut.outside = outside;
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

			drawBlank((2*tooldiameter+gap)*Global.zoom,color, 1, color, 1);

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

		// adds tabs based on given input and returns the number of tabs added
		public function addTabs(tabspacing:Number, tabwidth:Number, tabheight:Number):int{
			var cutlist:Array = rootpath.getChildren();
			var count:int = 0;

			for each(var cutpath:CutPath in cutlist){
				count += cutpath.addTabs(tabspacing, tabwidth, tabheight, tooldiameter);
			}

			redraw();

			return count;
		}

		/*public function setActive():void{
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