package com.partkart{

	import flash.geom.Point;

	import com.lorentz.SVG.*;

	public class PathParser{

		private var subPaths:Array;
		private var seglist:Array = new Array();

		protected const WIDTH:String = "width";
		protected const HEIGHT:String = "height";

		private var cpoint:Point = new Point(0,0); // current point
		private var opoint:Point = cpoint; // origin point
		private var lastC:Point;//Last control point

		private var parent:SVGToPath;

		public function PathParser(svgtopath:SVGToPath):void{
			parent = svgtopath;
		}

		public function parse(commands:Array):Path{
			subPaths = extractSubPaths(commands);

			for(var i:int = 0;i<subPaths.length; i++){
				parseSubPath(subPaths[i]);
			}

			if(seglist.length>0){
				var p:Path = new Path();
				for(i=0; i<seglist.length; i++){
					p.addSegment(seglist[i]);
				}
				return p;
			}
			else{
				return null;
			}
		}

		private function extractSubPaths(commands:Array):Array{
			var _subPaths:Array = new Array();

			var path:Array;
			for each(var command:PathCommand in commands){
					if((command.type=="M") || (command.type=="m")){
							if(path!=null && path.length>0){
									_subPaths.push(path);
							}
							path = new Array();
							path.push(command);

							var cargs:Array = command.args;

							if(cargs.length > 2){
								var reltype:String = command.type == "M" ? "L" : 'l';
								// assume extra bits attached to move command are line commands
								for(var i:int=2; i<cargs.length; i+=2){
									path.push(new PathCommand(reltype,new Array(cargs[i],cargs[i+1])));
								}
								command.args = new Array(cargs[0],cargs[1]);
							}
							continue;
					}
					path.push(command);
			}
			if(path!=null)
					_subPaths.push(path);

			return _subPaths;
		}

		private function parseSubPath(subPath:Array):void{
			for (var c:int = 0; c < subPath.length; c++) {
				var command:PathCommand = subPath[c];

				if(command.type == "Z" || command.type == "z"){
						closePath();
						continue;
				}

				var args:Array = command.args;

				var a:int = 0;
				while_args : while (a<args.length){
						switch (command.type) {
								case "M" : moveToAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "m" : moveToRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "L" : lineToAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "l" : lineToRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "H" : lineToHorizontalAbs(getUnit(args[a++], WIDTH));break;
								case "h" : lineToHorizontalRel(getUnit(args[a++], WIDTH)); break;
								case "V" : lineToVerticalAbs(getUnit(args[a++], HEIGHT)); break;
								case "v" : lineToVerticalRel(getUnit(args[a++], HEIGHT)); break;
								case "Q" : curveToQuadraticAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "q" : curveToQuadraticRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "S" : curveToCubicSmoothAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "s" : curveToCubicSmoothRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "T" : curveToQuadraticSmoothAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "t" : curveToQuadraticSmoothRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;

								case "C" : cubicCurveToAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "c" : cubicCurveToRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;

								case "A" : arcAbs(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), args[a++], args[a++]!=0, args[a++]!=0, getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT)); break;
								case "a" : arcRel(getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT), args[a++], args[a++]!=0, args[a++]!=0, getUnit(args[a++], WIDTH), getUnit(args[a++], HEIGHT));break;
								default : trace("Invalid PathCommand type: " +command.type);
														break while_args;
						}
				}
			}

		}

		public function moveToAbs(x:Number, y:Number):void {
			cpoint = new Point(x,y);
			opoint = cpoint;
		}

		public function moveToRel(x:Number, y:Number):void {
			moveToAbs(x+cpoint.x, y+cpoint.y);
		}

		public function lineToAbs(x:Number, y:Number):void {
			var s:Segment = new Segment(cpoint, new Point(x,y));
			cpoint = s.p2;
			seglist.push(s);
		}

		public function lineToRel(x:Number, y:Number):void {
			lineToAbs(x+cpoint.x,y+cpoint.y);
		}

		public function lineToHorizontalAbs(x:Number):void {
			lineToAbs(x, cpoint.y);
		}

		public function lineToHorizontalRel(x:Number):void {
			lineToHorizontalAbs(x+cpoint.x);
		}

		public function lineToVerticalAbs(y:Number):void {
			lineToAbs(cpoint.x, y);
		}

		public function lineToVerticalRel(y:Number):void {
			lineToVerticalAbs(y+cpoint.y);
		}

		public function curveToQuadraticAbs(x1:Number, y1:Number, x:Number, y:Number):void {
			var s:QuadBezierSegment = new QuadBezierSegment(cpoint, new Point(x,y), new Point(x1,y1));
			cpoint = s.p2;
			seglist.push(s);
			lastC = new Point(x1, y1);
		}

		public function curveToQuadraticRel(control_x:Number, control_y:Number, anchor_x:Number, anchor_y:Number):void {
			curveToQuadraticAbs(control_x+cpoint.x, control_y+cpoint.y, anchor_x+cpoint.x, anchor_y+cpoint.y);
		}

		public function curveToQuadraticSmoothAbs(x:Number, y:Number):void {
			if(lastC){
				var x1:Number = cpoint.x + (cpoint.x - lastC.x);
				var y1:Number = cpoint.y + (cpoint.y - lastC.y);
				curveToQuadraticAbs(x1, y1, x, y);
				lastC = new Point(x1, y1);
			}
		}

		public function curveToQuadraticSmoothRel(x:Number, y:Number):void {
			curveToQuadraticSmoothAbs(x+cpoint.x, y+cpoint.y);
		}

		public function cubicCurveToAbs(x1:Number, y1:Number, x2:Number, y2:Number, x:Number, y:Number):void{
			var s:CubicBezierSegment = new CubicBezierSegment(cpoint, new Point(x,y), new Point(x1,y1), new Point(x2,y2));
			cpoint = s.p2;
			seglist.push(s);
			lastC = new Point(x2, y2);
		}

		public function cubicCurveToRel(x1:Number, y1:Number, x2:Number, y2:Number, x:Number, y:Number):void{
			cubicCurveToAbs(x1+cpoint.x, y1+cpoint.y, x2+cpoint.x, y2+cpoint.y, x+cpoint.x, y+cpoint.y);
		}

		public function curveToCubicSmoothAbs(x2:Number, y2:Number, x:Number, y:Number):void {
			if(lastC){
				var x1:Number = cpoint.x + (cpoint.x - lastC.x);
				var y1:Number = cpoint.y + (cpoint.y - lastC.y);

				cubicCurveToAbs(x1, y1, x2, y2, x, y);
			}
		}

		public function curveToCubicSmoothRel(x2:Number, y2:Number, x:Number, y:Number):void {
			curveToCubicSmoothAbs(x2+cpoint.x, y2+cpoint.y, x+cpoint.x, y+cpoint.y);
		}

		public function arcAbs(rx:Number, ry:Number,angle:Number,largeArcFlag:Boolean,sweepFlag:Boolean,x:Number,y:Number):void {
        	var s:ArcSegment = new ArcSegment(cpoint, new Point(x,y), rx, ry, angle, largeArcFlag, sweepFlag);
			cpoint = s.p2;
			seglist.push(s);
		}

		public function arcRel(rx:Number, ry:Number, xAxisRotation:Number, largeArcFlag:Boolean, sweepFlag:Boolean,x:Number, y:Number):void {
			arcAbs(rx, ry, xAxisRotation, largeArcFlag, sweepFlag, x+cpoint.x, y+cpoint.y);
		}

		private function closePath():void{
			if(cpoint.equals(opoint)){
				var oseg:Segment = null; // origin segment
				var cseg:Segment = null; // current segment (ending segment)
				for(var i:int=0; i<seglist.length; i++){
					if(seglist[i].p2 == cpoint){
						cseg = seglist[i];
					}
					if(seglist[i].p1 == opoint){
						oseg = seglist[i];
					}
				}
				if(oseg != null && cseg != null){
					cseg.p2 = oseg.p1;
				}
			}
			else{
				var s:Segment = new Segment(cpoint, opoint);
				cpoint = opoint;
				seglist.push(s);
			}
		}

		public function getUnit(s:String, viewBoxReference:String = ""):Number {
			return parent.getUnit(s, viewBoxReference);
		}



	}
}