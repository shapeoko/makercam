package com.partkart{
	
	import fl.controls.ProgressBar;
	import fl.controls.ProgressBarMode;
	import fl.controls.ProgressBarDirection;
	import fl.controls.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Matrix;
	import flash.text.*;
	import flash.filters.DropShadowFilter;
	import fl.controls.Button;
	
	public class ProgressDialog extends Sprite{
		
		private var dwidth:int; // width of the dialog
		private var dheight:int; // height of the dialog
		
		private var stoplabel:String;
		
		private var back:Shape; // background box
		
		private var progressbar:pBar;
		
		private var oncancel:Function = null; // callback function for when the user cancels
		
		public var total:Number = 1; // number of operations to process
		
		var titlelabel:TextField;
		
		public function ProgressDialog(dialogwidth:int, dialogheight:int, dialogmessage:String = "processing", dialoglabel:String = "Cancel", callback:Function = null):void{
			dwidth = dialogwidth;
			dheight = dialogheight;
			name = dialogmessage;
			stoplabel = dialoglabel;
			oncancel = callback;
		}
		
		public function init(progresstotal:Number):void{
			total = progresstotal;
			
			back = new Shape();
			
			var m:Matrix = new Matrix(dwidth/1000, 0, 0, dheight/1000,dwidth/2, dheight/2);
			back.graphics.beginGradientFill(GradientType.RADIAL, [0x444444, 0x222222],[1,1],[50,255], m);
			back.graphics.drawRoundRect(0,0,dwidth,dheight,20,20);
			back.graphics.endFill();
			
			addChild(back);
			
			addEventListener(MouseEvent.MOUSE_DOWN, dialogDown);
			addEventListener(MouseEvent.MOUSE_UP, dialogUp);
			
			// draw title
			var shadowfilter:DropShadowFilter = new DropShadowFilter(2,45,0,0.65,3,3);
			
			var format:TextFormat = new TextFormat("Arial", 11);
			
			titlelabel = new TextField();
						
			titlelabel.defaultTextFormat = format;
			titlelabel.type = TextFieldType.DYNAMIC;
			titlelabel.multiline = false;
			titlelabel.height = 20;
			titlelabel.width = this.width - 10;
			titlelabel.x = 8;
			titlelabel.y = 10;
			titlelabel.filters = [shadowfilter];
			titlelabel.textColor = 0xffffff;
			titlelabel.text = name + " (0%)";
			
			addChild(titlelabel);
			
			// draw progress bar
			progressbar = new pBar();
			progressbar.width = dwidth-20;
			
			progressbar.x = 10;
			progressbar.y = 30;
			
			addChild(progressbar);
			
			// draw stop button
			var stop:Button = new Button();
			stop.label = stoplabel;
			stop.width = 50;
			stop.x = dwidth/2 - 25;
			stop.y = 40;
			addChild(stop);
			
			stop.addEventListener(MouseEvent.CLICK, endDialog);
		}
		
		private function dialogDown(e:MouseEvent):void{
			if(e.target == this || (e.target is TextField && e.target.selectable == false)){
				startDrag();
			}
		}
		
		private function dialogUp(e:MouseEvent):void{
			stopDrag();
		}
		
		private function endDialog(e:MouseEvent):void{
			stopDialog();
			
			if(oncancel !== null){
				oncancel();
			}
		}
		
		public function stopDialog():void{
			if(this.parent){
				var main:* = this.parent;
				main.endDialog();
				main.setCursor();
				this.parent.removeChild(this);
			}
		}
		
		public function setProgress(p:Number):void{
			progressbar.width = (dwidth-20)*(p/total);
			titlelabel.text = name + " ("+Math.round(100*(p/total))+"%)";
		}
	}
}