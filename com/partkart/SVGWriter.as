package com.partkart{
	
	import flash.geom.Point;
	
	public class SVGWriter{
		
		private var pathlist:Array;
		private var cutlist:Array;
		
		private var svg:String;
		
		private var maxx:Number;
		private var maxy:Number;
		
		public function SVGWriter(inputpaths:Array, inputcuts:Array){
			pathlist = inputpaths;
			cutlist = inputcuts;
		}
		
		public function parse():String{
			maxx = 0;
			maxy = 0;
			
			var minx:Number = 0;
			var miny:Number = 0;
			
			for(var i:int =0; i<pathlist.length; i++){
				var max:Point = pathlist[i].getMax();
				var min:Point = pathlist[i].getMin();
				
				if(max.x > maxx){
					maxx = max.x;
				}
				if(max.y > maxy){
					maxy = max.y;
				}
				
				if(min.x < minx){
					minx = min.x;
				}
				if(min.y < miny){
					miny = min.y;
				}
			}
			
			maxx -= minx;
			maxy -= miny;
			
			for(i=0; i<pathlist.length; i++){
				pathlist[i].name = "path"+i;
			}
			
			svg = "<?xml version='1.0'?>\n<!DOCTYPE svg PUBLIC '-//W3C//DTD SVG 1.1//EN' 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd'>\n<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' width='"+maxx+Global.unit +"' height='"+maxy+Global.unit+"' viewBox='0 0 "+maxx+" "+maxy+"'>";
			
			// add cutobjects as metadata
			
			if(cutlist && cutlist.length > 0){
				svg += "\n<metadata>\n";
				
				for(i=0; i<cutlist.length; i++){
					svg += "<cutobject ";
					svg += 'type="';
					
					if(cutlist[i] is ProfileCutObject){
						svg += "profile";
					}
					else if(cutlist[i] is PocketCutObject){
						svg += "pocket";
					}
					else if(cutlist[i] is FollowPathCutObject){
						svg += "followpath";
					}
					else if(cutlist[i] is DrillCutObject){
						svg += "drill";
					}
					
					svg += '" ';
					
					svg += 'unit="'+(Global.unit == "in" ? "imperial" : "metric")+'" ';
					svg += 'name="' + escape(cutlist[i].name) + '" ';
					svg += 'safetyheight="' + cutlist[i].safetyheight + '" ';
					svg += 'stocksurface="'+ cutlist[i].stocksurface +'" ';
					svg += 'targetdepth="'+ cutlist[i].targetdepth +'" ';
					svg += 'stepover="'+ cutlist[i].stepover +'" ';
					svg += 'stepdown="'+ cutlist[i].stepdown +'" ';
					svg += 'feedrate="'+ cutlist[i].feedrate +'" ';
					svg += 'plungerate="'+ cutlist[i].plungerate +'" ';
					
					svg += 'tooldiameter="'+ cutlist[i].tooldiameter +'" ';
					svg += 'roughingclearance="'+ cutlist[i].roughingclearance +'" ';
					svg += 'outside="'+ (cutlist[i].outside == true ? "true" : "false") +'" ';
					
					if(cutlist[i] is DrillCutObject){
						svg += 'center="'+ (cutlist[i].center == true ? "true" : "false") +'" ';
						svg += 'spacing="'+ cutlist[i].spacing +'" ';
					}
					
					svg += ">\n";
					
					for each(var path:Path in cutlist[i].pathlist){
						svg += "<path>"+path.name+"</path>\n";
					}
					
					svg += '</cutobject>'+"\n";
				}
				
				svg += "</metadata>\n";
			}
			
			for(i=0; i<pathlist.length; i++){
				parsePath(pathlist[i]);
			}
			svg += "\n</svg>";
			
			return svg;
		}
		
		private function parsePath(p:Path):void{
			svg += "\n<path id='"+p.name+"' stroke='black' fill='none' stroke-width='0.02' d='";
			
			var seglist:Array = p.getSegments();
			
			var origin:Point = seglist[0].p1;
			var next:Point = seglist[0].p2;
			var seg:Segment = seglist[0];
			
			svg += "M"+(origin.x+p.docx);
			svg += " "+(-origin.y+p.docy+maxy);
			
			while(seglist.length > 0){
				if(seg is QuadBezierSegment){
					svg += parseQuad(p, seg as QuadBezierSegment, next);
				}
				else if(seg is CubicBezierSegment){
					svg += parseCubic(p, seg as CubicBezierSegment, next);
				}
				else if(seg is ArcSegment){
					svg += parseArc(p, seg as ArcSegment, next);
				}
				else{
					svg += parseLine(p, next);
				}
				
				seglist.splice(seglist.indexOf(seg),1);
				
				if(seglist.length > 0){
					var found:Boolean = false;
					for(var i:int=0; i<seglist.length; i++){
						if(seglist[i].p1 == next){
							seg = seglist[i];
							next = seglist[i].p2;
							found = true;
							break;
						}
						else if(seglist[i].p2 == next){
							seg = seglist[i];
							next = seglist[i].p1;
							found = true;
							break;
						}
					}
					if(found == false){
						
						if(next == origin){
							svg += " Z";
						}
						
						seg = seglist[0];
						
						svg += " M"+(seglist[0].p1.x+p.docx);
						svg += " "+(-seglist[0].p1.y+p.docy+maxy);
						
						origin = seglist[0].p1;
						
						next = seglist[0].p2;
					}
				}
				else{
					if(next == origin){
						svg += " Z";
					}
				}
			}
			
			svg += "'/>";
			
		}
		
		private function parseLine(p:Path, next:Point):String{
			var line:String = " L";
			line += (next.x+p.docx);
			line += " " + (-next.y+p.docy+maxy);
			
			return line;
		}
		
		private function parseQuad(p:Path, seg:QuadBezierSegment, next:Point):String{
			var s:String = " Q";
			
			s += (seg.c1.x + p.docx);
			s += " " + (-seg.c1.y + p.docy+maxy);
			
			s += " " + (next.x + p.docx);
			s += " " + (-next.y + p.docy+maxy);
			
			return s;
		}
		
		private function parseCubic(p:Path, seg:CubicBezierSegment, next:Point):String{
			var s:String = " C";
			
			var c1:Point;
			var c2:Point;
			
			if(seg.p2 == next){
				c1 = seg.c1;
				c2 = seg.c2;
			}
			else{
				c1 = seg.c2;
				c2 = seg.c1;
			}
			
			s += c1.x + p.docx;
			s += " " + (-c1.y + p.docy+maxy);
			
			s += " " + (c2.x + p.docx);
			s += " " + (-c2.y + p.docy+maxy);
			
			s += " " + (next.x + p.docx);
			s += " " + (-next.y + p.docy+maxy);
			
			return s;
		}
		
		private function parseArc(p:Path, seg:ArcSegment, next:Point):String{
			var a:String = " A";
			
			a += seg.rx;
			a += " " + String(-seg.ry);
			a += " " + String(-seg.angle);
			if(seg.lf == true){
				a += " 1"
			}
			else{
				a += " 0";
			}
			if(seg.p2 == next){
				if(seg.sf == false){
					a += " 1"
				}
				else{
					a += " 0";
				}
			}
			else{
				if(seg.sf == true){
					a += " 1"
				}
				else{
					a += " 0";
				}
			}
			
			a += " " + (next.x + p.docx);
			a += " " + (-next.y + p.docy+maxy);
			
			return a;
			
		}
	}
}