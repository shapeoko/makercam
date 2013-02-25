package com.partkart{
	import flash.geom.Point;
	import fl.motion.BezierSegment;

	public class CubicBezierSegment extends Segment{

		public var c1:Point;
		public var c2:Point;

		private var seglist:Array;

		public function CubicBezierSegment(point1:Point, point2:Point, control1:Point, control2:Point):void{
			super(point1, point2);

			c1 = control1;
			c2 = control2;
		}

		public function linearize(circle:Boolean = false):Array{

			seglist = new Array();
			seglist.push(this);

			if(circle == true){
				inflectiondivide(this, Global.tolerance);
			}
			else{
				//subdivide(this, Global.tolerance, 0.5);
				loopdivide(circle);
			}

			return seglist;
		}

		// flash's recursion stack is limited, we use loops instead
		private function loopdivide(circle:Boolean):void{
			var dividelist:Array = seglist.slice();
			while(dividelist.length > 0){

				while(dividelist.length > 0 && !(dividelist[0] is CubicBezierSegment)){
					dividelist.shift();
				}

				if(dividelist.length == 0){
					return;
				}

				var seg:CubicBezierSegment = dividelist[0];

				var re:Array = subdivide(seg,Global.tolerance, 0.5, circle);
				if(re && re.length == 2){
					dividelist.splice(0,1,re[0],re[1]);
				}
				else{
					dividelist.shift();
				}
			}
		}

		// to "normalize" the cubic bezier segment, we must first subdivide it at its inflection point, if any exists
		// this is mostly to improve the accuracy of our arc fitting algorithm
		// for simplicity, we will assume that any resulting subdivisions do not have inflection points
		private function inflectiondivide(seg:CubicBezierSegment, tol:Number):void{

			// inflection point detection is simply a quadratic root finding problem (at^2 + bt + c = 0)
			var ax:Number = -p1.x + 3*(c1.x-c2.x) + p2.x;
			var ay:Number = -p1.y + 3*(c1.y-c2.y) + p2.y;

			var bx:Number = 3*(p1.x - 2*c1.x + c2.x);
			var by:Number = 3*(p1.y - 2*c1.y + c2.y);

			var cx:Number = 3*(c1.x-p1.x);
			var cy:Number = 3*(c1.y-p1.y);

			var dx:Number = p1.x;
			var dy:Number = p1.y;

			var a:Number = 6*(ay*bx - ax*by);
			var b:Number = 6*(ay*cx - ax*cy);
			var c:Number = 2*(by*cx - bx*cy);

			var roots:Array = BezierSegment.getQuadraticRoots(a,b,c);

			if(!roots || roots.length == 0){
				loopdivide(true);
				//subdivide(seg, tol, 0.5, true);
				return;
			}
			else{
				// filter out roots that are not within [0,1]
				if(roots.length > 1){
					if(roots[1] <= 0 || roots[1] >= 1){
						roots.pop();
					}
				}
				if(roots.length > 0){
					if(roots[0] <= 0 || roots[0] >= 1){
						roots.shift();
					}
				}

				var t:Number;

				if(roots.length == 0){
					//subdivide(seg, tol, 0.5, true);
					loopdivide(true);
					return;
				}
				else if(roots.length == 1){
					t = roots[0];
				}
				// if two correct roots remain, choose the one closest to 0.5
				else if(roots.length > 1){
					var dis1:Number = Math.abs(roots[0]-0.5);
					var dis2:Number = Math.abs(roots[1]-0.5);
					if(dis1 <= dis2){
						t = roots[0];
					}
					else{
						t = roots[1];
					}
				}

				// subdivide at t
				subdivide(seg, tol, t, true);
				loopdivide(true);
			}
		}

		// recursively subdivide bezier segment to within the given tolerance
		// using de Casteljau subdivision
		private function subdivide(seg:CubicBezierSegment, tol:Number, t:Number, circle:Boolean = false):Array{

			// only use biarc approximation when the segment has been inflection divided
			if(seglist.length > 1 && circle == true){
				var biarc:Biarc = isbiarc(seg, tol);
				if(biarc){
					// approximate with biarc
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
			var mid2:Point = new Point(seg.c2.x+(seg.p2.x-seg.c2.x)*t, seg.c2.y+(seg.p2.y-seg.c2.y)*t);

			var mid3:Point = new Point(seg.c1.x+(seg.c2.x-seg.c1.x)*t, seg.c1.y+(seg.c2.y-seg.c1.y)*t);

			var mida:Point = new Point(mid1.x+(mid3.x-mid1.x)*t,mid1.y+(mid3.y-mid1.y)*t);
			var midb:Point = new Point(mid3.x+(mid2.x-mid3.x)*t,mid3.y+(mid2.y-mid3.y)*t);

			var midx:Point = new Point(mida.x+(midb.x-mida.x)*t,mida.y+(midb.y-mida.y)*t);

			if(t != 0.5){
				trace(midx.x, midx.y);
			}

			/*var bezier:BezierSegment = new BezierSegment(seg.p1,seg.c1,seg.c2,seg.p2);
			var midpoint = bezier.getValue(t);*/

			var seg1:CubicBezierSegment = new CubicBezierSegment(seg.p1,midx,mid1,mida);
			var seg2:CubicBezierSegment = new CubicBezierSegment(midx,seg.p2,midb,mid2);

			seglist.splice(seglist.indexOf(seg),1,seg1,seg2);


			return new Array(seg1,seg2);
			//subdivide(seg1, tol, 0.5, circle);
			//subdivide(seg2, tol, 0.5, circle);
			//}
		}

		private function isbiarc(seg:CubicBezierSegment, tol:Number):Biarc{
			var intersect:Point = lineIntersect(seg.p1,seg.c1,seg.p2,seg.c2);

			if(intersect == null){
				return null;
			}

			var biarc:Biarc = new Biarc(seg.p1, intersect, seg.p2);

			// limit max radius (some machine controllers limit this radius)
			var radiuslimit:Number = 400;
			if(Global.unit == 'cm'){
				radiuslimit *= 2.54;
			}

			/*if(biarc == null || isNaN(biarc.r1) || isNaN(biarc.r2) || Math.abs(biarc.r1) > radiuslimit || Math.abs(biarc.r2) > radiuslimit){
				return null;
			}*/
			if(biarc == null || isNaN(biarc.r1) || isNaN(biarc.r2)){
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

		/*private function getmaxdeviation(t:Number,seg:CubicBezierSegment,center:Point, radius:Number):Number{
			// use newton's method to find t at which radial deviation is maximum, then return that maximum deviation

			// first get the coefficients of the parameterized cubic equation (at^3 + bt^2 + ct^ + d)
			var ax:Number = -seg.p1.x + 3*(seg.c1.x-seg.c2.x) + seg.p2.x;
			var ay:Number = -seg.p1.y + 3*(seg.c1.y-seg.c2.y) + seg.p2.y;

			var bx:Number = 3*(seg.p1.x - 2*seg.c1.x + seg.c2.x);
			var by:Number = 3*(seg.p1.y - 2*seg.c1.y + seg.c2.y);

			var cx:Number = 3*(seg.c1.x-seg.p1.x);
			var cy:Number = 3*(seg.c1.y-seg.p1.y);

			var dx:Number = seg.p1.x;
			var dy:Number = seg.p1.y;

			// and now values for the first derivative

			var ax1:Number = 3*ax; var ay1:Number = 3*ay;
			var bx1:Number = 2*bx; var by1:Number = 2*by;
			var cx1:Number = cx; var cy1:Number = cy;

			// and the second derivative

			var ax2:Number = 2*ax1; var ay2:Number = 2*ay1;
			var bx2:Number = bx1; var by2:Number = by1;

			var bezier:BezierSegment = new BezierSegment(seg.p1,seg.c1,seg.c2,seg.p2);

			var currentpoint:Point;

			var q:Point;
			var q1:Point;
			var q2:Point;

			var f:Number;
			var f1:Number;

			// first use bisection to determine whether root exists

			currentpoint = bezier.getValue(0);

			q = new Point(currentpoint.x-center.x,currentpoint.y-center.y);
			q1 = new Point(cx1,cy1);

			var temp1f:Number = q.x*q1.x + q.y*q1.y;

			currentpoint = bezier.getValue(1);

			q = new Point(currentpoint.x-center.x,currentpoint.y-center.y);
			q1 = new Point(ax1+bx1+cx1,ay1+by1+cy1);

			var temp2f:Number = q.x*q1.x + q.y*q1.y;

			if(temp1f/Math.abs(temp1f) == temp2f/Math.abs(temp2f)){
				// if the sign does not change between t=0 and t=1, assume that there is no root.
				return geterror(t, seg, center, radius);
			}

			var t1:Number = 0;
			var i:int = 0;
			f = 1;

			while(f > 0.01 && i<100 && !isNaN(t)){
				currentpoint = bezier.getValue(t);

				q = new Point(currentpoint.x-center.x,currentpoint.y-center.y);
				q1 = new Point(ax1*Math.pow(t,2)+bx1*t+cx1,ay1*Math.pow(t,2)+by1*t+cy1);
				q2 = new Point(ax2*t+bx2,ay2*t+by2);

				f = q.x*q1.x + q.y*q1.y;
				f1 = (q1.x-center.x)*q2.x + (q1.y-center.y)*q2.y;

				t = t - f/f1;

				i++;
			}

			if(t >= 1 || t<=0){
				t = 0.5;
			}

			return geterror(t, seg, center, radius);
		}*/

		private function getmaxdeviation(t1:Number,t2:Number,seg:CubicBezierSegment,center:Point, radius:Number):Number{
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

		private function geterror(t:Number, seg:CubicBezierSegment, center:Point, radius:Number):Number{
			var bezier:BezierSegment = new BezierSegment(seg.p1,seg.c1,seg.c2,seg.p2);
			var currentpoint:Point = bezier.getValue(t);

			var error:Number = Math.abs(Point.distance(currentpoint,center) - Math.abs(radius));

			return error;
		}

		// returns true if the given cubic bezier is close enough to a line segment using the given tolerance, false otherwise
		// use Roger Willcocks bezier flatness criterion
		public function isflat(seg:CubicBezierSegment, tol:Number):Boolean{
			var tolerance:Number = 16*tol*tol;

			var ux:Number = 3*seg.c1.x - 2*seg.p1.x - seg.p2.x;
			ux *= ux;

			var uy:Number = 3*seg.c1.y - 2*seg.p1.y - seg.p2.y;
			uy *= uy;

			var vx:Number = 3*seg.c2.x - 2*seg.p2.x - seg.p1.x;
			vx *= vx;

			var vy:Number = 3*seg.c2.y - 2*seg.p2.y - seg.p1.y;
			vy *= vy;

			if (ux < vx){
				ux = vx;
			}
			if (uy < vy){
				uy = vy;
			}

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
			var newbezier:CubicBezierSegment = new CubicBezierSegment(p2,p1,c2,c1);
			return newbezier;
		}

	}
}