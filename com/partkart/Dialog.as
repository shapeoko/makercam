package com.partkart{

	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.text.*;
	import flash.filters.DropShadowFilter;
	import fl.controls.Button;
	import flash.net.FileReference;
	import flash.net.FileFilter;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import fl.controls.List;

	// this sets up a modal dialog from a list of text input objects
	public class Dialog extends Sprite{

		private var flist:Array; // array of field objects that will serve as our data provider

		private var dwidth:int; // width of the dialog
		private var dheight:int; // height of the dialog

		private var back:Shape; // background box
		private var clsprite:Sprite; // close button

		private var file:FileReference;

		// the label for the "ok" button
		private var submitlabel:String;

		// if true, close the window after performing desired action
		private var closewindow:Boolean;

		public function Dialog(dialogwidth:int, dialogheight:int, fieldlist:Array, inputlabel:String = "OK", inputclose:Boolean = true):void{
			dwidth = dialogwidth;
			dheight = dialogheight;
			flist = fieldlist;
			submitlabel = inputlabel;
			closewindow = inputclose;

			init();
			populateFields();
		}

		private function init():void{

			back = new Shape();

			var m:Matrix = new Matrix(dwidth/1000, 0, 0, dheight/1000,dwidth/2, dheight/2);
			back.graphics.beginGradientFill(GradientType.RADIAL, [0x444444, 0x222222],[1,1],[50,255], m);
			back.graphics.drawRoundRect(0,0,dwidth,dheight,20,20);
			back.graphics.endFill();

			addChild(back);

			addEventListener(MouseEvent.MOUSE_DOWN, dialogDown);
			addEventListener(MouseEvent.MOUSE_UP, dialogUp);

			// add close button

			clsprite = new Sprite();

			var cl = new Shape();
			cl.graphics.beginFill(0xff0000);
			cl.graphics.drawCircle(0,0,8);
			cl.graphics.endFill();

			cl.graphics.lineStyle(2, 0xffffff, 1, false, LineScaleMode.NONE, CapsStyle.ROUND);

			cl.graphics.moveTo(-3,-3);
			cl.graphics.lineTo(3,3);

			cl.graphics.moveTo(3,-3);
			cl.graphics.lineTo(-3,3);

			clsprite.addChild(cl);

			clsprite.x = dwidth - 13;
			clsprite.y = 13;

			addChild(clsprite);

			clsprite.alpha = 0.7;

			clsprite.addEventListener(MouseEvent.CLICK, closeDialog);

			clsprite.addEventListener(MouseEvent.MOUSE_OVER, closeOver);
			clsprite.addEventListener(MouseEvent.MOUSE_OUT, closeOut);
		}

		private function populateFields():void{

			var vposition:int = 30;
			var hposition:int = 20;

			var format:TextFormat = new TextFormat("Arial", 11);

			var shadowfilter:DropShadowFilter = new DropShadowFilter(2,45,0,0.65,3,3);

			var input:TextField;

			for(var i:int=0; i<flist.length; i++){
				var f:Object = flist[i];

				switch(f.type){
					case "label":
						addLabel(f, hposition, vposition);
					break;
					case "number":
						addLabel(f, hposition, vposition);
						input = new TextField();

						input.restrict = "0-9.\\-";

						input.defaultTextFormat = format;
						input.type = TextFieldType.INPUT;
						input.multiline = false;
						input.height = 20;
						input.width = dwidth - (hposition*2);
						input.background = true;
						input.x = dwidth;
						input.y = vposition;
						input.filters = [shadowfilter];

						if(f.value){
							input.text = f.value;
						}

						if(f.highlight){
							input.backgroundColor = 0xfffbae;
						}

						f.input = input;
						addChild(input);
					break;
					case "string":
						addLabel(f, hposition, vposition);
						input = new TextField();

						input.defaultTextFormat = format;
						input.type = TextFieldType.INPUT;
						input.multiline = false;
						input.height = 20;
						input.width = dwidth - (hposition*2);
						input.background = true;
						input.x = dwidth;
						input.y = vposition;
						input.filters = [shadowfilter];

						if(f.value){
							input.text = f.value;
						}

						f.input = input;
						addChild(input);
					break;
					case "combobox":
						if(f.label){
							addLabel(f, hposition, vposition);
						}
						var combobox:ComboBox = new ComboBox();

						if(f.items){
							for each(var item:Object in f.items){
								combobox.addItem(item);
								if(f.value != null && f.value == item.data){
									combobox.selectedItem = item;
								}
							}
						}

						combobox.height = 20;
						combobox.width = dwidth - (hposition*2);
						if(f.label){
							combobox.x = dwidth;
						}
						else{
							combobox.x = hposition;
						}
						combobox.y = vposition;
						combobox.filters = [shadowfilter];

						f.input = combobox;
						addChild(combobox);
					break;
					case "file":
						addLabel(f, hposition, vposition);
						var browse:Button = new Button();
						browse.label = "Browse";
						browse.width = 80;
						browse.x = dwidth;
						browse.y = vposition;
						addChild(browse);

						browse.addEventListener(MouseEvent.CLICK, browseAction);
					break;
					case "checkbox":
						var checkbox:CheckBox = new CheckBox();
						var fo:TextFormat = new TextFormat("Arial", 11);
						fo.color = 0xffffff;
						checkbox.setStyle("textFormat",fo);
						checkbox.selected = f.value;
						checkbox.x = hposition;
						checkbox.y = vposition;
						checkbox.width = dwidth;
						checkbox.label = f.label;

						f.input = checkbox;
						addChild(checkbox);
					break;
					case "listbox":
						addLabel(f, hposition, vposition);
						var listbox:List = new List();
						listbox.allowMultipleSelection = true;
						listbox.width = dwidth - (hposition*2);
						listbox.height = 200;
						listbox.x = hposition;
						listbox.y = vposition+20;

						if(f.value && f.value.length > 0){
							for each(var obj:Object in f.value){
								listbox.addItem(obj);
							}
						}

						vposition += 200;

						f.input = listbox;
						addChild(listbox);
					break;
					case "cutlist": // special element used only for exporting g-code
						addLabel(f, hposition, vposition);
						var cutlist:List = new List();
						cutlist.name = "cutlist";
						cutlist.allowMultipleSelection = true;
						cutlist.width = dwidth;
						cutlist.height = 200;
						cutlist.x = hposition;
						cutlist.y = vposition+20;

						if(f.value && f.value.length > 0){
							for each(obj in f.value){
								cutlist.addItem(obj);
							}
							var selectedcuts:Array = new Array();
							for each(obj in f.value){
								if(obj.active){
									selectedcuts.push(obj);
								}
							}
							cutlist.selectedItems = selectedcuts;
						}

						vposition += 210;

						// manipulator buttons
						var up:Button = new Button();
						up.label = "+";
						up.width = 20;
						up.x = hposition;
						up.y = vposition+20;
						addChild(up);

						// move selected upward
						var uphandler:Function = function(e:MouseEvent):void{
							for(var i:int=0; i<cutlist.length; i++){
								var obj:Object = cutlist.getItemAt(i);
								if(i > 0 && cutlist.isItemSelected(obj)){
									cutlist.removeItemAt(i);
									cutlist.addItemAt(obj,i-1);
									cutlist.selectedIndex = i-1;
									break;
								}
							}
						}

						up.addEventListener(MouseEvent.CLICK, uphandler);

						var down:Button = new Button();
						down.label = "-";
						down.width = 20;
						down.x = hposition+25;
						down.y = vposition+20;
						addChild(down);

						// move selected downward
						var downhandler:Function = function(e:MouseEvent):void{
							for(var i:int=0; i<cutlist.length; i++){
								var obj:Object = cutlist.getItemAt(i);
								if(i < cutlist.length-1 && cutlist.isItemSelected(obj)){
									cutlist.removeItemAt(i);
									cutlist.addItemAt(obj,i+1);
									cutlist.selectedIndex = i+1;
									break;
								}
							}
						}

						down.addEventListener(MouseEvent.CLICK, downhandler);

						var sort:Button = new Button();
						sort.label = "sort by tool";
						sort.width = 80;
						sort.x = hposition+50;
						sort.y = vposition+20;
						addChild(sort);

						// sort by tool size
						var desc:Boolean = true;
						var sorthandler:Function = function(e:MouseEvent):void{
							if(desc){
								cutlist.sortItemsOn("diameter", Array.NUMERIC | Array.DESCENDING);
							}
							else{
								cutlist.sortItemsOn("diameter", Array.NUMERIC);
							}
							desc = !desc;
						}

						sort.addEventListener(MouseEvent.CLICK, sorthandler);

						var profile:Button = new Button();
						profile.label = "profiles last";
						profile.width = 80;
						profile.x = hposition+135;
						profile.y = vposition+20;
						addChild(profile);

						// put profile operations at the bottom
						var profilehandler:Function = function(e:MouseEvent):void{
							var num:int = cutlist.length;

							for(var i:int=0; i<num; i++){
								var obj:Object = cutlist.getItemAt(i);
								if(obj.data is ProfileCutObject){
									cutlist.removeItemAt(i);
									cutlist.addItem(obj);
									i--;
									num--;
								}
							}
						}

						profile.addEventListener(MouseEvent.CLICK, profilehandler);

						var all:Button = new Button();
						all.label = "all";
						all.width = 30;
						all.x = hposition+220;
						all.y = vposition+20;
						addChild(all);

						// select all items
						var allhandler:Function = function(e:MouseEvent):void{
							var selected:Array = new Array();
							for(var i:int=0; i<cutlist.length; i++){
								selected.push(cutlist.getItemAt(i));
							}
							cutlist.selectedItems = selected;
						}

						all.addEventListener(MouseEvent.CLICK, allhandler);

						f.input = cutlist;
						addChild(cutlist);
						vposition += 20;
					break;
				}

				if(f.type != "label" && f.type != "checkbox"){
					vposition += 30;
				}
				else{
					vposition += 20;
				}
			}

			vposition += 10;

			if(this.width > back.width){
				back.width = this.width+20;
			}
			if(this.height > back.height){
				back.height = this.height-20;
			}

			clsprite.x = back.width - 20;

			var buttonwidth:Number = Math.max(50,submitlabel.length*7);

			var submit:Button = new Button();
			submit.label = submitlabel;
			submit.width = buttonwidth;
			submit.x = this.width/2 - buttonwidth/2;
			submit.y = vposition;
			addChild(submit);

			submit.addEventListener(MouseEvent.CLICK, processDialog);

			vposition += 30;
		}

		private function addLabel(f:Object, hposition:int, vposition:int):void{
			var format:TextFormat = new TextFormat("Arial", 11);
			var t:TextField = new TextField();

			t.defaultTextFormat = format;
			t.text = f.label;
			t.type = TextFieldType.DYNAMIC;
			t.multiline = false;
			t.selectable = false;
			t.x = hposition;
			t.y = vposition;
			t.textColor = 0xffffff;

			t.width = dwidth;

			addChild(t);
		}

		private function closeOver(e:MouseEvent):void{
			e.target.alpha = 1;
		}

		private function closeOut(e:MouseEvent):void{
			e.target.alpha = 0.7;
		}

		private function dialogDown(e:MouseEvent):void{
			if(e.target == this || (e.target is TextField && e.target.selectable == false)){
				startDrag();
			}
		}

		private function dialogUp(e:MouseEvent):void{
			stopDrag();
		}

		private function closeDialog(e:MouseEvent):void{
			if(this.parent){
				var main:* = this.parent;
				main.endDialog();
				main.setCursor();
				this.parent.removeChild(this);
			}
		}

		private function processDialog(e:MouseEvent):void{
			if(this.parent){
				var main:* = this.parent;
				if(closewindow){
					closeDialog(e);
				}
				main.processDialog(flist, this.name);
				return;
			}
			if(closewindow){
				closeDialog(e);
			}
		}

		private function browseAction(e:MouseEvent):void{
			file = new FileReference();

			file.addEventListener(Event.SELECT, fileSelect);
			file.addEventListener(Event.CANCEL, fileCancel);

			file.browse(new Array( new FileFilter( "Images (*.jpg, *.jpeg, *.gif, *.png)", "*.jpg;*.jpeg;*.gif;*.png" )));
		}

		private function fileSelect(e:Event):void{
			file.addEventListener(Event.COMPLETE, fileProcess);
			file.addEventListener(IOErrorEvent.IO_ERROR, fileError);

			file.load();
		}

		private function fileCancel(e:Event):void{
			file = null;
		}

		private function fileProcess(e:Event):void{
			var imgloader:Loader = new Loader();
			imgloader.loadBytes(e.target.data);
			flist[0].input = imgloader;

			file = null;
		}

		private function fileError(e:IOErrorEvent):void{
			file = null;
		}

	}
}