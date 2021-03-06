﻿package com.partkart{
	import flash.geom.Point;
	import com.partkart.Segment;

	public class QuadBezierSegment extends Segment{

		public var c1:Point;

		private var seglist:Array;

		public function QuadBezierSegment(point1:Point, point2:Point, control1:Point):void{
			super(point1, point2);

			c1 = control1;
		}

		public function getPoint(time : Number, point : Point = null):Point {
			if (isNaN(time)) {
					return undefined;
			}
			point = (point as Point) || new Point();
			const f : Number = 1 - time;
			point.x = p1.x * f * f + c1.x * 2 * time * f + p2.x * time * time;
			point.y = p1.y * f * f + c1.y * 2 * time * f + p2.y * time * time;
			return point;
		}

		public function linearize(circle:Boolean = false):Array{
			seglist = new Array();
			seglist.push(this);

			loopdivide(circle);
			//subdivide(this, Global.tolerance, 0.5, circle);

			return seglist;
		}

		// flash's recursion stack is limited, we use loops instead
		private function loopdivide(circle:Boolean):void{
			var dividelist:Array = seglist.slice();
			while(dividelist.length > 0){
				var seg:QuadBezierSegment = dividelist[0];

				var re:Array = subdivide(seg,Global.tolerance, 0.5, circle);
				if(re && re.length == 2){
					dividelist.splice(0,1,re[0],re[1]);
				}
				else{
					dividelist.shift();
				}
			}
		}

		// recursively subdivide bezier segment to within the given tolerance
		// using de Casteljau subdivision
		private function subdivide(seg:QuadBezierSegment, tol:Number, t:Number, circle = false):Array{

			if(circle){
				var biarc:Biarc = isbiarc(seg, tol);
				// approximate with biarc
				if(biarc){
					var arcs:Array = biarc.getArcs();
					seglist.splice(seglist.indexOf(seg),1,arcs[0],arcs[1]);
					return null;
				}
			}
			// use more stringent tests for flatness if circles are specified (circular arcs are more desirable)
			if((circle == false && isflat(seg, tol)) || (circle == true && isflat(seg, 0.5*tol))){
				// convert to line
				seglist.splice(seglist.indexOf(seg),1,new Segment(seg.p1,seg.p2));
				return null;
			}
			//else{
				// first calculate midpoints
				// note: they are actual midpoints only when t = 0.5

				var mid1:Point = new Point(seg.p1.x+(seg.c1.x-seg.p1.x)*t, seg.p1.y+(seg.c1.y-seg.p1.y)*t);
				var mid2:Point = new Point(seg.c1.x+(seg.p2.x-seg.c1.x)*t, seg.c1.y+(seg.p2.y-seg.c1.y)*t);

				var mid3:Point = new Point(mid1.x+(mid2.x-mid1.x)*t, mid1.y+(mid2.y-mid1.y)*t);

				var seg1:QuadBezierSegment = new QuadBezierSegment(seg.p1,mid3,mid1);
				var seg2:QuadBezierSegment = new QuadBezierSegment(mid3,seg.p2,mid2);

				seglist.splice(seglist.indexOf(seg),1,seg1,seg2);

				return new Array(seg1, seg2);
				//subdivide(seg1, tol, 0.5, circle);
				//subdivide(seg2, tol, 0.5, circle);
			//}
		}

		private function isbiarc(seg:QuadBezierSegment, tol:Number):Biarc{
			var intersect:Point = seg.c1;

			if(intersect == null){
				return null;
			}

			var biarc:Biarc = new Biarc(seg.p1, intersect, seg.p2);

			// limit max radius (some machine controllers limit this radius)
			var radiuslimit:Number = 400;
			if(Global.unit == 'cm'){
				radiuslimit *= 2.54;
			}

			if(biarc == null || isNaN(biarc.r1) || isNaN(biarc.r2) || Math.abs(biarc.r1) > radiuslimit || Math.abs(biarc.r2) > radiuslimit){
				return null;
			}

			// determine whether the biarc is a close enough approximation to the given segment
			var deviation1:Number = getmaxdeviation(0,0.5,seg,biarc.c1,biarc.r1);
			var deviation2:Number = getmaxdeviation(0.5,1,seg,biarc.c2,biarc.r2);

			var deviation:Number = Math.max(deviation1,deviation2);

			if(deviation < tol){
				return biarc;
			}

			return null;
		}

		private function getmaxdeviation(t1:Number,t2:Number,seg:QuadBezierSegment,center:Point, radius:Number):Number{
			// the newton raphson method approach is still not very reliable, for now sample 20 points along the curve
			var error:Number = 0;
			var e:Number;
			for(var i:int=0; i<20; i++){
				e = geterror(t1 + (i/20)*(t2-t1),seg,center,radius);
				if(e > error){
					error = e;
				}
			}
			return error;
		}

		private function geterror(t:Number, seg:QuadBezierSegment, center:Point, radius:Number):Number{
			var currentpoint:Point = seg.getPoint(t);

			var error:Number = Math.abs(Point.distance(currentpoint,center) - Math.abs(radius));

			return error;
		}

		// returns true if the given quad bezier is close enough to a line segment using the given tolerance, false otherwise
		// use Roger Willcocks bezier flatness criterion
		public function isflat(seg:QuadBezierSegment, tol:Number):Boolean{
			var tolerance:Number = 4*tol*tol;

			var ux:Number = 2*seg.c1.x - seg.p1.x - seg.p2.x;
			ux *= ux;

			var uy:Number = 2*seg.c1.y - seg.p1.y - seg.p2.y;
			uy *= uy;

			return (ux+uy <= tolerance);
		}

		//---------------------------------------------------------------
		//Checks for intersection of Segment if as_seg is true.
		//Checks for intersection of Line if as_seg is false.
		//Return intersection of Segment AB and Segment EF as a Point
		//Return null if there is no intersection
		//---------------------------------------------------------------
		public function lineIntersect(A:Point,B:Point,E:Point,F:Point,as_seg:Boolean=false):Point {
			var ip:Point;
			var a1:Number;
			var a2:Number;
			var b1:Number;
			var b2:Number;
			var c1:Number;
			var c2:Number;

			a1= B.y-A.y;
			b1= A.x-B.x;
			c1= B.x*A.y - A.x*B.y;
			a2= F.y-E.y;
			b2= E.x-F.x;
			c2= F.x*E.y - E.x*F.y;

			var denom:Number=a1*b2 - a2*b1;
			if (denom == 0) {
				return null;
			}
			ip=new Point();
			ip.x=(b1*c2 - b2*c1)/denom;
			ip.y=(a2*c1 - a1*c2)/denom;

			//---------------------------------------------------
			//Do checks to see if intersection to endpoints
			//distance is longer than actual Segments.
			//Return null if it is with any.
			//---------------------------------------------------
			if(as_seg){
				if(Math.pow(ip.x - B.x, 2) + Math.pow(ip.y - B.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
				   return null;
				}
				if(Math.pow(ip.x - A.x, 2) + Math.pow(ip.y - A.y, 2) > Math.pow(A.x - B.x, 2) + Math.pow(A.y - B.y, 2))
				{
				   return null;
				}

				if(Math.pow(ip.x - F.x, 2) + Math.pow(ip.y - F.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
				   return null;
				}
				if(Math.pow(ip.x - E.x, 2) + Math.pow(ip.y - E.y, 2) > Math.pow(E.x - F.x, 2) + Math.pow(E.y - F.y, 2))
				{
				   return null;
				}
			}

			if(isNaN(ip.x) || isNaN(ip.y)){
				return null;
			}

			return ip;
		}

		public override function reverse():*{
			var newbezier:QuadBezierSegment = new QuadBezierSegment(p2,p1,c1);
			return newbezier;
		}

	}
}