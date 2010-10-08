package com.partkart{
	
	public class UndoDelete extends Undo{
		
		public var pathlist:Array;
		public var cutlist:Array;
		public var cutparent:Array;
		
		public function UndoDelete(s:SceneGraph):void{
			super(s);
		}
		
		public override function undoAction():void{
			for each(var path:Path in pathlist){
				scene.addPath(path);
				path.dirty = true;
				path.camdirty = true;
			}
			for each(var cut:CutObject in cutlist){
				scene.addCut(cut);
			}
			for each(var obj:Object in cutparent){
				if(obj.cut.pathlist.indexOf(obj.path) == -1){
					obj.cut.pathlist.push(obj.path);
				}
			}
		}
		
		public override function redoAction():void{
			for each(var path:Path in pathlist){
				scene.removePath(path);
			}
			for each(var cut:CutObject in cutlist){
				scene.removeCut(cut);
			}
			for each(var obj:Object in cutparent){
				var index:int = obj.cut.pathlist.indexOf(obj.path);
				if(index != -1){
					obj.cut.pathlist.splice(index,1);
				}
			}
		}
	}
}