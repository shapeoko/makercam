package com.partkart{
	
	import flash.display.Sprite;
	import flash.utils.getTimer;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	
	public class DrillCutObject extends CutObject{
		
		public var dlist:Array;
		
		public function DrillCutObject():void{
			super();
		}
		
		protected override function run():Boolean{			
			var cutpath:CutPath;
			
			initializeDrill();
			
			redraw();
			
			return false;
		}
		
		public function initializeDrill():void{
			dlist = new Array();
			var cutpath:CutPath;
			var drillpoint:Point;
			
			if(center || spacing == 0){
				// find the center of each cutpath and use that as the drilling location
				for each(cutpath in cutlist){
					var rect:Rectangle = cutpath.getExactBounds();
					drillpoint = new Point(cutpath.docx + rect.x + rect.width/2, -cutpath.docy + rect.y + rect.height/2);
					dlist.push(drillpoint);
				}
			}
			else{
				// fill cutpath with a hole pattern
				for each(cutpath in cutlist){
					var bounds:Rectangle = cutpath.getExactBounds();
					for(var i:int=1; i<bounds.width/spacing; i++){
						for(var j:int=1; j<bounds.height/spacing; j++){
							drillpoint = new Point(bounds.x+i*spacing, bounds.y+j*spacing);
							
							if(cutpath.containsPoint(drillpoint)){
								dlist.push(new Point(drillpoint.x+cutpath.docx,drillpoint.y-cutpath.docy));
							}
						}
					}
				}
			}
		}
		
		public override function redraw():void{
			
			this.graphics.clear();
			
			if(this.rootpath == null){
				super.initialize();
				initializeDrill();
				processed = false;
			}
			
			//if(processed == false){
				
				for each(var path:Path in pathlist){
					if(path.dirty == true || path.camdirty == true){
						// first remove previous rootpath
						while(numChildren > 0){
							removeChildAt(0);
						}
						super.initialize();
						initializeDrill();
						processed = false;
						
						docx = 0;
						docy = 0;
						
						x = 0;
						y = 0;
				
						break;
					}
				}
				
				// draw dots where there are drilling operations
				var c:Number = tooldiameter/2.82842712;
				
				for(var i:int=0; i<dlist.length; i++){
					if(processed == false){
						graphics.lineStyle(0,0,0);
						
						if(active == false){
							graphics.beginFill(0xffff00,0.5);
						}
						else{
							graphics.beginFill(0x00ddff,0.5);
						}
						graphics.drawCircle(dlist[i].x*Global.zoom,-dlist[i].y*Global.zoom,(tooldiameter/2)*Global.zoom);
						graphics.endFill();
					}
					if(active == false || processed == false){
						graphics.lineStyle(1,0,1);
					}
					else{
						graphics.lineStyle(2,0,1);
					}
					
					if(processed == true && Global.viewcuts == true){
						graphics.lineStyle(0,0,0);
						graphics.beginFill(0xff0000,0.2);
						graphics.drawCircle(dlist[i].x*Global.zoom,-dlist[i].y*Global.zoom,(tooldiameter/2)*Global.zoom);
						graphics.endFill();
					}
					else{
						graphics.moveTo((dlist[i].x-c)*Global.zoom, (-dlist[i].y+c)*Global.zoom);
						graphics.lineTo((dlist[i].x+c)*Global.zoom, (-dlist[i].y-c)*Global.zoom);
						
						graphics.moveTo((dlist[i].x+c)*Global.zoom, (-dlist[i].y+c)*Global.zoom);
						graphics.lineTo((dlist[i].x-c)*Global.zoom, (-dlist[i].y-c)*Global.zoom);
					}
				}
				rootpath.visible = false;
			//}
		}
		
		// returns an array of grouped drillcutobjects
		public override function group():Array{
			super.initialize();
			var groups:Array = super.group();
			var newcuts:Array = new Array();
			
			for(var i:int=0; i<groups.length; i++){
				var cut:DrillCutObject = this.clone();
				cut.name = this.name + "-" + i;
				cut.pathlist = groups[i];
				newcuts.push(cut);
			}
			
			return newcuts;
		}
		
		// copies parameters of this cutpath into a new cutpath
		protected function clone():DrillCutObject{
			var newcut:DrillCutObject = new DrillCutObject();
			
			newcut.safetyheight = safetyheight;
			newcut.stocksurface = stocksurface;
			newcut.targetdepth = targetdepth;
			newcut.stepover = stepover;
			newcut.stepdown = stepdown;
			newcut.plungerate = plungerate;
			
			newcut.tooldiameter = tooldiameter;
			newcut.center = center;
			newcut.spacing = spacing;
			
			return newcut;
		}
		
		public override function setActive():void{
			active = true;			
			redraw();
		}
		
		public override function setInactive():void{
			active = false;
			redraw();
		}
		
		public function drawNestBlank(color:uint = 0x000000, gap:Number = 0):void{
			this.graphics.clear();
			
			for(var i:int=0; i<dlist.length; i++){
				graphics.beginFill(color,1);
				graphics.drawCircle(dlist[i].x*Global.zoom,-dlist[i].y*Global.zoom,(tooldiameter/2 + gap/2)*Global.zoom);
				graphics.endFill();
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