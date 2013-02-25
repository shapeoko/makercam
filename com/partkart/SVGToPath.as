package com.partkart{

	import flash.geom.Point;
	import flash.geom.Matrix;
	import flash.geom.Transform;

	import com.lorentz.SVG.*;

	public class SVGToPath{

		private var pathlist:Array = new Array();
		private var viewboxes:Array = new Array();
		private var svgboxes:Array = new Array();
		//private var currentViewBox:Object;
		private var currentFontSize:Number = 12/72;

		private var svg_object:Object;

		protected const WIDTH:String = "width";
		protected const HEIGHT:String = "height";
		protected const WIDTH_HEIGHT:String = "width_height";


		public function SVGToPath(){}

		public function parse(e:Object, trans:Matrix = null):Array{

			if(e.type == "svg"){
				svg_object = e;

				var svgbox:Object = new Object();

				svgbox.heightunit = getUnitType(e.height);
				svgbox.widthunit = getUnitType(e.width);

				svgbox.height = StringUtil.remove(e.height, getUnitType(e.height));
				svgbox.width = StringUtil.remove(e.width, getUnitType(e.width));

				svgbox.viewbox = e.viewBox;

				svgboxes.push(svgbox);
			}

			inheritStyles(e);

			var pushed:Boolean = false;

			if(e.viewBox!=null){
				viewboxes.push(e.viewBox);
				pushed = true;
			}

			if(e.finalStyle && e.finalStyle["font-size"]!=null){
					currentFontSize = getUnit(e.finalStyle["font-size"], HEIGHT);
			}

			var p:Path;

			switch(e.type) {
				case 'svg':
				parseSvg(e, trans); break;

				case 'rect':
				p = parseRect(e); break;

				case 'path':
				p = parsePath(e); break;

				case 'polygon':
				p = parsePoly(e, true); break;

				case 'polyline':
				p = parsePoly(e, false); break;

				case 'line':
				p = parseLine(e); break;

				case 'circle':
				p = parseCircle(e); break;

				case 'ellipse':
				p = parseEllipse(e); break;

				case 'g':
				 parseG(e, trans); break;

				case 'text':
				 parseText(e); break;
			}

			if(pushed == true){
				viewboxes.pop();
			}
			if(e.type == 'svg'){
				svgboxes.pop();
			}

			if(p != null){
				if(trans){
					p.matrixTransform(getMatrixUnits(trans));
				}
				if(e.transform){
					if(e.transform is Transform){
						p.matrixTransform(getMatrixUnits(e.transform.matrix));
					}
					else if(e.transform is Matrix){
						p.matrixTransform(getMatrixUnits(e.transform));
					}
				}
				pathlist.push(p);
			}

			return pathlist;

		}

		private function parseSvg(e:Object, m:Matrix = null):void{
			var trans:Matrix;

			if(e.transform && m){
				if(e.transform is Transform){
					trans = e.transform.matrix.clone();
				}
				else if(e.transform is Matrix){
					trans = e.transform.clone();
				}
				trans.concat(m);
			}
			else if(e.transform){
				if(e.transform is Transform){
					trans = e.transform.matrix.clone();
				}
				else if(e.transform is Matrix){
					trans = e.transform.clone();
				}
			}
			else if(m){
				trans = m.clone();
			}

			/*if(trans != null){
				trans.ty = -trans.ty;
			}*/

			for each(var element:Object in e.children){
				parse(element, trans);
			}
		}

		public function parseRect(e:Object):Path{
			var x:Number = getUnit(e.x, WIDTH);
			var y:Number = getUnit(e.y, HEIGHT);
			var width:Number = getUnit(e.width, WIDTH);
			var height:Number = getUnit(e.height, HEIGHT);

			var s1:Segment;
			var s2:Segment;
			var s3:Segment;
			var s4:Segment;

			var r1:ArcSegment;
			var r2:ArcSegment;
			var r3:ArcSegment;
			var r4:ArcSegment;

			var p:Path = new Path();

			var rx:Number = getUnit(e.rx, WIDTH);
            var ry:Number = getUnit(e.ry, HEIGHT);

			if(e.isRound && (rx != 0 || ry != 0)) {
				if(rx == 0){
					rx = ry;
				}
				if(ry == 0){
					ry = rx;
				}
				if(rx > width/2){
					rx = width/2;
				}
				if(ry > height/2){
					ry = height/2;
				}

				r1 = new ArcSegment(new Point(x, y+ry), new Point(x+rx, y), rx,ry,0,false,true);
				s1 = new Segment(r1.p2, new Point(x+width-rx, y));

				r2 = new ArcSegment(s1.p2, new Point(x+width, y+ry), rx,ry,0,false,true);
				s2 = new Segment(r2.p2, new Point(x+width, y+height-ry));

				r3 = new ArcSegment(s2.p2, new Point(x+width-rx, y+height), rx,ry,0,false,true);
				s3 = new Segment(r3.p2, new Point(x+rx, y+height));

				r4 = new ArcSegment(s3.p2, new Point(x,y+height-rx), rx,ry,0,false,true);
				s4 = new Segment(r4.p2, r1.p1);

				p.addSegment(r1);
				p.addSegment(s1);
				p.addSegment(r2);
				p.addSegment(s2);
				p.addSegment(r3);
				p.addSegment(s3);
				p.addSegment(r4);
				p.addSegment(s4);
			}
			else{
				s1 = new Segment(new Point(x,y), new Point(x+width, y));
				s2 = new Segment(s1.p2, new Point(x+width, y+height));
				s3 = new Segment(s2.p2, new Point(x, y+height));
				s4 = new Segment(s3.p2, s1.p1);

				p.addSegment(s1);
				p.addSegment(s2);
				p.addSegment(s3);
				p.addSegment(s4);
			}

			if(p.getNumSeg() > 0){
				return p;
			}
			return null;
		}

		private function parsePath(e:Object):Path{

			var pathparser:PathParser = new PathParser(this);
			var p:Path = pathparser.parse(e.d);

			if(e.id != null && p != null){
				p.name = String(e.id);
			}

			return p;
		}

		private function parsePoly(e:Object, ispoly:Boolean):Path{
			var p:Path = new Path();

			var args:Array = e.points;

			if(args.length >= 4 && args.length%2 == 0){ // if an odd number of args, it is in error!

				var i:int = 2;
				var cpoint:Point = new Point(getUnit(args[0], WIDTH), getUnit(args[1], HEIGHT));
				var opoint:Point = cpoint; // keep a copy of the origin for last leg of polygon
				var npoint:Point;

				while(i<args.length-1){
					npoint = new Point(getUnit(args[i], WIDTH), getUnit(args[i+1], HEIGHT));
					var seg:Segment = new Segment(cpoint, npoint);
					p.addSegment(seg);
					cpoint = npoint;
					i += 2;
				}
				if(ispoly && !cpoint.equals(opoint)){
					var seg1:Segment = new Segment(cpoint, opoint);
					p.addSegment(seg1);
				}

				return p;
			}
			return null;
		}

		private function parseLine(e:Object):Path{
			var x1:Number = getUnit(e.x1, WIDTH);
			var y1:Number = getUnit(e.y1, HEIGHT);
			var x2:Number = getUnit(e.x2, WIDTH);
			var y2:Number = getUnit(e.y2, HEIGHT);

			if(!isNaN(x1) && !isNaN(y1) && !isNaN(x2) && !isNaN(y2)){
				var seg:Segment = new Segment(new Point(x1,y1), new Point(x2,y2));
				var p:Path = new Path();
				p.addSegment(seg);
				return p;
			}
			return null;
		}

		private function parseCircle(e:Object):Path{
			var cx:Number = getUnit(e.cx, WIDTH);
			var cy:Number = getUnit(e.cy, HEIGHT);
			var r:Number = getUnit(e.r, WIDTH);

			if(!isNaN(cx) && !isNaN(cy) && !isNaN(r)){
				var a1:ArcSegment = new ArcSegment(new Point(cx - r, cy), new Point(cx + r, cy), r/1000,r/1000,0, false,false);
				var a2:ArcSegment = new ArcSegment(a1.p1, a1.p2, r/1000,r/1000, 0,false,true);
				var p:Path = new Path();
				p.addSegment(a1);
				p.addSegment(a2);
				return p;
			}
			return null;
		}

		public function parseEllipse(e:Object):Path{
			var cx:Number = getUnit(e.cx, WIDTH);
			var cy:Number = getUnit(e.cy, HEIGHT);
			var rx:Number = getUnit(e.rx, WIDTH);
			var ry:Number = getUnit(e.ry, HEIGHT);

			if(!isNaN(cx) && !isNaN(cy) && !isNaN(rx) && !isNaN(ry)){
				var a1:ArcSegment = new ArcSegment(new Point(cx - rx, cy), new Point(cx + rx, cy), rx/1000,ry/1000,0, false,false);
				var a2:ArcSegment = new ArcSegment(a1.p1, a1.p2, rx/1000,ry/1000, 0,false,true);
				var p:Path = new Path();
				p.addSegment(a1);
				p.addSegment(a2);
				return p;
			}
			return null;

		}

		private function parseG(e:Object, m:Matrix = null):void{
			var trans:Matrix;

			if(e.transform && m){
				if(e.transform is Transform){
					trans = e.transform.matrix.clone();
				}
				else if(e.transform is Matrix){
					trans = e.transform.clone();
				}
				trans.concat(m);
			}
			else if(e.transform){
				if(e.transform is Transform){
					trans = e.transform.matrix.clone();
				}
				else if(e.transform is Matrix){
					trans = e.transform.clone();
				}
			}
			else if(m){
				trans = m.clone();
			}

			for each(var element:Object in e.children){
				parse(element, trans);
			}
		}

		private function parseText(e:Object):void{

		}

		public function getUnit(s:String, viewBoxReference:String = ""):Number {
			if(s == null){
				return 0;
			}

			var value:Number;

			if(s.indexOf("pt")!=-1){ // a point is an absolute unit defined as exactly 1/72 of an inch, it is not related to relative pixel size
					value = Number(StringUtil.remove(s, "pt"));
					value = value/72;
			} else if(s.indexOf("pc")!=-1){ // pc = pica
					value = Number(StringUtil.remove(s, "pc"));
					value = value*12/72;
			} else if(s.indexOf("mm")!=-1){
					value = Number(StringUtil.remove(s, "mm"));
					value = value/25.4;
			} else if(s.indexOf("cm")!=-1){
					value = Number(StringUtil.remove(s, "cm"));
					value = value/2.54;
			} else if(s.indexOf("in")!=-1){
					value = Number(StringUtil.remove(s, "in"));
			} else if(s.indexOf("px")!=-1){
					value = Number(StringUtil.remove(s, "px"));
					value = value/Global.importres;

			//Relative
			} else if(s.indexOf("em")!=-1){
					value = Number(StringUtil.remove(s, "em"));
					value = value*currentFontSize;

			//Percentage
			} else if(s.indexOf("%")!=-1){
					value = Number(StringUtil.remove(s, "%"));
					var currentViewBox:Object = viewboxes[viewboxes.length-1];
					switch(viewBoxReference){
							case WIDTH : value = (value/100) * getUnit(currentViewBox.width);
								break;
							case HEIGHT : value = (value/100) * getUnit(currentViewBox.height);
								break;
							default : value = value/100 * Math.sqrt(Math.pow(getUnit(currentViewBox.width),2)+Math.pow(getUnit(currentViewBox.height),2))/Math.sqrt(2);
								break;
					}
			} else {
					if(viewBoxReference != "" && svgboxes.length > 0 && svgboxes[svgboxes.length-1].viewbox != null){
						var sbox:Object = svgboxes[svgboxes.length-1];
						if(viewBoxReference == WIDTH && sbox.width != null){
							value = getUnit(Number(s)*(sbox.width/sbox.viewbox.width) + sbox.widthunit);
						}
						if(viewBoxReference == HEIGHT && sbox.height != null){
							value = getUnit(Number(s)*(sbox.height/sbox.viewbox.height) + sbox.heightunit);
						}

						if(Global.unit == "cm"){ // we treat values internal to the getunit function as inches, if global units are in cm, we must convert to inches
							value = value/2.54;
						}
					}
					else{
						value = Number(s)/Global.importres; // assume pixels
					}
			}

			if(Global.unit == "in"){
				return value;
			}
			else if(Global.unit == "cm"){
				return value*2.54;
			}
			return NaN;
		}

		public function getUnitType(s:String):String{
			if(s.indexOf("pt")!=-1){
				return "pt";
			} else if(s.indexOf("pc")!=-1){
				return "pc";
			} else if(s.indexOf("mm")!=-1){
				return "mm";
			} else if(s.indexOf("cm")!=-1){
				return "cm";
			} else if(s.indexOf("in")!=-1){
				return "in";
			} else if(s.indexOf("px")!=-1){
				return "px";
			} else if(s.indexOf("em")!=-1){
				return "em";
			} else if(s.indexOf("%")!=-1){
				return "%";
			} else{
				return "";
			}
		}

		private function getMatrixUnits(m:Matrix):Matrix{
			// at this point, we can assume matrix values are in pixels
			var matrix:Matrix = m.clone();

			if(svgboxes.length > 0 && svgboxes[svgboxes.length-1].viewbox != null){
				var sbox:Object = svgboxes[svgboxes.length-1];

				matrix.tx = getUnit(matrix.tx*(sbox.width/sbox.viewbox.width) + sbox.widthunit);
				matrix.ty = getUnit(matrix.ty*(sbox.height/sbox.viewbox.height) + sbox.heightunit);
			}
			else{
				matrix.tx = matrix.tx/Global.importres;
				matrix.ty = matrix.ty/Global.importres;

				if(Global.unit == "cm"){
					matrix.tx = matrix.tx*2.54;
					matrix.ty = matrix.ty*2.54;
				}
			}

			return matrix;
		}

		private function inheritStyles(elt:Object):void {
			if(elt.parent){
					elt.finalStyle = elt.parent.finalStyle; //Inherits parent style
			} else {
					elt.finalStyle = new Object();
			}

			if(svg_object.styles[elt.type]!=null){ //Merge with elements styles
					elt.finalStyle = SVGUtil.mergeObjectStyles(elt.finalStyle, svg_object.styles[elt.type]);
			}

			if(elt["class"]){ //Merge with classes styles
					for each(var className:String in String(elt["class"]).split(" "))
							elt.finalStyle = SVGUtil.mergeObjectStyles(elt.finalStyle, svg_object.styles["."+className]);
			}

			if(elt.style) //Merge all styles with the style attribute
					elt.finalStyle = SVGUtil.mergeObjectStyles(elt.finalStyle, elt.style);
		}


	}
}