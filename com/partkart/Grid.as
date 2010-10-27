package com.partkart{
	
	import flash.display.*;
	import flash.events.*;
	
	public class Grid extends Sprite{
		
		// the grid class draws the grid and origin axes based on the current zoom level and origin position
		
		private var xaxis:Sprite;
		private var yaxis:Sprite;
		private var grid:Sprite;
		
		private var gridlines:Array;
		
		private var gridxnum:int;
		private var gridynum:int;
		
		private var yoffset:int = 0;
		private var xoffset:int = 0;
		
		private var horizlines:Sprite;
		private var vertlines:Sprite;
		
		// Reusable array index
		private var i:int;
		
		public function Grid():void{			
			init();
		}
		
		public function init():void{
			horizlines = new Sprite();
			vertlines = new Sprite();
			gridlines = new Array();
			
			grid = new Sprite();
			xaxis = new Sprite();
			yaxis = new Sprite();
			
			drawBlank();
			
			drawAxes();
			
			// Draw grid lines
			drawGrid();
			addChild(grid);
			grid.addChild(horizlines);
			grid.addChild(vertlines);
		}
		
		private function drawBlank():void{
			
			// a blank background is necessary for the grid to detect mouse events
			
			var blank:Shape = new Shape();
			blank.graphics.beginFill(0xffffff);
			blank.graphics.drawRect(0,0,Global.docwidth,Global.docheight);
			blank.graphics.endFill();
			
			blank.alpha = 0;
			addChild(blank);
		}
		
		private function drawAxes():void {
			// draw axes for origin
			var yg:Graphics = yaxis.graphics;
			var xg:Graphics = xaxis.graphics;

			yg.lineStyle(1,0,0.5,true,LineScaleMode.NONE);
			yg.moveTo(0,0);
			yg.lineTo(0,Global.docheight);
			yaxis.x = Global.xorigin;

			xg.lineStyle(1,0,0.5,true,LineScaleMode.NONE);
			xg.moveTo(0,0);
			xg.lineTo(Global.docwidth,0);
			xaxis.y = Global.yorigin;

			addChild(yaxis);
			addChild(xaxis);
		}
		
		private function redrawAxes():void{
			xaxis.y = Global.yorigin;
			yaxis.x = Global.xorigin;
		}
		
		private function drawGrid():void {
			
			// set grid spacing
			gridxnum = Math.ceil(Global.docwidth/Global.zoom);
			gridynum = Math.ceil(Global.docheight/Global.zoom);
			
			// set position of offset variables
			yoffset = Global.yorigin - Math.floor(Global.yorigin/Global.zoom)*Global.zoom;
			xoffset = Global.xorigin - Math.floor(Global.xorigin/Global.zoom)*Global.zoom;
			
			var ypos:int = 0;
			var xpos:int = 0;
			
			// draw horizontal lines
			for (i = 0; i <= gridynum; i++) {
				ypos = i*Global.zoom + yoffset;
				if(ypos != 0){
					gridlines[i] = new Shape();
					drawHorizLine(gridlines[i]);
					gridlines[i].y = ypos;
				}
			}
			
			// draw vertical lines
			for (i = 0; i <= gridxnum; i++) {
				xpos = i*Global.zoom + xoffset;
				if(xpos != 0){
					gridlines[i] = new Shape();
					drawVertLine(gridlines[i]);
					gridlines[i].x = xpos;
				}
			}

		}
		
		public function redrawGrid():void{			
			if(Global.zoom < 10){
				redrawGridLarge();
				return;
			}
			this.graphics.clear();
			
			// set grid spacing
			gridxnum = Math.ceil(Global.docwidth/Global.zoom);
			gridynum = Math.ceil(Global.docheight/Global.zoom);
			
			// set position of offset variables
			yoffset = Global.yorigin - Math.floor(Global.yorigin/Global.zoom)*Global.zoom;
			xoffset = Global.xorigin - Math.floor(Global.xorigin/Global.zoom)*Global.zoom;
			
			var ypos:int = 0;
			var xpos:int = 0;
			
			// reposition existing horizontal lines
			for (i = 0; i < horizlines.numChildren; i++) {
				ypos = i*Global.zoom + yoffset;
				horizlines.getChildAt(i).y = ypos;
			}
			
			// reposition existing vertical lines
			for (i = 0; i < vertlines.numChildren; i++) {
				xpos = i*Global.zoom + xoffset;
				vertlines.getChildAt(i).x = xpos;
			}
			
			// add more horizontal lines as needed
			if(gridynum > horizlines.numChildren){
				for(i=horizlines.numChildren; i <= gridynum; i++){
					ypos = i*Global.zoom + yoffset;
					if(ypos != 0){
						gridlines[i] = new Shape();
						drawHorizLine(gridlines[i]);
						gridlines[i].y = ypos;
					}
				}
			}
			else if(gridynum < horizlines.numChildren){
				// remove vertical grid lines as needed
				while(horizlines.numChildren > gridynum){
					horizlines.removeChildAt(gridynum);
				}
			}
			
			// add more vertical lines as needed
			if(gridxnum > vertlines.numChildren){
				for(i=vertlines.numChildren; i <= gridxnum; i++){
					xpos = i*Global.zoom + xoffset;
					if(xpos != 0){
						gridlines[i] = new Shape();
						drawVertLine(gridlines[i]);
						gridlines[i].x = xpos;
					}
				}
			}
			else if(gridxnum < vertlines.numChildren){
				// remove vertical grid lines as needed
				while(vertlines.numChildren > gridxnum){
					vertlines.removeChildAt(gridxnum);
				}
			}
		}

		public function redrawGridLarge():void{
			
			// apparently drawing a rectangle as a background will hurt performance when using hardware acceleration, revise later..
			this.graphics.beginFill(0xeeeeee);
			this.graphics.drawRect(0,0,this.width,this.height);
			this.graphics.endFill();
			
			// set grid spacing
			
			var offset = 0;
			
			if(Global.unit == "cm"){
				offset = 100;
			}
			else{
				offset = 12;
			}
			
			gridxnum = Math.ceil(Global.docwidth/(Global.zoom*offset));
			gridynum = Math.ceil(Global.docheight/(Global.zoom*offset));
			
			// set position of offset variables
			yoffset = Global.yorigin - Math.floor(Global.yorigin/(Global.zoom*offset))*Global.zoom*offset;
			xoffset = Global.xorigin - Math.floor(Global.xorigin/(Global.zoom*offset))*Global.zoom*offset;
			
			var ypos:int = 0;
			var xpos:int = 0;
			
			// reposition existing horizontal lines
			for (i = 0; i < horizlines.numChildren; i++) {
				ypos = i*Global.zoom*offset + yoffset;
				horizlines.getChildAt(i).y = ypos;
			}
			
			// reposition existing vertical lines
			for (i = 0; i < vertlines.numChildren; i++) {
				xpos = i*Global.zoom*offset + xoffset;
				vertlines.getChildAt(i).x = xpos;
			}
			
			// add more horizontal lines as needed
			if(gridynum > horizlines.numChildren){
				for(i=horizlines.numChildren; i <= gridynum; i++){
					ypos = i*Global.zoom*offset + yoffset;
					if(ypos != 0){
						gridlines[i] = new Shape();
						drawHorizLine(gridlines[i]);
						gridlines[i].y = ypos;
					}
				}
			}
			else if(gridynum < horizlines.numChildren){
				// remove vertical grid lines as needed
				while(horizlines.numChildren > gridynum){
					horizlines.removeChildAt(gridynum);
				}
			}
			
			// add more vertical lines as needed
			if(gridxnum > vertlines.numChildren){
				for(i=vertlines.numChildren; i <= gridxnum; i++){
					xpos = i*Global.zoom*offset + xoffset;
					if(xpos != 0){
						gridlines[i] = new Shape();
						drawVertLine(gridlines[i]);
						gridlines[i].x = xpos;
					}
				}
			}
			else if(gridxnum < vertlines.numChildren){
				// remove vertical grid lines as needed
				while(vertlines.numChildren > gridxnum){
					vertlines.removeChildAt(gridxnum);
				}
			}
		}
		
		private function drawHorizLine(line:Shape):void{
			
			// dotted line
			for(var j=0; j<Global.docwidth; j+=4){
				line.graphics.beginFill(0x999999);
				line.graphics.drawRect(j,0,1,1);
				line.graphics.endFill();
			}
			
			horizlines.addChild(line);
		}
		
		private function drawVertLine(line:Shape):void{
			
			// dotted line
			for(var j=0; j<Global.docheight; j+=4){
				line.graphics.beginFill(0x999999);
				line.graphics.drawRect(0,j,1,1);
				line.graphics.endFill();
			}
			
			vertlines.addChild(line);
		}
		
		public function setOrigin():void{
			redrawAxes();
			redrawGrid();
		}
		
		public function clear():void{
			while(numChildren>0){
				removeChildAt(0);
			}
		}
	}
	
}