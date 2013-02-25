package com.partkart{

	import flash.display.*;
	import com.partkart.Segment;
	import flash.geom.Point;
	import com.partkart.Path;

	public class Dot extends Sprite{

		// the dot keeps track of which two segments it controls
		public var s1:Segment;
		public var s2:Segment;

		// and a reference to the segment point that it controls
		public var point:Point;

		// and which segments for which it is a bezier control point
		public var c1:Segment;
		public var c2:Segment;

		public var active:Boolean; // active means the dot is red
		public var current:Boolean = false; // current means the dot was the most recently clicked
		public var loop:Boolean = false; // whether the dot is currently circled

		public var looppoint:Point;
		public var looppath:Path; // merge with this path after dragging

		private var loopshape:Shape;

		private var hitshape:Shape;

		public function Dot():void{
			setInactive();
		}

		public function setActive():void{
			active = true;

			clearChildren();
			var dot1 = new Shape();
			dot1.graphics.beginFill(0x000000);
			dot1.graphics.drawRect(0,0,30,30);
			dot1.graphics.endFill();
			dot1.x = -15;
			dot1.y = -15;

			dot1.alpha = 0;

			var dot3 = new Shape();
			dot3.graphics.beginFill(0xff0000);
			dot3.graphics.drawCircle(0,0,5);
			dot3.graphics.endFill();

			var dotsprite:Sprite = new Sprite();

			addChild(dot1);
			addChild(dot3);
		}

		public function setInactive():void{
			active = false;

			clearChildren();
			var dot1 = new Shape();
			dot1.graphics.beginFill(0x000000);
			dot1.graphics.drawRect(0,0,30,30);
			dot1.graphics.endFill();
			dot1.x = -15;
			dot1.y = -15;

			dot1.alpha = 0;

			var dot2 = new Shape();
			dot2.graphics.beginFill(0x000000);
			dot2.graphics.drawCircle(0,0,5);
			dot2.graphics.endFill();

			var dot3 = new Shape();
			dot3.graphics.beginFill(0xff0000);
			dot3.graphics.drawCircle(0,0,3);
			dot3.graphics.endFill();

			var dotsprite:Sprite = new Sprite();

			addChild(dot1);
			addChild(dot2);
			addChild(dot3);
		}

		public function setLoop():void{
			loop = true;
			if(loopshape == null || (loopshape != null && !contains(loopshape))){
				loopshape = new Shape();
				loopshape.graphics.beginFill(0xff0000);
				loopshape.graphics.drawCircle(0,0,15);
				loopshape.graphics.drawCircle(0,0,13);
				loopshape.graphics.endFill();

				addChild(loopshape);
			}
		}

		public function unsetLoop():void{
			loop = false;
			if(loopshape != null && contains(loopshape)){
				removeChild(loopshape);
			}
		}

		private function clearChildren():void{
			while(numChildren >0){
				removeChildAt(0);
			}
		}

		public function setCurrent():void{
			current = true;
		}

		public function unsetCurrent():void{
			current = false;
		}

		public function setDragging():void{
			// we need a larger hit area for the current dot in order for the mouse to "stay on the dot" during snapping operations
			if(hitshape == null || (hitshape != null && !contains(hitshape))){
				hitshape = new Shape();
				hitshape.graphics.beginFill(0xff0000);
				hitshape.graphics.drawCircle(0,0,80);
				hitshape.graphics.endFill();
				hitshape.alpha = 0;
				addChild(hitshape);
			}
		}

		public function unsetDragging():void{
			if(hitshape != null && contains(hitshape)){
				removeChild(hitshape);
			}
		}

		// identifies this dot as a sketch dot
		public function setSketch():void{
			clearChildren();
			var sketchshape:Shape = new Shape();
			sketchshape.graphics.beginFill(0xffdd00);
			sketchshape.graphics.drawCircle(0,0,22);
			sketchshape.graphics.endFill();

			addChild(sketchshape);
		}

	}
}