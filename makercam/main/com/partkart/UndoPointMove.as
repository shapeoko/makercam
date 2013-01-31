package com.partkart{
	
	import flash.geom.Point;
	
	public class UndoPointMove extends Undo{
		
		public var point:Point;
		
		public var undopoint:Point;
		public var redopoint:Point;
		
		public var path:Path;
		
		public function UndoPointMove(s:SceneGraph):void{
			super(s);
		}
		
		public override function undoAction():void{
			point.x = undopoint.x;
			point.y = undopoint.y;
			path.dirty = true;
			path.camdirty = true;
		}
		
		public override function redoAction():void{
			point.x = redopoint.x;
			point.y = redopoint.y;
		}
	}
}