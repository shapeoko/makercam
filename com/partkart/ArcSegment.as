package com.partkart{
	import flash.geom.Point;
	
	public class ArcSegment extends Segment{
		
		public var rx:Number;
		public var ry:Number;
		public var angle:Number;
		
		public var lf:Boolean;
		public var sf:Boolean;
		
		public function ArcSegment(point1:Point, point2:Point, radiusx:Number, radiusy:Number, axisangle:Number, largeflag:Boolean, sweepflag:Boolean):void{
			super(point1, point2);
			
			rx = radiusx;
			ry = radiusy;
			angle = axisangle;
			lf = largeflag;
			sf = sweepflag;
		}
		
		/** 
		 * Functions from degrafa
		 * com.degrafa.geometry.utilities.ArcUtils
		 **/
		public function computeSvgArc():Object {
			var largeArcFlag:Boolean = lf;
			var sweepFlag:Boolean = !sf;
			
			//store before we do anything with it    
			var xAxisRotation:Number = angle;        
													
			// Compute the half distance between the current and the final point
			var dx2:Number = (p2.x - p1.x) / 2.0;
			var dy2:Number = (p2.y - p1.y) / 2.0;
			
			// Convert angle from degrees to radians
			angle = degreesToRadians(angle);
			var cosAngle:Number = Math.cos(angle);
			var sinAngle:Number = Math.sin(angle);
	
			
			//Compute (x1, y1)
			var x1:Number = (cosAngle * dx2 + sinAngle * dy2);
			var y1:Number = (-sinAngle * dx2 + cosAngle * dy2);
			
			// Ensure radii are large enough
			rx = Math.abs(rx);
			ry = Math.abs(ry);
			var Prx:Number = rx * rx;
			var Pry:Number = ry * ry;
			var Px1:Number = x1 * x1;
			var Py1:Number = y1 * y1;
			
			// check that radii are large enough
			var radiiCheck:Number = Px1/Prx + Py1/Pry;
			if (radiiCheck > 1) {
				rx = Math.sqrt(radiiCheck) * rx;
				ry = Math.sqrt(radiiCheck) * ry;
				Prx = rx * rx;
				Pry = ry * ry;
			}
	
			
			//Compute (cx1, cy1)
			var sign:Number = (largeArcFlag == sweepFlag) ? -1 : 1;
			var sq:Number = ((Prx*Pry)-(Prx*Py1)-(Pry*Px1)) / ((Prx*Py1)+(Pry*Px1));
			sq = (sq < 0) ? 0 : sq;
			var coef:Number = (sign * Math.sqrt(sq));
			var cx1:Number = coef * ((rx * y1) / ry);
			var cy1:Number = coef * -((ry * x1) / rx);
	
			
			//Compute (cx, cy) from (cx1, cy1)
			var sx2:Number = (p2.x + p1.x) / 2.0;
			var sy2:Number = (p2.y + p1.y) / 2.0;
			var cx:Number = sx2 + (cosAngle * cx1 - sinAngle * cy1);
			var cy:Number = sy2 + (sinAngle * cx1 + cosAngle * cy1);
	
			
			//Compute the angleStart (angle1) and the angleExtent (dangle)
			var ux:Number = (x1 - cx1) / rx;
			var uy:Number = (y1 - cy1) / ry;
			var vx:Number = (-x1 - cx1) / rx;
			var vy:Number = (-y1 - cy1) / ry;
			var p:Number 
			var n:Number
			
			//Compute the angle start
			n = Math.sqrt((ux * ux) + (uy * uy));
			p = ux;
			
			sign = (uy < 0) ? -1.0 : 1.0;
			
			var angleStart:Number = radiansToDegrees(sign * Math.acos(p / n));
	
			// Compute the angle extent
			n = Math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
			p = ux * vx + uy * vy;
			sign = (ux * vy - uy * vx < 0) ? -1.0 : 1.0;
			var angleExtent:Number = radiansToDegrees(sign * Math.acos(p / n));
			
			if(!sweepFlag && angleExtent > 0) 
			{
				angleExtent -= 360;
			} 
			else if (sweepFlag && angleExtent < 0) 
			{
				angleExtent += 360;
			}
			
			angleExtent %= 360;
			angleStart %= 360;
					
			return Object({x:p2.x,y:p2.y,startAngle:angleStart,arc:angleExtent,radius:rx,yRadius:ry,xAxisRotation:xAxisRotation, cx:cx,cy:cy});
		}
		
		// note: current implementation merely linearizes the bezier approximations. This is not very accurate - must be improved in the future!
		public function linearize(circle:Boolean = false):Array{	
		
			var ellipticalArc:Object  = computeSvgArc();
			
			var startpoint:Point = p2;
			var x:Number = ellipticalArc.cx;
			var y:Number = ellipticalArc.cy;
			
			var startAngle:Number = ellipticalArc.startAngle;
			var arc:Number = ellipticalArc.arc;
			
			var radius:Number = ellipticalArc.radius;
			var yRadius:Number = ellipticalArc.yRadius;
			
			var xAxisRotation = ellipticalArc.xAxisRotation;
			
			// Circumvent drawing more than is needed
			if (Math.abs(arc)>360)
			{
					arc = 360;
			}
		   
			// Draw in a maximum of 45 degree segments. First we calculate how many
			// segments are needed for our arc.
			var segs:Number = Math.ceil(Math.abs(arc)/45);
		   
			// Now calculate the sweep of each segment
			var segAngle:Number = arc/segs;
		   
			var theta:Number = degreesToRadians(segAngle);
			//var theta:Number = Math.sqrt(Global.tolerance/Math.max(Math.abs(radius),Math.abs(yRadius))); // this dtheta ensures that the segments never deviate past the global tolerance values
			var angle:Number = degreesToRadians(startAngle);
		   	
			//var segs:int = Math.ceil(Math.abs(arc/radiansToDegrees(theta)));
			//theta = degreesToRadians(arc/segs);
			
		   	var seglist:Array = new Array();
		   
			// Draw as 45 degree segments
			if (segs>0)
			{                              
				var beta:Number = degreesToRadians(xAxisRotation);
				var sinbeta:Number = Math.sin(beta);
				var cosbeta:Number = Math.cos(beta);
	   
				var cx:Number;
				var cy:Number;
				var x1:Number;
				var y1:Number;
				
				var tp1:Point = startpoint; // note that we start at the "end" of the arc as defined in arcSegment
				var tp2:Point;
				var tc1:Point;

				// Loop for drawing arc segments
				for (var i:int = 0; i<segs; i++)
				{
						angle += theta;

						var sinangle:Number = Math.sin(angle-(theta/2));
						var cosangle:Number = Math.cos(angle-(theta/2));
					   
						var div:Number = Math.cos(theta/2);
						cx= x + (radius * cosangle * cosbeta - yRadius * sinangle * sinbeta)/div;
						cy= y + (radius * cosangle * sinbeta + yRadius * sinangle * cosbeta)/div;
					   
						sinangle = Math.sin(angle);
						cosangle = Math.cos(angle);
					   
						x1 = x + (radius * cosangle * cosbeta - yRadius * sinangle * sinbeta);
						y1 = y + (radius * cosangle * sinbeta + yRadius * sinangle * cosbeta);
						
						tp2 = new Point(x1,y1);
						tc1 = new Point(cx, cy);
						
						if(i == segs-1){
							seglist.push(new QuadBezierSegment(tp1,p1,tc1));
						}
						else{
							seglist.push(new QuadBezierSegment(tp1,tp2,tc1));
						}
						
						tp1 = tp2;
				}
			}
			
			//seglist.reverse();
			
			var newseglist:Array = new Array();
			
			for(i=0; i<seglist.length; i++){
				newseglist = newseglist.concat(seglist[i].linearize(circle));
			}
			
			return reversePath(newseglist);
		}
		
		protected function reversePath(seglist:Array):Array{
			for(var i:int=0; i<seglist.length; i++){
				seglist[i] = reverseSegment(seglist[i]);
			}
			seglist.reverse();
			
			return seglist;
		}
		
		protected function reverseSegment(seg:*):*{
			if(seg is CircularArc){
				var seg1:CircularArc = seg as CircularArc;
				
				seg1 = new CircularArc(seg1.p2, seg1.p1, seg1.center.clone(), -seg1.radius);
				
				return seg1;
			}
			else{				
				var seg2:Segment = new Segment(seg.p2, seg.p1);
				
				return seg2;
			}
		}
		
		protected static function degreesToRadians(angle:Number):Number{
			return angle*(Math.PI/180);
		}
		
		protected static function radiansToDegrees(angle:Number):Number{
			return angle*(180/Math.PI);
		}
	}
}