package com.partkart{
	import flash.geom.Point;
	
	public class Biarc{
		
		// a biarc is composed of two circular arcs that are tangential at their joint
		// a biarc is a good way of approximating bezier splines for cnc machining
		// as many controllers only accept curves in the form of G02 and G03 codes (circular motion)
		
		
		// each of the points the biarc travels through, p1 and p3 are endpoints of the bezier
		// p2 is the incenter of the bezier triangle
		
		public var p1:Point;
		public var p2:Point;
		public var p3:Point;
		
		// center points of each arc segment
		public var c1:Point;
		public var c2:Point;
		
		// radius values of each arc segment
		public var r1:Number;
		public var r2:Number;
		
		// error flag when the circle is too flat
		public var flat:Boolean = false;
		
		// the constructor takes the coordinates of a bezier triangle
		// note: pb != p2
		public function Biarc(pa:Point, pb:Point, pc:Point):void{
			p1 = pa;
			p3 = pc;
			
			p2 = incenter(pa,pb,pc);
			
			var t1:Point = pb.subtract(pa);
			
			// this is a property of the incenter biarc division method - that the tangent at the joint is
			// equal to the vector from pa to pc
			var t2:Point = pc.subtract(pa);
			
			var circ1:Array = arc(p1,p2,t1);
			var circ2:Array = arc(p2,p3,t2);
			
			r1 = circ1[0];
			c1 = circ1[1];
			
			r2 = circ2[0];
			c2 = circ2[1];
		}
		
		// returns the incenter point, given the bounding bezier triangle
		private function incenter(pa:Point, pb:Point, pc:Point):Point{
			var a:Number = Point.distance(pb,pc);
			var b:Number = Point.distance(pa,pc);
			var c:Number = Point.distance(pa,pb);
			
			var sum:Number = a+b+c;
			
			var x:Number = (a*pa.x + b*pb.x + c*pc.x)/sum;
			var y:Number = (a*pa.y + b*pb.y + c*pc.y)/sum;
			
			return new Point(x,y);
		}
		
		// calculates center and radius from 2 points and initial tangent vector
		private function arc(point1:Point, point2:Point, tangent:Point):Array{
			tangent.normalize(1);
			var x:Number = point2.x - point1.x;
			var y:Number = point2.y - point1.y;
			
			var r:Number = -(Math.pow(x,2)+Math.pow(y,2))/(2*(y*tangent.x-x*tangent.y));
			var center:Point = new Point(tangent.y*r + point1.x, -tangent.x*r + point1.y);
			
			return new Array(r,center);
		}
		
		public function getArcs():Array{
			
			var arc1:CircularArc = new CircularArc(p1,p2,c1,r1);
			var arc2:CircularArc = new CircularArc(p2,p3,c2,r2);
			
			return new Array(arc1,arc2);
		}
	}
}