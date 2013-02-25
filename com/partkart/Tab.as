package com.partkart{

	import flash.display.Sprite;
	import flash.geom.Point;

	public class Tab extends Sprite{

		public var location:Number;
		public var tabwidth:Number;
		public var tabheight:Number;

		// tool diameter
		public var diameter:Number;

		public var active:Boolean = false;

		public var p1:Point;
		public var p2:Point;

		public function Tab(inputlocation:Number, inputwidth:Number, inputheight:Number, inputdiameter:Number):void{
			location = inputlocation;
			tabwidth = inputwidth;
			tabheight = inputheight;
			diameter = inputdiameter;
		}

		public function redraw():void{
			graphics.clear();
			if(active){
				graphics.beginFill(0x0099ff);
			}
			else{
				graphics.lineStyle(2,0x0099ff,1);
				graphics.beginFill(0xffffff,0);
			}

			graphics.drawRoundRect(-(diameter/2)*Global.zoom, -(tabwidth/2)*Global.zoom,diameter*Global.zoom,tabwidth*Global.zoom, diameter*Global.zoom);

			graphics.endFill();
		}

		public function setActive():void{
			var changed:Boolean = (active == false);
			active = true;

			if(changed){
				redraw();
			}
		}

		public function setInactive():void{
			var changed:Boolean = (active == true);
			active = false;

			if(changed){
				redraw();
			}
		}
	}
}