package {

	import flash.display.*;
	import flash.ui.Keyboard;
	import flash.events.*;
	import flash.text.*;
	import flash.geom.Point;
	import flash.utils.Timer;
	import fl.controls.ComboBox;
	import flash.ui.Mouse;
	import flash.net.FileReference;
	import fl.data.DataProvider;
	import flash.filters.BlurFilter;
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.ui.MouseCursor;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import fl.events.ListEvent;
	
	import com.partkart.*;
	import com.lorentz.SVG.*;
	
	public class Main extends Sprite {
		
		private var grid:Grid;
		
		public var scene:SceneGraph;
		
		private var background:Sprite; // background image
		private var backgroundscale:Number = 72;
		private var backgroundvisibility:Number = 50;
		
		public var xstart:Number = 0;
		public var ystart:Number = 0;
		
		private var dragging:Boolean = false;
		
		private var xoriginstart:Number;
		private var yoriginstart:Number;
		
		private var sketch:Sketch; // draw one sketch at a time
		private var sketchdot:Dot; // currently active sketchdot for path joining after sketch operation
		
		private var imposter:Sprite; // the imposter "pretends" to be the scene graph during zoom operations, this makes the app more responsive with extremely complex files
		private var zooming:Boolean = false; // flag used to indicate that a zoom operation is in progress
		private var startzoom:Number;
		
		private var now:int = 0;
		private var timer:Timer;
		
		private var temptool:int = 0; // temporary holder for the tool number while we display a modal dialog
		
		private var file:FileReference;
		private var progressdialog:ProgressDialog;
		
		private var partkart:PartKart;
		public function Main() {
			// partkart related functions
			partkart = new PartKart(this);
			
			// setup stage scale mode and alignment
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			stage.addEventListener(Event.RESIZE, stageResize);
			
			//stage.dispatchEvent(new Event(Event.RESIZE));
			
			background = new Sprite();
			addChild(background);
			
			grid = new Grid();
			addChild(grid);
			
			scene = SceneGraph.getInstance();
			addChild(scene);
			
			//setChildIndex(tools, numChildren-1) // tools pallete on top
			addChild(tools);
			attachToolsListeners();
			
			// now add paths and stuff
			/*var path1 = new Path();
			var s1 = new Segment(new Point(1,1), new Point(3,3));
			var s2 = new Segment(s1.p2, new Point(5,3));
			var s3 = new QuadBezierSegment(s2.p2, new Point(7,3), new Point(8,2));
			var s4 = new CubicBezierSegment(s3.p2, new Point(7,6), new Point(8,2), new Point(8,5));
			var s5 = new ArcSegment(s4.p2, new Point(6,6),1,1,180,true,true);
			var s6 = new Segment(s5.p2, s1.p1);
			path1.addSegment(s1);
			path1.addSegment(s2);
			path1.addSegment(s3);
			path1.addSegment(s4);
			path1.addSegment(s5);
			path1.addSegment(s6);*/
			
			/*var path2 = new Path();
			s1 = new Segment(new Point(1,1), new Point(3,3));
			s2 = new Segment(new Point(3,3), new Point(5,3));
			path2.addSegment(s1);
			path2.addSegment(s2);*/
			
			//trace(path1.isClosed());
			//trace(path2.isClosed());
			
			//scene.addPath(path1);
			//addPath(path2);
			
			addEventListener(MouseEvent.MOUSE_DOWN, mainMouseDown);
			addEventListener(MouseEvent.MOUSE_UP, mainMouseUp);
			//addEventListener(MouseEvent., mainMiddleDown);
			stage.addEventListener(Event.MOUSE_LEAVE, mainMouseLeave);
			
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, mainKeyDown);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, mainKeyUp);
			
			stage.dispatchEvent(new Event(Event.RESIZE));
			
			scene.redraw();
		}
		
		public function stageResize(e:Event){
			if(stage.stageWidth > 400){
				tools.background.width = stage.stageWidth;
				tools.viewcuts.x = stage.stageWidth - 254;
				tools.snap.x = stage.stageWidth - 173;
				tools.unit.x = stage.stageWidth - 111;
				tools.zoomin.x = stage.stageWidth - 53;
				tools.zoomout.x = stage.stageWidth - 29;
			}
			
			// resize from bottom left corner
			Global.yorigin += stage.stageHeight - Global.docheight;
			
			Global.docwidth = stage.stageWidth;
			Global.docheight = stage.stageHeight;
			grid.clear();
			grid.init();
			
			// redraw scene
			scene.redraw();
		}
		
		public function mainMouseDown(e:MouseEvent):void{
			
			// remove all selectareas
			if(getChildByName("selectarea")){
				removeChild(getChildByName("selectarea"));
			}
			
			if(Global.tool != 99){
				scene.clearDots();
				clearMenu();
				tools.active = false;
				stage.focus = null;
			}
			
			if(Global.space == true && Global.tool != 99){ // tool 99 means "no tool"
				mainStartDrag(e);
			}
			else{
				switch(Global.tool){
					case 0:
						mainStartSelect(e);
						scene.setInactive();
					break;
					case 2:
						mainStartDrag(e);
						//scene.shiftActive();
						//scene.redraw();
					break;
					case 1:
						startSketch(e);
					break;
				}
			}
		}
		
		/*public function mainMiddleDown(e:MouseEvent):void{
			mainStartDrag(e);
		}*/
		
		public function mainStartDrag(e:MouseEvent):void{
			addChild(tools); // tools should be on top when dragging
			xstart = e.stageX;
			ystart = e.stageY;
			xoriginstart = Global.xorigin;
			yoriginstart = Global.yorigin;
			dragging = true;
			Global.dragging = true;
			
			addEventListener(MouseEvent.MOUSE_MOVE, mainDrag);
		}
		
		public function mainDrag(e:MouseEvent):void{
			if(dragging && (Global.tool == 2 || Global.space == true) && Global.tool != 99){
				var xdelta:Number = e.stageX - xstart;
				var ydelta:Number = e.stageY - ystart;
				
				Global.xorigin = xoriginstart + xdelta;
				Global.yorigin = yoriginstart + ydelta;
				grid.setOrigin();
				redrawBackground();
				
				// update path positions
				scene.x = Global.xorigin;
				scene.y = Global.yorigin;
			}
			else if(dragging && Global.tool == 0){
				var selectbox:Sprite = getChildByName("selectarea") as Sprite;
				
				if(selectbox != null){
					var b:Shape = selectbox.getChildAt(0) as Shape;
					
					var xs:Number;
					var ys:Number;
					
					var w:Number;
					var h:Number;
					
					if(e.stageX > xstart){
						xs = 0;
						w = e.stageX - xstart;
					}
					else{
						xs = e.stageX - xstart;
						w = xstart - e.stageX;
					}
					
					if(e.stageY > ystart){
						ys = 0;
						h = e.stageY - ystart;
					}
					else{
						ys = e.stageY - ystart;
						h = ystart - e.stageY;
					}
					
					b.x = xs;
					b.y = ys;
					b.width = w;
					b.height = h;
				}
			}
		}
		
		public function mainMouseUp(e:MouseEvent):void{
			dragging = false;
			Global.dragging = false;
			removeEventListener(MouseEvent.MOUSE_MOVE, mainDrag);
			
			mainFinishSelect();
		}
		
		public function mainStartSelect(e:MouseEvent):void{
			
			//mainStartDrag(e);
			addChild(tools); // tools should be on top when dragging
			xstart = e.stageX;
			ystart = e.stageY;
			
			dragging = true;
			Global.dragging = true;
			
			addEventListener(MouseEvent.MOUSE_MOVE, mainDrag);
			
			var selectbox:Sprite = new Sprite();
			selectbox.name = "selectarea";
			
			selectbox.x = e.stageX;
			selectbox.y = e.stageY;
			
			var box:Shape = new Shape();
			box.graphics.beginFill(0xbce4fe);
			box.graphics.drawRect(0,0,1,1);
			box.graphics.endFill();
			
			box.alpha = 0.5;
			
			selectbox.addChild(box);
			addChild(selectbox);
			
			scene.cacheAsBitmap = false;
		}
		
		public function mainFinishSelect():void{
			var selectbox:Sprite = getChildByName("selectarea") as Sprite;
			if(selectbox != null && selectbox.width > 1 && selectbox.height > 1){
				
				scene.addChild(selectbox);
				selectbox.x -= scene.x;
				selectbox.y -= scene.y;
				
				scene.select(selectbox);
				
				scene.removeChild(selectbox);
			}
			scene.cacheAsBitmap = true;
		}
		
		public function mainMouseLeave(e:Event):void{
			// this function is required to handle cases where the mouse leaves the stage
			if(dragging == true){
				dragging = false;
				Global.dragging = false;
				removeEventListener(MouseEvent.MOUSE_MOVE, mainDrag);
				mainFinishSelect();
			}
			
			scene.mouseLeave();
		}
		
		public function mainKeyDown(e:KeyboardEvent):void{				
			if(e.ctrlKey || e.shiftKey){
				scene.ctrl = true;
			}
			else if(e.keyCode == 32 && Global.space == false){ // space key
				Global.space = true;
				Mouse.cursor = MouseCursor.HAND;
				scene.clearDots();
				//scene.redraw();
			}
			else if(e.keyCode == 46 || e.keyCode == 8){ // delete key
				if(stage.focus == null){
					scene.deleteSelected();
				}
			}
		}
		
		public function mainKeyUp(e:KeyboardEvent):void{
			if(e.ctrlKey == true && e.keyCode == 67){
				scene.startCopy();
			}
			else if(e.ctrlKey == true && e.keyCode == 86){
				var p:Point = new Point((this.mouseX-Global.xorigin)/Global.zoom, (-this.mouseY+Global.yorigin)/Global.zoom);
				trace("paste point: ", p);
				scene.startPaste(p);
			}
			
			if(!e.ctrlKey || !e.shiftKey){
				scene.ctrl = false;
			}
			if(e.keyCode == 32){
				Global.space = false;
				setCursor();
			}
		}
		
		public function attachToolsListeners():void{
			
			tools.addEventListener(MouseEvent.MOUSE_OVER, toolsOver);
			tools.addEventListener(MouseEvent.MOUSE_DOWN, toolsDown);
			tools.addEventListener(MouseEvent.MOUSE_MOVE, toolsMove);
			tools.addEventListener(MouseEvent.MOUSE_UP, toolsUp);
			tools.addEventListener(MouseEvent.MOUSE_OUT, toolsOut);
			
			tools.tool0.addEventListener(MouseEvent.MOUSE_OVER, toolOver);
			tools.tool1.addEventListener(MouseEvent.MOUSE_OVER, toolOver);
			tools.tool2.addEventListener(MouseEvent.MOUSE_OVER, toolOver);
			
			tools.tool0.addEventListener(MouseEvent.MOUSE_DOWN, toolDown);
			tools.tool1.addEventListener(MouseEvent.MOUSE_DOWN, toolDown);
			tools.tool2.addEventListener(MouseEvent.MOUSE_DOWN, toolDown);
			
			tools.tool0.addEventListener(MouseEvent.MOUSE_OUT, toolOut);
			tools.tool1.addEventListener(MouseEvent.MOUSE_OUT, toolOut);
			tools.tool2.addEventListener(MouseEvent.MOUSE_OUT, toolOut);
			
			tools.zoomin.addEventListener(MouseEvent.CLICK, zoomIn);
			tools.zoomout.addEventListener(MouseEvent.CLICK, zoomOut);
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, zoomWheel);
			
			tools.unit.addEventListener(Event.CHANGE, unitChange);
			
			tools.snap.addEventListener(Event.CHANGE, snapChange);
			tools.viewcuts.addEventListener(Event.CHANGE, viewcutsChange);
			
			tools.active = false;
			
			tools.mFile.mouseChildren = false;
			tools.mEdit.mouseChildren = false;
			tools.mInsert.mouseChildren = false;
			tools.mCAM.mouseChildren = false;
			tools.mToolpaths.mouseChildren = false;
			tools.mNesting.mouseChildren = false;
			tools.mPartkart.mouseChildren = false;
			
			tools.dFile.visible = false;
			tools.dEdit.visible = false;
			tools.dInsert.visible = false;
			tools.dCAM.visible = false;
			tools.dToolpaths.visible = false;
			tools.dNesting.visible = false;
			tools.dPartkart.visible = false;
			
			tools.dFile.addEventListener(Event.CHANGE, menuSelect);
			tools.dEdit.addEventListener(Event.CHANGE, menuSelect);
			tools.dInsert.addEventListener(Event.CHANGE, menuSelect);
			tools.dCAM.addEventListener(Event.CHANGE, menuSelect);
			tools.dToolpaths.addEventListener(Event.CHANGE, menuSelect);
			tools.dNesting.addEventListener(Event.CHANGE, menuSelect);
			tools.dPartkart.addEventListener(Event.CHANGE, menuSelect);	
			tools.dToolpaths.addEventListener(ListEvent.ITEM_ROLL_OVER, toolpathOver);
			
			tools.mFile.drop = tools.dFile;
			tools.mEdit.drop = tools.dEdit;
			tools.mInsert.drop = tools.dInsert;
			tools.mCAM.drop = tools.dCAM;
			tools.mToolpaths.drop = tools.dToolpaths;
			tools.mNesting.drop = tools.dNesting;
			tools.mPartkart.drop = tools.dPartkart;
			
			tools.mFile.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mEdit.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mInsert.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mCAM.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mToolpaths.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mNesting.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			tools.mPartkart.addEventListener(MouseEvent.ROLL_OVER, menuOver);
			
			tools.mFile.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mEdit.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mInsert.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mCAM.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mToolpaths.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mNesting.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			tools.mPartkart.addEventListener(MouseEvent.ROLL_OUT, menuOut);
			
			tools.mFile.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mEdit.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mInsert.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mCAM.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mToolpaths.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mNesting.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
			tools.mPartkart.addEventListener(MouseEvent.MOUSE_DOWN, menuDown);
		}
		
		public function clearMenu():void{
			tools.mFile.highlightDown.alpha = 0;
			tools.mEdit.highlightDown.alpha = 0;
			tools.mInsert.highlightDown.alpha = 0;
			tools.mCAM.highlightDown.alpha = 0;
			tools.mToolpaths.highlightDown.alpha = 0;
			tools.mNesting.highlightDown.alpha = 0;
			tools.mPartkart.highlightDown.alpha = 0;

			tools.mFile.highlightUp.alpha = 0;
			tools.mEdit.highlightUp.alpha = 0;
			tools.mInsert.highlightUp.alpha = 0;
			tools.mCAM.highlightUp.alpha = 0;
			tools.mToolpaths.highlightUp.alpha = 0;
			tools.mNesting.highlightUp.alpha = 0;
			tools.mPartkart.highlightUp.alpha = 0;
			
			tools.mFile.text.textColor =  0x000000;
			tools.mEdit.text.textColor =  0x000000;
			tools.mInsert.text.textColor =  0x000000;
			tools.mCAM.text.textColor =  0x000000;
			tools.mToolpaths.text.textColor =  0x000000;
			tools.mNesting.text.textColor =  0x000000;
			tools.mPartkart.text.textColor =  0x000000;
			
			tools.dFile.visible = false;
			tools.dEdit.visible = false;
			tools.dInsert.visible = false;
			tools.dCAM.visible = false;
			tools.dToolpaths.visible = false;
			tools.dNesting.visible = false;
			tools.dPartkart.visible = false;
			
			tools.dFile.clearSelection();
			tools.dEdit.clearSelection();
			tools.dInsert.clearSelection();
			tools.dCAM.clearSelection();
			tools.dToolpaths.clearSelection();
			tools.dNesting.clearSelection();
			tools.dPartkart.clearSelection();
		}
		
		public function toolsOver(e:MouseEvent):void{
			Mouse.cursor = MouseCursor.AUTO;
		}
		
		public function toolsDown(e:MouseEvent):void{
			e.stopPropagation();
			addChild(tools); // put on top of z stack
		}
		
		public function toolsMove(e:MouseEvent):void{
			e.stopPropagation();
		}
		
		public function toolsUp(e:MouseEvent):void{
			//e.stopPropagation();
		}
		
		public function toolsOut(e:MouseEvent):void{
			setCursor();
		}
		
		public function toolOver(e:MouseEvent):void{
			e.target.alpha = 0.5;
		}
		
		public function toolDown(e:MouseEvent):void{
			e.target.alpha = 1;
			if(e.target.name == "tool0"){
				Global.tool = 0;
				setZoom(Global.zoom); // re-render everything
			}
			else if(e.target.name == "tool1"){
				Global.tool = 1;
				setZoom(Global.zoom); // re-render everything
			}
			else if(e.target.name == "tool2"){
				Global.tool = 2;
				setZoom(Global.zoom); // re-render everything
			}
			
			setCursor();
		}
		
		public function toolOut(e:MouseEvent):void{
			e.target.alpha = 1;
		}
		
		public function menuOver(e:MouseEvent):void{
			if(tools.active == false){
				e.target.getChildByName("highlightUp").alpha = 0.15;
			}
			else if(e.target){
				clearMenu();
				e.target.getChildByName("highlightDown").alpha = 1;
				var t:TextField = e.target.getChildByName("text") as TextField;
				t.textColor = 0xffffff;
				if(e.target.drop){
					e.target.drop.visible = true;
				}
			}
		}
		
		public function menuOut(e:MouseEvent):void{
			if(tools.active == false){
				e.target.getChildByName("highlightUp").alpha = 0;
				var t:TextField = e.target.getChildByName("text") as TextField;
				t.textColor = 0x000000;
			}
		}
		
		public function toolpathOver(e:ListEvent):void{
			for each(var cut:CutObject in scene.cutlist){
				cut.setInactive();
			}
			e.item.data.setActive();
		}
		
		public function menuDown(e:MouseEvent):void{
			var t:TextField = e.target.getChildByName("text") as TextField;
			
			if(tools.active == true){
				tools.active = false;
				clearMenu();
			}
			else{
				tools.active = true;
				
				clearMenu();
				
				e.target.getChildByName("highlightDown").alpha = 1;
				if(e.target.drop){
					e.target.drop.visible = true;
				}
				
				t.textColor = 0xffffff;
			}
		}
		
		public function menuSelect(e:Event):void{
			if(e.target == tools.dFile){
				switch(e.target.selectedIndex){
					case 0:
						// import file
						trace("import!");
						loadFile();
					break;
					case 1:
						// export file
						trace("export!");
						saveFile();
					break;
				}
			}
			else if(e.target == tools.dEdit){
				switch(e.target.selectedIndex){
					case 0:
						// undo
						Global.undoAction();
						scene.redraw();
					break;
					case 1:
						// redo
						Global.redoAction();
						scene.redraw();
					break;
					case 2:
						// copy
						scene.startCopy();
					break;
					case 3:
						// paste
						scene.startPaste();
					break;
					case 4:
						startDialog(120, 100, new Array({type: "number", label:"Scale X (%)", value: 100},
														{type: "number", label:"Scale Y (%)", value: 100}),
														"scale");
					break;
					case 5:
						startDialog(120, 50, new Array({type: "number", label:"Rotate (degrees)", value: "0"}),
														"rotate");
					break;
					case 6:
						startDialog(120, 100, new Array({type: "number", label:"Skew X (%)", value: "0"},
														{type: "number", label:"Skew Y (%)", value: "0"}),
														"skew");
					break;
					case 7:
						scene.separateSelected();
					break;
					case 8:
						startDialog(200, 100, new Array({type: "file", label:"Load Image From Disk"},
														{type:"number", label: "Image Resolution (px/"+Global.unit+")", value: backgroundscale},
														{type:"number", label:"Visibility (%)", value: String(backgroundvisibility)}),
														"background");
					break;
					case 9:
						startDialog(250, 200, new Array({type: "number", label:"SVG Import Default Resolution (px/inch)", value:Global.importres},
														{type:"label", label:"Common values:"},
														{type:"label", label:"Illustrator: 72, Inkscape: 90"},
														{type:"label", label:""},
														{type:"checkbox", label:"Snap to local points", value:Global.localsnap},
														{type:"label", label:""},
														{type: "number", label: "Machining Tolerance ("+Global.unit+")", value: Global.tolerance},
														{type: "number", label: "Bitmap Tolerance", value: Global.bitmaptolerance},
														{type: "number", label: "Nesting Bitmap Size", value: Global.nestbitmapsize},
														{type: "checkbox", label: "Separate Toolpaths by Boundary", value: Global.separatetoolpaths}),
														"preferences");
					break;
				}
			}
			else if(e.target == tools.dInsert){
				switch(e.target.selectedIndex){
					case 0:
						// add circle
						startDialog(120, 50, new Array({type:"number", label:"Diameter ("+Global.unit+")", value:1}),
														"addcircle");
					break;
					case 1:
						// add ellipse
						startDialog(120, 100, new Array(
														{type:"number", label:"Ellipse Width ("+Global.unit+")", value:1},
														{type:"number", label:"Ellipse Height ("+Global.unit+")", value:1}),
														"addellipse");
					break;
					case 2:
						// add rectangle
						startDialog(150, 100, new Array({type:"number", label:"Rectangle Width ("+Global.unit+")", value:1},
														{type:"number", label:"Rectangle Height ("+Global.unit+")", value:1}),
														"addrectangle");
					break;
					case 3:
						// add rounded rectangle
						startDialog(150, 100, new Array({type:"number", label:"Rectangle Width ("+Global.unit+")", value:1},
														{type:"number", label:"Rectangle Height ("+Global.unit+")", value:1},
														{type:"number", label:"Corner Radius ("+Global.unit+")", value:0.2}),
														"addroundedrectangle");
					break;
					case 4:
						// add polygon
						startDialog(120, 100, new Array({type:"number", label:"Number of Sides", value:6},
														{type:"number", label:"Radius ("+Global.unit+")", value:1}),
														"addpolygon");
					break;
					case 5:
						// add star
						startDialog(120, 100, new Array({type:"number", label:"Number of Points", value:6},
														{type:"number", label:"Radius ("+Global.unit+")", value:1},
														{type:"number", label:"Pointiness (%)", value:50}),
														"addstar");
					break;
				}
			}
			else if(e.target == tools.dCAM){
				var selected:Boolean;
				var p:Path;
				var closed:Boolean;
				var unit:String;
				
				// setup default values to populate fields
				
				var safetyheight:Number = Global.unit == "in" ? 0.5 : 15;
				var stocksurface:String = "0";
				var targetdepth:Number  = Global.unit == "in" ? -0.75 : -10;
				var stepdown:Number = Global.unit == "in" ? 0.05 : 1.5;
				var stepover:Number = 40;
				var feedrate:Number = Global.unit == "in" ? 60 : 1500;
				var plungerate:Number = Global.unit == "in" ? 30 : 800;
				
				var tooldiameter:Number = Global.unit == "in" ? 0.25 : 5;
				var roughingclearance:String = "0";
				
				switch(e.target.selectedIndex){
					case 0:
						// make sure at least one path is selected
						selected = false;
						for each(p in scene.pathlist){
							closed = p.isClosed();
							if(p.active == true && closed){
								selected = true;
							}
							else if(p.active == true && !closed){
								p.setInactive();
							}
						}
						
						if(selected == false){
							startDialog(240, 50, new Array({type:"label", label:"Please select at least one closed path"}), "error");
						}
						else{
					
							unit = Global.unit == "in" ? "in" : "mm";
							
							startDialog(150,200, new Array({type:"string", label:"name", value:"profile "+(scene.cutlist.length+1)},
															{type:"number", label:"tool diameter ("+unit+")", value: tooldiameter, highlight: true},
															{type:"number", label:"target depth ("+unit+")", value: targetdepth, highlight: true},
														   {type:"combobox", label:"inside/outside", items:new Array({label:"Outside", data:true},{label:"Inside", data:false})},
														   {type:"number", label:"safety height ("+unit+")", value:safetyheight},
														   {type:"number", label:"stock surface ("+unit+")", value: stocksurface},
														   {type:"number", label:"step down ("+unit+")", value: stepdown},
														   {type:"number", label:"feed rate ("+unit+"/minute)", value: feedrate},
														   {type:"number", label:"plunge rate ("+unit+"/minute)", value: plungerate}),
														   "profile");
						}
					break;
					case 1:
						// make sure at least one path is selected
						selected = false;
						for each(p in scene.pathlist){
							closed = p.isClosed();
							if(p.active == true && closed){
								selected = true;
							}
							else if(p.active == true && !closed){
								p.setInactive();
							}
						}
						
						if(selected == false){
							startDialog(240, 50, new Array({type:"label", label:"Please select at least one closed path"}), "error");
						}
						else{
					
							unit = Global.unit == "in" ? "in" : "mm";
							
							startDialog(150,200, new Array({type:"string", label:"name", value:"pocket "+(scene.cutlist.length+1)},
															{type:"number", label:"tool diameter ("+unit+")", value: tooldiameter, highlight: true},
															{type:"number", label:"target depth ("+unit+")", value: targetdepth, highlight: true},
														   {type:"number", label:"safety height ("+unit+")", value: safetyheight},
														   {type:"number", label:"stock surface ("+unit+")", value: stocksurface},
														   {type:"number", label:"step over (%)", value: stepover},
														   {type:"number", label:"step down ("+unit+")", value: stepdown},
														   {type:"number", label:"roughing clearance ("+unit+")", value: roughingclearance},
														   {type:"number", label:"feedrate ("+unit+"/minute)", value: feedrate},
														   {type:"number", label:"plunge rate ("+unit+"/minute)", value: plungerate}),
														   "pocket");
						}
					break;
					case 2:
						selected = false;
						for each(p in scene.pathlist){
							if(p.active == true){
								selected = true;
							}
						}
						
						if(selected == false){
							startDialog(230, 50, new Array({type:"label", label:"Please select at least one path"}), "error");
						}
						else{
					
							unit = Global.unit == "in" ? "in" : "mm";
							
							startDialog(150,200, new Array({type:"string", label:"name", value:"follow path "+(scene.cutlist.length+1)},
														   {type:"number", label:"tool diameter ("+unit+")", value: tooldiameter, highlight: true},
														   {type:"number", label:"target depth ("+unit+")", value: targetdepth, highlight: true},
														   {type:"number", label:"safety height ("+unit+")", value: safetyheight},
														   {type:"number", label:"stock surface ("+unit+")", value: stocksurface},
														   {type:"number", label:"step down ("+unit+")", value: stepdown},
														   {type:"number", label:"feedrate ("+unit+"/minute)", value: feedrate},
														   {type:"number", label:"plunge rate ("+unit+"/minute)", value: plungerate}),
														   "followpath");
						}
					break;
					case 3:
					// drill operation
					unit = Global.unit == "in" ? "in" : "mm";
							
					startDialog(150,200, new Array({type:"string", label:"name", value:"drill "+(scene.cutlist.length+1)},
												   {type:"number", label:"tool diameter ("+unit+")", value: tooldiameter, highlight: true},
												   {type:"number", label:"target depth ("+unit+")", value: targetdepth, highlight: true},
												   {type:"combobox", label:"drill location", items:new Array({label:"path center", data:true},{label:"fill pattern", data:false}), value: true, highlight: true},
												   {type:"number", label:"hole spacing ("+unit+")", value: tooldiameter*2, highlight: true},
												   {type:"number", label:"safety height ("+unit+")", value: safetyheight},
												   {type:"number", label:"stock surface ("+unit+")", value: stocksurface},
												   {type:"number", label:"peck distance ("+unit+")", value: stepdown},
												   {type:"number", label:"plunge rate ("+unit+"/minute)", value: plungerate}),
												   "drill");
					break;
					case 4:
					// add tabs
					
					// check that there is at least one calculated profile op
					var valid:Boolean = false;
					for each(var cutobject:CutObject in scene.cutlist){
						if(cutobject is ProfileCutObject && cutobject.processed == true){
							valid = true;
							break;
						}
					}
					
					if(!valid){
						startDialog(320,50,new Array({type:"label", label:"Please select at least one calculated profile operation"}), "error");
						return;
					}
					
					startDialog(150,200, new Array({type:"number", label:"tab spacing ("+Global.unit+")", value: Global.unit == "in" ? 5 : 15},
												   {type:"number", label:"tab width ("+Global.unit+")", value: Global.unit == "in" ? .25 : 0.5},
												   {type:"number", label:"tab height ("+Global.unit+")", value: Global.unit == "in" ? .25 : 0.5}),
												   "tabs");
					break;
					case 5:
						var pd:ProgressDialog = startProgressDialog(250, 75, "processing", "Cancel", scene.cutCancel);
						scene.reprocessCuts(pd);
					break;
					case 6:
						var processed:Array = scene.getProcessedCuts();
						var fields:Array = new Array();
						for each(var cut:CutObject in processed){
							fields.push({label: cut.name + " ("+Global.toFixed(cut.tooldiameter, 10/Global.tolerance)+")", data: cut, diameter: cut.tooldiameter});
						}
						startDialog(300,200, new Array({type:"cutlist", label:"calculated toolpaths", value: fields},
												   {type:"combobox", label:"post processor", items:new Array({label:"Standard G-Code", data:0}), value: 0}),
												   "exportgcode", "Export Selected Toolpaths", false);
					break;
				}
			}
			else if(e.target == tools.dToolpaths){
				
				var selectedindex:int = tools.dToolpaths.selectedIndex;
				
				unit = Global.unit == "in" ? "in" : "mm";
				
				if(e.target.selectedItem.data is ProfileCutObject){
					var profile:ProfileCutObject = e.target.selectedItem.data as ProfileCutObject;
					startDialog(150,200, new Array({type:"string", label:"name", value: profile.name},
												   {type:"number", label:"tool diameter ("+unit+")", value: unit == "mm" ? 10*profile.tooldiameter : profile.tooldiameter, highlight: true},
												   {type:"number", label:"target depth ("+unit+")", value: profile.targetdepth == 0 ? String(profile.targetdepth): profile.targetdepth, highlight: true},
												   {type:"combobox", label:"inside/outside", items:new Array({label:"Outside", data:true},{label:"Inside", data:false}), value: profile.outside},
												   {type:"number", label:"safety height ("+unit+")", value: profile.safetyheight == 0 ? String(profile.safetyheight) : profile.safetyheight},
												   {type:"number", label:"stock surface ("+unit+")", value: profile.stocksurface == 0 ? String(profile.stocksurface): profile.stocksurface},
												   {type:"number", label:"step down ("+unit+")", value: profile.stepdown},
												   {type:"number", label:"feedrate ("+unit+"/minute)", value: profile.feedrate},
												   {type:"number", label:"plunge rate ("+unit+"/minute)", value: profile.plungerate}),
												   "editprofile");
				}
				else if(e.target.selectedItem.data is PocketCutObject){
					var pocket:PocketCutObject = e.target.selectedItem.data as PocketCutObject;
					startDialog(150,200, new Array({type:"string", label:"name", value: pocket.name},
												   {type:"number", label:"tool diameter ("+unit+")", value: unit == "mm" ? 10*pocket.tooldiameter : pocket.tooldiameter, highlight: true},
												   {type:"number", label:"target depth ("+unit+")", value: pocket.targetdepth == 0 ? String(pocket.targetdepth) : pocket.targetdepth, highlight: true},
												   {type:"number", label:"safety height ("+unit+")", value: pocket.safetyheight == 0 ? String(pocket.safetyheight) : pocket.safetyheight},
												   {type:"number", label:"stock surface ("+unit+")", value: pocket.stocksurface == 0 ? String(pocket.stocksurface) : pocket.stocksurface},
												   {type:"number", label:"step over (%)", value: 100*pocket.stepover},
												   {type:"number", label:"step down ("+unit+")", value: pocket.stepdown},
												   {type:"number", label:"roughing clearance ("+unit+")", value: pocket.roughingclearance == 0 ? "0" :(unit == "mm" ? 10*pocket.roughingclearance : pocket.roughingclearance)},
												   {type:"number", label:"feedrate ("+unit+"/minute)", value: pocket.feedrate},
												   {type:"number", label:"plunge rate ("+unit+"/minute)", value: pocket.plungerate}),
												   "editpocket");
				}
				else if(e.target.selectedItem.data is FollowPathCutObject){
					var follow:FollowPathCutObject = e.target.selectedItem.data as FollowPathCutObject;
					startDialog(150,200, new Array({type:"string", label:"name", value: follow.name},
												   {type:"number", label:"tool diameter ("+unit+")", value: unit == "mm" ? 10*follow.tooldiameter : follow.tooldiameter, highlight: true},
												   {type:"number", label:"target depth ("+unit+")", value: follow.targetdepth == 0 ? String(follow.targetdepth) : follow.targetdepth, highlight: true},
												   {type:"number", label:"safety height ("+unit+")", value: follow.safetyheight == 0 ? String(follow.safetyheight) : follow.safetyheight},
												   {type:"number", label:"stock surface ("+unit+")", value: follow.stocksurface == 0 ? String(follow.stocksurface) : follow.stocksurface},
												   {type:"number", label:"step down ("+unit+")", value: follow.stepdown},
												   {type:"number", label:"feedrate ("+unit+"/minute)", value: follow.feedrate},
												   {type:"number", label:"plunge rate ("+unit+"/minute)", value: follow.plungerate}),
												   "editfollowpath");
				}
				else if(e.target.selectedItem.data is DrillCutObject){
					var drill:DrillCutObject = e.target.selectedItem.data as DrillCutObject;
					startDialog(150,200, new Array({type:"string", label:"name", value: drill.name},
												   {type:"number", label:"tool diameter ("+unit+")", value: unit == "mm" ? 10*drill.tooldiameter : drill.tooldiameter, highlight: true},
												   {type:"number", label:"target depth ("+unit+")", value: drill.targetdepth == 0 ? String(drill.targetdepth) : drill.targetdepth, highlight: true},
												   {type:"combobox", label:"drill location", items:new Array({label:"path center", data:true},{label:"fill pattern", data:false}), value: drill.center, highlight: true},
												   {type:"number", label:"hole spacing ("+unit+")", value: unit == "mm" ? 10*drill.spacing : drill.spacing, highlight: true},
												   {type:"number", label:"safety height ("+unit+")", value: drill.safetyheight == 0 ? String(drill.safetyheight) : drill.safetyheight},
												   {type:"number", label:"stock surface ("+unit+")", value: drill.stocksurface == 0 ? String(drill.stocksurface) : drill.stocksurface},
												   {type:"number", label:"peck distance ("+unit+")", value: drill.stepdown},
												   {type:"number", label:"plunge rate ("+unit+"/minute)", value: drill.plungerate}),
												   "editdrill");
				}
			}
			else if(e.target == tools.dNesting){
				switch(e.target.selectedIndex){
					case 0:
						var selectedpaths:Array = new Array();
						for each(var path:Path in scene.pathlist){
							if(path.active == true){
								selectedpaths.push(path);
							}
						}
						
						if(selectedpaths.length != 1){
							startDialog(375,50,new Array({type:"label", label:"Please specify exactly one closed path to act as the material boundary"}), "error");
						}
						else if(!selectedpaths[0].isClosed()){
							startDialog(230,50,new Array({type:"label", label:"The selected path is not a closed path"}), "error");
						}
						else{
							scene.nestpath = selectedpaths[0];
						}
					break;
					case 1:
						if(scene.nestpath == null || !scene.contains(scene.nestpath)){
							startDialog(330,50,new Array({type:"label", label:"Please specify a closed path to act as the material boundary"}), "error");
						}
						else{
							startDialog(200, 100, new Array({type:"number", label:"angles", value: 4},
															{type:"number", label:"space between objects ("+Global.unit+")", value: '0'},
															{type:"checkbox", label:"group overlapping toolpaths", value: true},
															{type:"checkbox", label:"group profile operations", value: false}),
															"startnest");
						}
					break;
				}
			}
			else if(e.target == tools.dPartkart){
				switch(e.target.selectedIndex){
					case 0:
						partkart.order(scene.getActiveCuts());
					break;
					case 1:
						partkart.order(scene.cutlist.slice());
					break;
				}
				
				scene.redraw();
			}
			
			clearMenu();
			tools.active = false;
			
			// select the item in the toolpath menu for further processing
			if(e.target == tools.dToolpaths){
				tools.dToolpaths.selectedIndex = selectedindex;
			}
		}
		
		public function setCursor():void{
			if(Global.tool == 0){
				Mouse.cursor = MouseCursor.AUTO;
			}
			else if(Global.tool == 1){
				Mouse.cursor = MouseCursor.BUTTON;
			}
			else if(Global.tool == 2){
				Mouse.cursor = MouseCursor.HAND;
			}
		}
		
		public function zoomIn(e:MouseEvent):void{
			if(Global.zoom < 200){
				setZoom(Global.zoom*1.2);
			}
		}
		
		public function zoomOut(e:MouseEvent):void{
			if(Global.zoom > 15){
				setZoom(Global.zoom*0.8);
			}
		}
		
		public function zoomWheel(e:MouseEvent):void{
			if(Global.dragging == false && Global.tool != 99){
				
				if(zooming == false){
					zooming = true;
					//stage.quality = StageQuality.LOW;
					//scene.cacheAsBitmap = false;
					startzoom = Global.zoom;
					timer = new Timer(100,1);
					timer.addEventListener(TimerEvent.TIMER_COMPLETE, finishZoom);
					timer.start();
				}
				else{
					if(timer){
						timer.reset();
						timer.start();
					}
				}
				
				var d:int = e.delta/Math.abs(e.delta);
				if(d < 0){
					if(Global.zoom < 2000){
						imposterZoom(Global.zoom*1.2, new Point(e.stageX, e.stageY));
						//setZoom(Global.zoom*1.2, new Point(e.stageX, e.stageY));
					}
				}
				else if(d > 0){
					imposterZoom(Global.zoom*0.8);
					//zoomOut(e); // zoom in on mouse but zoom out on center, this is also a method of navigation
				}
			}
		}
		
		public function finishZoom(e:TimerEvent):void{
			zooming = false;
			//stage.quality = StageQuality.HIGH;
			//scene.cacheAsBitmap = true;
			if(imposter != null && contains(imposter)){
				removeChild(imposter);
			}
			
			imposter = null;
			
			scene.visible = true;
			
			scene.x = Global.xorigin;
			scene.y = Global.yorigin;
			
			scene.redraw();
		}
		
		// redrawing during a zoom event may be laggy, the idea behind imposter zoom is to replace the scene
		// with a bitmap "imposter", and zoom that instead (much faster/more responsive)
		public function imposterZoom(zoom:Number, mouse:Point = null):void{
			
			if(zoom != Global.zoom){
				
				if(imposter == null){
					imposter = new Sprite();
					
					var region:Rectangle = new Rectangle();
					region = scene.getBounds(scene);
					
					//var factor:Number = Math.max(scene.width,scene.height)/Global.bitmapsize;
					
					//if(factor < 1){
					var factor:Number = 1;
					//}
					
					var trans:Matrix = new Matrix(factor,0,0,factor, -region.x*factor,-region.y*factor);
					
					if(scene.width > 0 && scene.height > 0){
						try{
							var b:BitmapData = new BitmapData(Math.ceil(scene.width/factor), Math.ceil(scene.height/factor), true, 0x000000);
							b.draw(scene, trans);
							
							var bitmap:Bitmap =  new Bitmap(b,"auto",false);
							bitmap.x = region.x;
							bitmap.y = region.y;
							
							imposter.addChild(bitmap);
						}catch(e:Error){
							// fallback to regular zoom when an error occurs
							// this usually happens when the bitmap is too big
							setZoom(zoom, mouse);
							return;
						}
					}
					
					scene.visible = false;
				}
				
				if(mouse == null){
					Global.xorigin = Global.docwidth/2 - (Global.docwidth/2 - Global.xorigin)*(zoom/Global.zoom);
					Global.yorigin = Global.docheight/2 - (Global.docheight/2 - Global.yorigin)*(zoom/Global.zoom);
				}
				else{
					Global.xorigin = mouse.x - (mouse.x - Global.xorigin)*(zoom/Global.zoom);
					Global.yorigin = mouse.y - (mouse.y - Global.yorigin)*(zoom/Global.zoom);
				}
				
				addChild(imposter);
				
				Global.zoom = zoom;
				grid.setOrigin();
				grid.redrawGrid();
				redrawBackground();
				
				imposter.x = Global.xorigin;
				imposter.y = Global.yorigin;
				
				imposter.width = scene.width * (Global.zoom/startzoom);
				imposter.height = scene.height * (Global.zoom/startzoom);
			}
			
			/*var m:Matrix = new Matrix();
			m.identity();
			m.scale(Global.zoom/80,Global.zoom/80);
			imposter.transform.matrix = m;*/
		}
		
		public function setZoom(zoom:Number, mouse:Point = null):void{
			addChild(tools); // tools should be on top when zooming
			
			if(zoom != Global.zoom){
				if(mouse == null){
					Global.xorigin = Global.docwidth/2 - (Global.docwidth/2 - Global.xorigin)*(zoom/Global.zoom);
					Global.yorigin = Global.docheight/2 - (Global.docheight/2 - Global.yorigin)*(zoom/Global.zoom);
				}
				else{
					Global.xorigin = mouse.x - (mouse.x - Global.xorigin)*(zoom/Global.zoom);
					Global.yorigin = mouse.y - (mouse.y - Global.yorigin)*(zoom/Global.zoom);
				}
				
				Global.zoom = zoom;
				grid.setOrigin();
				grid.redrawGrid();
				redrawBackground();
				
				scene.x = Global.xorigin;
				scene.y = Global.yorigin;
				
				scene.redraw();
			}
		}
		
		public function redrawBackground():void{
			if(background.alpha != 0){
				background.x = Global.xorigin;
				background.y = Global.yorigin;
				
				if(background.numChildren > 0){
					var loader:Loader = background.getChildAt(0) as Loader;
					var bit:Bitmap = loader.content as Bitmap;
					
					if(bit != null){
						background.width = (bit.bitmapData.width/backgroundscale)*Global.zoom;
						background.height = (bit.bitmapData.height/backgroundscale)*Global.zoom;
					}
				}
			}
		}
		
		public function unitChange(e:Event):void{
			var unitbox:ComboBox = e.target as ComboBox;
			
			var unit = unitbox.value;
			var i:int = 0;
			if(Global.unit != unit){
				if(unit == "in"){
					scene.cmToInch();
					Global.zoom = Global.zoom*2.54;
				}
				else if(unit == "cm"){
					scene.inchToCm();
					Global.zoom = Global.zoom/2.54;
				}
				grid.redrawGrid();
				scene.redraw();
				Global.unit = unit;
			}
		}
		
		public function snapChange(e:Event):void{
			Global.snap = e.target.selected;
		}
		
		public function viewcutsChange(e:Event):void{
			Global.viewcuts = e.target.selected;
			scene.redraw();
		}
		
		public function loadFile():void{
			var sloader:SVGLoader = new SVGLoader(this);
			sloader.load();
		}
		
		public function saveFile():void{
			
			// ensure there are paths to save
			if(scene.pathlist.length == 0){
				startDialog(140, 50, new Array({type:"label", label:"No paths to save"}), "error");
				return;
			}
			
			var writer:SVGWriter = new SVGWriter(scene.pathlist, scene.cutlist);
			var save:String = writer.parse();
			
			file = new FileReference();
			file.save(save, "partkamdesign.svg");
			file.addEventListener(Event.CANCEL, saveCancel);
			file.addEventListener(Event.SELECT, saveBegin);
			file.addEventListener(ProgressEvent.PROGRESS, saveProgress);
			file.addEventListener(Event.COMPLETE, saveComplete);
		}
		
		public function exportGcode(cutlist:Array):void{			
			
			var processor:PostProcessor = new PostProcessor(cutlist);
			var gcode:String = processor.process();
			
			if(gcode != null){
				file = new FileReference();
				file.save(gcode, "part.nc");
				file.addEventListener(Event.CANCEL, saveCancel);
				file.addEventListener(Event.COMPLETE, saveComplete);
			}
		}
		
		public function saveBegin(e:Event):void{
			progressdialog = startProgressDialog(250, 75, "Saving", "Cancel", this.saveProgressCancel);
			progressdialog.init(1);
		}
		
		public function saveCancel(e:Event):void{
			removeFile();
		}
		
		public function saveProgressCancel():void{
			if(file != null){
				file.cancel();
			}
			removeFile();
		}
		
		public function saveProgress(e:ProgressEvent):void{
			progressdialog.setProgress(e.bytesLoaded/e.bytesTotal);
		}
		
		public function saveComplete(e:Event):void{
			removeFile();
			if(progressdialog != null){
				progressdialog.stopDialog();
			}
		}
		
		public function removeFile():void{
			if(file != null){
				file.removeEventListener(Event.CANCEL, saveCancel);
				file.removeEventListener(Event.SELECT, saveBegin);
				file.removeEventListener(ProgressEvent.PROGRESS, saveProgress);
				file.removeEventListener(Event.COMPLETE, saveComplete);
			}
			
			file = null;
		}
		
		public function processFile(svg:Object):void{
			var parser:SVGToPath = new SVGToPath();
			var list:Array = parser.parse(svg);
			
			var miny:Number = 0;
			
			if(svg.height){
				var h:String = svg.height.toString();
				if(h != "100%"){
					miny = parser.getUnit(h);
				}
			}
			
			for each(var path:Path in list){
				path.invertY();
				/*var min:Point = path.getMin();
				if(min.y < miny){
					miny = min.y;
				}*/
			}
			
			for each(path in list){
				path.docy -= miny;
			}
			
			scene.setInactive();
			scene.addPaths(list);
		}
		
		// add cutobjects from the raw svg xml file
		public function loadCuts(svg:XML):void{
			var metadata:XML;
			
			for each(var child:XML in svg.*) {
				if(child.localName() == "metadata"){
					metadata = child;
				}
			}
			
			if(metadata == null){
				return;
			}
			
			for each(child in metadata.*){
				if(child.localName() == "cutobject"){
					loadCutObject(child);
				}
			}
			
			// remove path names after they have been used (they will interfere with future load operations)
			for each(var path:Path in scene.pathlist){
				path.name = '';
			}
			
			scene.redraw();
		}
		
		protected function loadCutObject(cutobject:XML):void{
			var children:Array = new Array();
			
			// parse children first
			
			for each(var child:XML in cutobject.*){
				if(child.localName() == "path"){
					var id:String = String(child.text());
					for each(var path:Path in scene.pathlist){
						if(path.name == id){
							children.push(path);
						}
					}
				}
			}
					
			if(children.length == 0){
				return;
			}
			
			var cut:CutObject;
			var type:String = cutobject.@type;
			
			if(type == "profile"){
				cut = new ProfileCutObject();
			}
			else if(type == "pocket"){
				cut = new PocketCutObject();
			}
			else if(type == "followpath"){
				cut = new FollowPathCutObject();
			}
			else if(type == "drill"){
				cut = new DrillCutObject();
			}
			
			var cutname:String = unescape(cutobject.@name);
			
			if(cutname == ""){
				cutname = "unnamed operation";
			}
			
			cut.name = cutname;
			cut.safetyheight = cutobject.@safetyheight;
			cut.stocksurface = cutobject.@stocksurface;
			cut.targetdepth = cutobject.@targetdepth;
			cut.stepover = cutobject.@stepover;
			cut.stepdown = cutobject.@stepdown;
			cut.feedrate = cutobject.@feedrate;
			cut.plungerate = cutobject.@plungerate;
			
			cut.outside = (cutobject.@outside == "true" ? true : false);
			
			cut.center = (cutobject.@center == "true" ? true : false);
			cut.spacing = cutobject.@spacing;
			
			cut.tooldiameter = cutobject.@tooldiameter;
			cut.roughingclearance = cutobject.@roughingclearance;
			
			if(Global.unit == "in" && cutobject.@unit == "metric"){
				// mm to inch
				cut.safetyheight /= 25.4;
				cut.stocksurface /= 25.4;
				cut.targetdepth /= 25.4;
				cut.stepdown /= 25.4;
				cut.feedrate /= 25.4;
				cut.plungerate /= 25.4;
				
				// cm to inch
				cut.tooldiameter /= 2.54;
				cut.roughingclearance /= 2.54;
				
				cut.spacing /= 2.54;
			}
			else if(Global.unit == "cm" && cutobject.@unit == "imperial"){
				// inch to mm
				cut.safetyheight *= 25.4;
				cut.stocksurface *= 25.4;
				cut.targetdepth *= 25.4;
				cut.stepdown *= 25.4;
				cut.feedrate *= 25.4;
				cut.plungerate *= 25.4;
				
				// inch to cm
				cut.tooldiameter *= 2.54;
				cut.roughingclearance *= 2.54;
				
				cut.spacing *= 2.54;
			}
			
			for each(path in children){
				path.zeroOrigin();
			}
			
			cut.pathlist = children;
			
			scene.addCut(cut);
		}
		
		// modal dialog stuff
		
		public function addScreen():void{
			Mouse.cursor = MouseCursor.AUTO;
			
			// first add screen and blur the background
			
			var s:Shape = new Shape();
			
			s.graphics.beginFill(0x000000);
			s.graphics.drawRect(0,0,Global.docwidth,Global.docheight);
			s.graphics.endFill();
			s.alpha = 0.1;
			
			var screen:Sprite = new Sprite();
			
			screen.addChild(s);
			screen.name = "screen";
			addChild(screen);
			
			// now blur everything

			/*var blur:BlurFilter = new BlurFilter(3, 3, 3);
			//this.filters = [colorMat, blur];
			for(var i:int=0; i<numChildren; i++){
				if(getChildAt(i) is Sprite){
					getChildAt(i).filters = [blur];
				}
			}*/
		}
		
		public function startDialog(dw:int, dh:int, fieldlist:Array, dialogname:String, submitlabel:String = "OK", closewindow:Boolean = true):Dialog{
			
			addScreen();
			
			var d:Dialog = new Dialog(dw, dh, fieldlist, submitlabel, closewindow);
			
			d.name = dialogname;
			
			d.x = Global.docwidth/2 - d.width/2;
			d.y = Global.docheight/2 - d.height/2;
			
			temptool = Global.tool;
			Global.tool = 99; // no tool may be used during modal dialog display
			addChild(d);
			
			return d;
		}
		
		public function startProgressDialog(dw:int, dh:int, dmessage:String = "processing", dlabel:String = "Cancel", callback:Function = null):ProgressDialog{
			
			addScreen();
			
			var d:ProgressDialog = new ProgressDialog(dw, dh, dmessage, dlabel, callback);
			
			d.x = Global.docwidth/2 - dw/2;
			d.y = Global.docheight/2 - dh/2;
			
			temptool = Global.tool;
			Global.tool = 99; // no tool may be used during modal dialog display
			addChild(d);
			
			return d;
		}
		
		public function endDialog():void{
			// remove screen, blur, and restore everthing to original settings
			for(var i:int=0; i<numChildren; i++){
				if(getChildAt(i) is Sprite){
					getChildAt(i).filters = [];
					if(getChildAt(i).name == "screen"){
						removeChildAt(i);
					}
				}
			}
			
			setCursor();
			
			Global.tool = temptool;
		}
		
		public function processDialog(flist:Array, dname:String):void{
			// do something with dialog output
			
			stage.focus = this;
			
			var i:int = 0;
			switch(dname){
				case "scale":
					var sx:Number = Number(flist[0].input.text);
					var sy:Number = Number(flist[1].input.text);
					
					var avx:Number = 0;
					var avy:Number = 0;
					
					var m:Matrix = new Matrix(sx/100,0,0,sy/100,avx,avy);
					
					if(sx != 0 && sy != 0){
						scene.applyMatrixLocal(m);
					}
				break;
				case "rotate":
					var ang:Number = Number(flist[0].input.text);
					var r:Matrix = new Matrix();
					r.rotate(ang*Math.PI/180);
					if(ang != 0 && ang != 360){
						scene.applyMatrixLocal(r);
					}
				break;
				case "skew":
					var skx:Number = Number(flist[0].input.text);
					var sky:Number = Number(flist[1].input.text);
					
					var s:Matrix = new Matrix();
					s.c = Math.tan((-1*skx/100));
					s.b = Math.tan((-1*sky/100));
					
					scene.applyMatrixLocal(s);
				break;
				case "background":
					if(flist[0].input != null && flist[0].input is Loader){
						while(background.numChildren > 0){
							background.removeChildAt(0);
						}
						background.addChild(flist[0].input);
					}
					
					var scale:Number = Number(flist[1].input.text);
					
					if(!isNaN(scale) && scale != 0){
						if(scale < 0){
							scale = Math.abs(scale);
						}
						
						backgroundscale = scale;
						
						redrawBackground();
					}
					
					var al:Number = Number(flist[2].input.text);
					
					if(!isNaN(al)){
						if(al>100){
							al = 100;
						}
						else if(al < 0){
							al = Math.abs(al);
						}
						background.alpha = al/100;
						backgroundvisibility = al;
					}
				break;
				case "preferences":
					var res:Number = Number(flist[0].input.text);
					if(!isNaN(res) && res != 0){
						if(res < 0){
							res = -res;
						}
						Global.importres = res;
					}
					
					var snap:Boolean = flist[4].input.selected;
					Global.localsnap = snap;
					
					var tolerance:Number = Number(flist[6].input.text);
					
					if(!isNaN(tolerance) && tolerance != 0){
						if(tolerance < 0){
							tolerance = -tolerance;
						}
						Global.tolerance = tolerance;
					}
					
					var bitmaptolerance:Number = Number(flist[7].input.text)
					
					if(!isNaN(bitmaptolerance) && bitmaptolerance != 0){
						if(bitmaptolerance < 0){
							bitmaptolerance = -bitmaptolerance;
						}
						Global.bitmaptolerance = bitmaptolerance;
					}
					
					var nestbitmapsize:Number = Number(flist[8].input.text)
					
					if(!isNaN(nestbitmapsize)){
						if(nestbitmapsize < 400){
							nestbitmapsize = 400;
						}
						if(nestbitmapsize > 4000){
							nestbitmapsize = 4000;
						}
						Global.nestbitmapsize = Math.floor(nestbitmapsize);
					}
					
					Global.separatetoolpaths = flist[9].input.selected;
					
				break;
				case "addcircle":
					var dia:Number = Number(flist[0].input.text);
					if(!isNaN(dia) && dia != 0){
						if(dia < 0){
							dia = Math.abs(dia);
						}
						
						addEllipse(dia,dia);
					}
				break;
				case "addellipse":
					var ew:Number = Number(flist[0].input.text);
					var eh:Number = Number(flist[1].input.text);
					if(!isNaN(ew) && ew != 0 && !isNaN(eh) && eh != 0){
						if(ew < 0){
							ew = Math.abs(ew);
						}
						if(eh < 0){
							eh = Math.abs(eh);
						}
						
						addEllipse(ew,eh);
					}
				break;
				case "addrectangle":
					var rw:Number = Number(flist[0].input.text);
					var rh:Number = Number(flist[1].input.text);
					if(!isNaN(rw) && rw != 0 && !isNaN(rh) && rh != 0){
						if(rw < 0){
							rw = Math.abs(rw);
						}
						if(rh < 0){
							rh = Math.abs(rh);
						}
						
						addRect(rw,rh,0, false);
					}
				break;
				case "addroundedrectangle":
					var rw1:Number = Number(flist[0].input.text);
					var rh1:Number = Number(flist[1].input.text);
					var rad:Number = Number(flist[2].input.text);
					if(!isNaN(rw1) && rw1 != 0 && !isNaN(rh1) && rh1 != 0){
						if(rw1 < 0){
							rw1 = Math.abs(rw1);
						}
						if(rh < 0){
							rh1 = Math.abs(rh1);
						}
						if(rad < 0){
							rad = Math.abs(rad);
						}
						
						addRect(rw1,rh1,rad, true);
					}
				break;
				case "addpolygon":
					var sides:int = Math.floor(Number(flist[0].input.text));
					var rad1:Number = Number(flist[1].input.text);
					if(!isNaN(sides) && sides !=0 && !isNaN(rad1) && rad1!=0){
						if(sides<0){
							sides = Math.abs(sides);
						}
						if(rad1 < 0){
							rad1 = Math.abs(rad1);
						}
						if(sides >= 3){
							addPolygon(sides, rad1);
						}
					}
				break;
				case "addstar":
					var points:int = Math.floor(Number(flist[0].input.text));
					var rad2:Number = Number(flist[1].input.text);
					var pointiness:Number = Number(flist[2].input.text);
					if(!isNaN(points) && points !=0 && !isNaN(rad2) && rad2!=0 && !isNaN(pointiness)){
						if(points<0){
							points = Math.abs(points);
						}
						if(rad2 < 0){
							rad2 = Math.abs(rad1);
						}
						if(pointiness < 0){
							pointiness = Math.abs(pointiness);
						}
						if(pointiness > 99){
							pointiness = 99;
						}
						if(points >= 3){
							addStar(points, rad2, pointiness);
						}
					}
				break;
				case "profile":
					scene.zeroSelected();
					scene.profile(flist);
					scene.pathsOnTop();
				break;
				case "editprofile":
					scene.zeroSelected();
					scene.editprofile(flist);
					scene.pathsOnTop();
				break;
				case "pocket":
					scene.zeroSelected();
					scene.pocket(flist);
					scene.pathsOnTop();
				break;
				case "editpocket":
					scene.zeroSelected();
					scene.editpocket(flist);
					scene.pathsOnTop();
				break;
				case "followpath":
					scene.zeroSelected();
					scene.followpath(flist);
					scene.pathsOnTop();
				break;
				case "editfollowpath":
					scene.zeroSelected();
					scene.editfollowpath(flist);
					scene.pathsOnTop();
				break;
				case "drill":
					scene.zeroSelected();
					scene.drill(flist);
					scene.pathsOnTop();
				break;
				case "editdrill":
					scene.zeroSelected();
					scene.editdrill(flist);
					scene.pathsOnTop();
				break;
				case "startnest":
					var pd:ProgressDialog = startProgressDialog(250, 75, "Optimizing Nesting Solution", "Stop", scene.finishNest);
					
					var divs:int = Number(flist[0].input.text);
					var gap:Number = Number(flist[1].input.text);
					var group:Boolean = flist[2].input.selected;
					var groupprofile:Boolean = flist[3].input.selected;
					
					if(!scene.startNest(pd, divs, gap, group, groupprofile)){
						pd.stopDialog();
						scene.redraw();
						startDialog(270, 50, new Array({type:"label", label:"At least 2 objects are required for nesting"}), "error");
					}
				break;
				case "tabs":
					var tabspacing:Number = Number(flist[0].input.text);
					var tabwidth:Number = Number(flist[1].input.text);
					var tabheight:Number = Number(flist[2].input.text);
					
					if(isNaN(tabspacing) || tabspacing <= 0 || isNaN(tabwidth) || tabwidth <= 0 || isNaN(tabheight) || tabheight <= 0 || tabspacing <= tabwidth){
						startDialog(100, 50, new Array({type:"label", label:"Invalid input"}), "error");
						return;
					}
					scene.addTabsSelected(tabspacing, tabwidth, tabheight);
				break;
				case "exportgcode":
					var cutlist:Array = new Array();
					var listitems:Array = flist[0].input.selectedItems;
					for(i=0; i<listitems.length; i++){
						var obj:Object = listitems[i];
						cutlist.push(obj.data);
					}
					if(cutlist.length > 0){
						exportGcode(cutlist);
					}
				break;
			}
		}
		
		public function addEllipse(ew:Number, eh:Number):void{
			var middle:Point = new Point(((Global.docwidth/2)-Global.xorigin)/Global.zoom, (-(Global.docheight/2)+Global.yorigin)/Global.zoom);
			
			var cx:Number = middle.x;
			var cy:Number = middle.y;
			var rx:Number = ew/2;
			var ry:Number = eh/2;
			
			var ob:Object = {cx:cx+Global.unit, cy:cy+Global.unit, rx:rx+Global.unit, ry:ry+Global.unit};
			
			var svgtemp:SVGToPath = new SVGToPath();
			
			var p:Path = svgtemp.parseEllipse(ob);
			
			if(p != null){
				scene.addPath(p);
				scene.redraw();
			}
			
			svgtemp = null;
		}
		
		public function addRect(rw:Number, rh:Number, radius:Number, round:Boolean):void{
			var middle:Point = new Point(((Global.docwidth/2)-Global.xorigin)/Global.zoom, (-(Global.docheight/2)+Global.yorigin)/Global.zoom);
			
			var ob:Object = {isRound: round, rx: radius + Global.unit, ry: radius + Global.unit, x: middle.x-rw/2 + Global.unit, y:middle.y-rh/2 + Global.unit, width:rw + Global.unit, height:rh + Global.unit};
			
			var svgtemp:SVGToPath = new SVGToPath();
			
			var p:Path = svgtemp.parseRect(ob);
			
			if(p != null){
				scene.addPath(p);
				scene.redraw();
			}
			
			svgtemp = null;
		}
		
		public function addPolygon(sides:int, radius:Number):void{
			if(sides<3){
				sides = 3;
			}
			
			var p:Path = new Path();
			
			//var radius:Number = Global.docheight/(Global.zoom*3);
			
			var cpoint:Point; // current point
			var lpoint:Point = new Point(0, radius); // point belonging to the previous segment
			var origin:Point = lpoint;
			for(var i:int=360/sides; i<360; i += 360/sides){
				cpoint = new Point(radius*Math.sin(i*Math.PI/180), radius*Math.cos(i*Math.PI/180));
				var seg:Segment = new Segment(lpoint, cpoint);
				lpoint = cpoint;
				p.addSegment(seg);
			}
			
			// close polygon
			seg = new Segment(cpoint, origin);
			p.addSegment(seg);
			
			var middle:Point = new Point(((Global.docwidth/2)-Global.xorigin)/Global.zoom, (-(Global.docheight/2)+Global.yorigin)/Global.zoom);
			p.docx = middle.x;
			p.docy = -middle.y;
			
			scene.addPath(p);
			scene.redraw();
		}
		
		public function addStar(points:int, radius:Number, pointiness:Number):void{
			if(points<3){
				points = 3;
			}
			
			var p:Path = new Path;
			
			var cpoint:Point; // current point
			var lpoint:Point = new Point(0, radius); // point belonging to the previous segment
			var origin:Point = lpoint;
			for(var i:int=360/points; i<360; i += 360/points){
				cpoint = new Point(radius*Math.sin(i*Math.PI/180), radius*Math.cos(i*Math.PI/180));
				var ipoint:Point = new Point(radius*((100-pointiness)/100)*Math.sin((i-180/points)*Math.PI/180), radius*((100-pointiness)/100)*Math.cos((i-180/points)*Math.PI/180));
				
				var seg:Segment = new Segment(lpoint, ipoint);
				p.addSegment(seg);
				
				seg = new Segment(ipoint, cpoint);
				p.addSegment(seg);
				
				lpoint = cpoint;
			}
			
			// close star
			ipoint = new Point(radius*((100-pointiness)/100)*Math.sin((i-180/points)*Math.PI/180), radius*((100-pointiness)/100)*Math.cos((i-180/points)*Math.PI/180));
			seg = new Segment(cpoint, ipoint);
			p.addSegment(seg);
			
			seg = new Segment(ipoint, origin);
			p.addSegment(seg);
			
			var middle:Point = new Point(((Global.docwidth/2)-Global.xorigin)/Global.zoom, (-(Global.docheight/2)+Global.yorigin)/Global.zoom);
			p.docx = middle.x;
			p.docy = -middle.y;
			
			scene.addPath(p);
			scene.redraw();
		}
		
		// sketch tools
		
		public function startSketch(e:MouseEvent):void{
			if(e.target is Dot){
				sketchdot = e.target as Dot;
			}
			
			Global.dragging = true;
			
			sketch = new Sketch(new Point(e.stageX,e.stageY));
			
			addChild(sketch);
			addEventListener(MouseEvent.MOUSE_MOVE, moveSketch);
			addEventListener(MouseEvent.MOUSE_UP, upSketch);
			stage.addEventListener(Event.MOUSE_LEAVE, upSketch);
			
			timer = new Timer(0,0);
			timer.addEventListener(TimerEvent.TIMER, timeIncrement);
			timer.start();
		}
		
		public function moveSketch(e:MouseEvent):void{
			var p:Point = new Point(e.stageX, e.stageY);
			sketch.lineTo(p);
			sketch.addPoint(p);
			sketch.addTime(now);
		}
		
		public function upSketch(e:Event):void{
			removeEventListener(MouseEvent.MOUSE_MOVE, moveSketch);
			removeEventListener(MouseEvent.MOUSE_UP, upSketch);
			stage.removeEventListener(Event.MOUSE_LEAVE, upSketch);
			
			timer.removeEventListener(TimerEvent.TIMER, timeIncrement);
			now = 0;
			
			var path:Path = sketch.getPath();
			
			if(path != null){
				path.docx = -Global.xorigin/Global.zoom;
				path.docy = -Global.yorigin/Global.zoom;
				
				path.x = -Global.xorigin;
				path.y = -Global.yorigin;
				
				if(sketchdot != null){
					sketchdot.looppath.mergePath(path, sketchdot.point);
					sketchdot.looppath.setInactive();
					
					sketchdot = null;
				}
				else{
					// if it is not a continuation, check if the path should be closed
					if(path.seglist.length > 2){
						var seglist:Array = path.seglist;
						var intersect:Point = Global.lineIntersect(seglist[0].p1, seglist[0].p2, seglist[seglist.length-1].p1, seglist[seglist.length-1].p2, true);
						if(intersect != null && !isNaN(intersect.x) && !isNaN(intersect.y)){
							seglist[0].p1 = intersect;
							seglist[seglist.length-1].p2 = intersect;
						}
					}
					
					/*path.docx = -Global.xorigin/Global.zoom;
					path.docy = -Global.yorigin/Global.zoom;*/
					path.redrawDots();
					scene.addPath(path);
				}
			}
			
			Global.dragging = false;
			removeChild(sketch);
			
		}
		
		public function timeIncrement(e:TimerEvent):void{
			now++;
		}
	}
}