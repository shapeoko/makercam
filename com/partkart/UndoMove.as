package com.partkart{

	public class UndoMove extends Undo{

		public var pathlist:Array;
		public var xdelta:Number;
		public var ydelta:Number;

		public function UndoMove(s:SceneGraph):void{
			super(s);
		}

		public override function undoAction():void{
			for each(var path:* in pathlist){
				path.docx -= xdelta;
				path.docy -= ydelta;
				if(path is Path){
					path.dirty = true;
					path.camdirty = true;
				}
			}
		}

		public override function redoAction():void{
			for each(var path:* in pathlist){
				path.docx += xdelta;
				path.docy += ydelta;
			}
		}
	}
}