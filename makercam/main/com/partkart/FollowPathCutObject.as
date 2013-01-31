package com.partkart{
	
	import flash.display.Sprite;
	import flash.utils.getTimer;
	
	public class FollowPathCutObject extends CutObject{
		
		public function FollowPathCutObject():void{
			super();
		}
		
		protected override function run():Boolean{			
			var cutpath:CutPath;
			
			for each(cutpath in cutlist){
				cutpath.makeContinuous();
				cutpath.clonePath();
				cutpath.joinSequence();
			}
			
			redraw();
			
			return false;
		}
		
		public override function redraw():void{
			this.graphics.clear();
			if(processed == false){
				// simply draw a stroke around pathlist
				this.graphics.lineStyle(tooldiameter*Global.zoom,0xffff00,0.3);
				
				for each(var path:Path in pathlist){
					//this.graphics.moveTo(path.seglist[0].p1.x, path.seglist[0].p1.y);
					path.render(this);
				}
			}
			else{
				var cutlist:Array = rootpath.getChildren();
				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						cutpath.renderClear();
						if(Global.viewcuts == false){
							cutpath.drawArrows(4);
						}
						else{
							cutpath.redrawCuts(tooldiameter);
						}
					}
				}
			}
		}
		
		// returns an array of grouped followpathcutobjects
		public override function group():Array{
			// whether one path is inside of another is irrelevant to a followpath operation, so we don't need to use the rootpath
			var newcuts:Array = new Array();
			
			for(var i:int=0; i<pathlist.length; i++){
				var cut:FollowPathCutObject = this.clone();
				cut.name = this.name + "-" + i;
				cut.pathlist = new Array(pathlist[i]);
				newcuts.push(cut);
			}
			
			return newcuts;
		}
		
		// copies parameters of this cutpath into a new cutpath
		protected function clone():FollowPathCutObject{
			var newcut:FollowPathCutObject = new FollowPathCutObject();
			
			newcut.safetyheight = safetyheight;
			newcut.stocksurface = stocksurface;
			newcut.targetdepth = targetdepth;
			newcut.stepover = stepover;
			newcut.stepdown = stepdown;
			newcut.feedrate = feedrate;
			newcut.plungerate = plungerate;
			
			newcut.tooldiameter = tooldiameter;
			
			return newcut;
		}
		
		public override function setActive():void{
			active = true;
			if(processed == false){
				// active mode for unprocessed operations
			}
			else{
				var cutlist:Array = rootpath.getChildren();
				for each(var cutpath:CutPath in cutlist){
					if(cutpath != null){
						if(Global.viewcuts == false){
							cutpath.drawArrows(6);
						}
						else{
							cutpath.redrawCuts(tooldiameter);
						}
					}
				}
			}
		}
		
		public override function setInactive():void{
			active = false;
			redraw();
		}
		
		public function drawNestBlank(color:uint = 0x000000, gap:Number = 0):void{
			this.graphics.clear();
			
			this.graphics.lineStyle((tooldiameter + gap)*Global.zoom,color,1);
				
			for each(var path:Path in pathlist){
				path.render(this);
			}
			
			while(numChildren>0){
				removeChildAt(0);
			}
		}
		
		/*public function reprocess():void{
			
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