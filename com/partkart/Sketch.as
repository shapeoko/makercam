package com.partkart{
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.Point;
	
	public class Sketch extends Sprite{
		
		private var pointlist:Array = new Array(); // raw sketch input
		
		private var angles:Array = new Array();
		private var lengthlist:Array = new Array();
		private var curvature:Array = new Array();
		
		private var timelist:Array = new Array();
		private var speedlist:Array = new Array();
		
		private var outputlist:Array = new Array();
		private var bezierlist:Array = new Array();
		
		private var avdis:Number = 0;		
		
		public function Sketch(p:Point):void{
			graphics.lineStyle(1,0x2c6b8f, 1, true, LineScaleMode.NONE);
			graphics.moveTo(p.x, p.y);
		}
		
		public function addPoint(p:Point):void{
			pointlist.push(p);
		}
		
		public function addTime(n:int):void{
			timelist.push(n);
		}
		
		public function lineTo(p:Point):void{
			graphics.lineTo(p.x, p.y);
		}
		
		public function getPath():Path{
			if(pointlist.length < 5){ // prevents short/tiny segments and random user clicks
				return null;
			}
			
			processInput();
			
			if(outputlist.length > 1){
				var path:Path = new Path();
				var s:Segment;
				var b:Array;
				
				var patharray:Array = new Array(); // contains an array of already added linear segments
				for(var i:int = 0; i<outputlist.length - 1; i++){
					s = new Segment(outputlist[i],outputlist[i+1]);
					patharray.push(s);				
				}
				
				var templen:int = patharray.length;
				for(i=0; i<templen; i++){
					s = patharray[i];
					for(var j:int = 0; j<bezierlist.length; j++){
						b = bezierlist[j];
						if(s.p1.equals(b[0].p1) && s.p2.equals(b[b.length-1].p2)){
							b[0].p1 = s.p1;
							b[b.length-1].p2 = s.p2;
							patharray.splice(i,1,b);
						}
						else if(s.p1.equals(b[b.length-1].p2) && s.p2.equals(b[0].p1)){
							b[b.length-1].p2 = s.p1;
							b[0].p1 = s.p2;
							patharray.splice(i,1,b);
						}
					}
				}
				
				// handle the case where only a single segment with 0 length is returned
				if(patharray.length == 0){
					return null;
				}
				
				var isnull:Boolean = true;
				
				for(i=0; i<patharray.length; i++){
					if(patharray[i] is Segment && !patharray[i].p1.equals(patharray[i].p2)){
						isnull = false;
						break;
					}
					else if(patharray[i] is Array){
						for(j=0; j<patharray[i].length; j++){
							if(patharray[i][j] is Segment && !patharray[i][j].p1.equals(patharray[i][j].p2)){
								isnull = false;
								break;
							}
						}
					}
				}
				
				if(isnull){
					return null;
				}
				
				for(i=0; i<patharray.length; i++){
					if(patharray[i] is Segment){
						path.addSegment(patharray[i]);
					}
					else if(patharray[i] is Array){
						for(j=0; j<patharray[i].length; j++){
							path.addSegment(patharray[i][j]);
						}
					}
				}
				
				return path;
			}
			return null;
		}
		
		private function processInput():void{
			
			invertY();
			
			// add first point 
			outputlist.push(pointlist[0]);
			
			for(var i:int = 0; i<pointlist.length - 1; i++){
				avdis += Point.distance(pointlist[i], pointlist[i+1]);
			}
			
			avdis = avdis/(pointlist.length-1);
			trace("avdis: ", avdis);
			
			var a:Number;
			for(i = 0; i<pointlist.length; i++){
				a = getAngle(i);
				angles.push(a);
			}
			
			processLength();
			processSpeed();
			
			processCurvature();
			
			addSpeed();
			
			processCurvatureFit();
			
			// add last point 
			outputlist.push(pointlist[pointlist.length - 1]);
			
			proximityFilter();
			
			beautify();
			
			fitBeziers();
			
			scaleOutput();
			
			remDoubles();
			
			trace("done");
		}
		
		// turns left hand coordinates to right-hand coordinates
		private function invertY():void{
			for each(var p in pointlist){
				p.y = -p.y;
			}
		}
		
		// use parallelism and perpendicularity to arrange output points in a pleasant manner, snap to grid and other points
		private function beautify():void{
			
			var anglist:Array = new Array();
			
			// first gather a list of angles between all output points
			for(var i:int=0; i<outputlist.length-1; i++){
				var angobj = new Object();
				var angle = Math.atan2(outputlist[i+1].y - outputlist[i].y, outputlist[i+1].x - outputlist[i].x)*180/Math.PI;
				
				/*var angle:Number;
				
				var a2:Number = a1 + 180;
				var a3:Number = a1 - 180;
				
				if(Math.abs(a1) < Math.abs(a2) && Math.abs(a1) < Math.abs(a3)){
					angle = Math.abs(a1); // average angle in degrees
				}
				else if(Math.abs(a2) < Math.abs(a3)){
					angle = Math.abs(a2); // average angle in degrees
				}
				else{
					angle = Math.abs(a3); // average angle in degrees
				}*/
				
				angobj.angle = angle;
				angobj.p1 = outputlist[i];
				angobj.p2 = outputlist[i+1];
				
				anglist.push(angobj);
			}
			
			var grouplist:Array = new Array(); // now we group angle objects of similar angle
			
			// first construct a histogram of angular differences
			
			//var angdiff:Array = new Array();
			
			//anglist.sortOn("angle", Array.NUMERIC);
			
			/*if(anglist.length > 2){				
				for(i=1; i<anglist.length-1; i++){
					var diff:Number = angularDifference(anglist[i-1].angle, anglist[i].angle)+angularDifference(anglist[i].angle, anglist[i+1].angle);
					diff = diff/2;
					angdiff.push(diff);
				}
				
				var avdiff:Number = 0;
				
				for(i=0; i<angdiff.length; i++){
					avdiff += angdiff[i];
				}
				
				avdiff = avdiff/angdiff.length; // average difference between angles. This will serve as a normalizing parameter to filter out minimum diffs
				
				trace("angular difference: ",angdiff);
				
				
			}*/
			
			var anglelimit:Number = 6; // group angles that are within this limit (angle in degrees)
			
			for(i=0; i<anglist.length; i++){
				for(var j:int=0; j<anglist.length; j++){
					var tempang:Number = angularDifference(anglist[i].angle, anglist[j].angle);
					
					if(i != j && angularDifference(anglist[i].angle, anglist[j].angle) < anglelimit){
						// if they are close, place them in one group
						var group1:Array = findIn(grouplist, anglist[i]);
						var group2:Array = findIn(grouplist, anglist[j]);
						
						if(group1 == null && group2 == null){ // if neither is in a group, create a group
							var added:Boolean = false;
							for(var k:int=0; k<grouplist.length; k++){ // see if any existing groups are close enough
								if(getAverageAngularDifference(grouplist[k], anglist[i].angle) < anglelimit){
									grouplist[k].push(anglist[i]);
									grouplist[k].push(anglist[j]);
									added = true;
									break;
								}
							}
							if(added == false){
								var group:Array = new Array();
								group.push(anglist[i]);
								group.push(anglist[j]);
								grouplist.push(group);
							}
						}
						else if(group1 != null && group2 == null){
							group1.push(anglist[j]);
						}
						else if(group2 != null && group1 == null){
							group2.push(anglist[i]);
						}
					}
				}
			}
			
			// snap to grid
			for(i=0; i<grouplist.length; i++){
				if(getAverageAngularDifference(grouplist[i], 0) < anglelimit){
					for(j=0; j<grouplist[i].length; j++){
						grouplist[i][j].angle = 0;
					}
				}
				else if(getAverageAngularDifference(grouplist[i], 90) < anglelimit){
					for(j=0; j<grouplist[i].length; j++){
						grouplist[i][j].angle = 90;
					}
				}
				else{
					grouplist[i].sortOn("angle", Array.NUMERIC);
					var median:Number = grouplist[i][Math.floor((grouplist[i].length-1)/2)].angle;
					for(j=0; j<grouplist[i].length; j++){
						grouplist[i][j].angle = median;
					}
				}
			}
			
			trace(grouplist);
			
			// now we implement the angle changes and write it back to the outputlist
			
			for(i=0; i<anglist.length-1; i++){
				var a:Object = anglist[i];
				var b:Object = anglist[i+1];
				
				var len1:Number = Point.distance(a.p1,a.p2)/2;
				var len2:Number = Point.distance(b.p1,b.p2)/2;
				
				var mid1:Point = new Point((a.p1.x + a.p2.x)/2, (a.p1.y + a.p2.y)/2);
				var mid2:Point = new Point((b.p1.x + b.p2.x)/2, (b.p1.y + b.p2.y)/2);
				
				var ext1:Point = new Point(mid1.x + len1*Math.cos((a.angle*Math.PI)/180), mid1.y + len1*Math.sin((a.angle*Math.PI)/180));
				var ext2:Point = new Point(mid2.x + len2*Math.cos((b.angle*Math.PI)/180), mid2.y + len2*Math.sin((b.angle*Math.PI)/180));
				
				var intersect:Point = Global.lineIntersect(mid1, ext1, mid2, ext2);
				
				if(intersect != null && !isNaN(intersect.x) && !isNaN(intersect.y) && onScreen(intersect)){
					
					if(i==0){
						var ext4:Point = new Point(mid1.x - (ext1.x-mid1.x), mid1.y - (ext1.y - mid1.y));
						if(Point.distance(intersect,ext1) < Point.distance(intersect, ext4)){
							a.p1.x = ext4.x;
							a.p1.y = ext4.y;
						}
						else{
							a.p1.x = ext1.x;
							a.p1.y = ext1.y;
						}
					}
					
					// copy new values to original datastructures
					a.p2.x = intersect.x;
					a.p2.y = intersect.y;
					
					var ext3:Point = new Point(mid2.x - (ext2.x-mid2.x), mid2.y - (ext2.y - mid2.y));
					
					if(Point.distance(intersect,ext2) < Point.distance(intersect, ext3)){
						b.p2.x = ext3.x;
						b.p2.y = ext3.y;
					}
					else{
						b.p2.x = ext2.x;
						b.p2.y = ext2.y;
					}
				}
										   
			}
			
			
		}
		
		private function onScreen(intersect:Point):Boolean{
			// returns true if the intersect point is within a box twice the size of the screen
			// this is to eliminate extreme values
			if(intersect.x > Global.docwidth*2 || intersect.x < -1*Global.docwidth){
				return false;
			}
			else if(intersect.y > Global.docheight*2 || intersect.y < -1*Global.docheight){
				return false;
			}
			return true;
		}
		
		private function findIn(list:Array, a:Object):Array{
			for(var i:int=0; i<list.length; i++){
				if(list[i].indexOf(a) != -1){
					return list[i];
				}
			}
			return null;
		}
		
		private function getAverageAngularDifference(a:Array, b:Number):Number{
			var av:Number = 0;
			for(var i:int=0; i<a.length; i++){
				av += angularDifference(a[i].angle, b);
			}
			av = av/a.length;
			
			return av;
		}
		
		private function angularDifference(a:Number, b:Number):Number{
			var diff:Number = a-b;
			
			var dlist:Array = new Array(); // list of possible angular configurations
			
			dlist.push(Math.abs(diff));
			dlist.push(Math.abs(diff+180));
			dlist.push(Math.abs(diff-180));
			dlist.push(Math.abs(diff-360));
			dlist.push(Math.abs(diff+360));
			
			var smallest:Number = 90;
			
			for(var i:int=0; i < dlist.length; i++){
				if(dlist[i] < smallest){
					smallest = dlist[i];
				}
			}
			
			return smallest; // return lowest angular difference;
		}
		
		private function signedAngularDifference(a:Number, b:Number):Number{
			var diff:Number = a-b;
			
			var dlist:Array = new Array(); // list of possible angular configurations
			
			dlist.push(Math.abs(diff));
			dlist.push(Math.abs(diff+180));
			dlist.push(Math.abs(diff-180));
			dlist.push(Math.abs(diff-360));
			dlist.push(Math.abs(diff+360));
			
			dlist.sort();
			
			return dlist[0]; // return lowest angular difference;
		}
		
		private function scaleOutput():void{
			for(var i:int = 0; i<outputlist.length; i++){
				if(outputlist[i] is Point){					
					outputlist[i] = new Point(outputlist[i].x/Global.zoom, outputlist[i].y/Global.zoom);
				}
			}
		}
		
		private function getAngle(index:int):Number{
			// get angle by averaging the angle of the line that passes through previous and next points
			// to do: use orthogonal regression instead, to find the angle of the line of best fit
			var angle:Number = 0;
			var limit:int = -1*avdis + 11; // vary sampling limit based on average segment length, numbers experimentally determined
			
			if(limit < 4){
				limit = 4;
			}
			
			var p1:Point;
			var p2:Point;
			
			for(var i:int = 1; i<limit; i++){
				if(pointlist[index-i]){
					p1 = pointlist[index-i];
				}
				else{
					p1 = pointlist[index];
				}
				
				if(pointlist[index+i]){
					p2 = pointlist[index+i];
				}
				else{
					p2 = pointlist[index];
				}
				var a1:Number = Math.atan2(p2.y - p1.y, p2.x - p1.x)*180/Math.PI;
				angle += angularDifference(a1,0);
				//var a2:Number = a1 + 180;
				//var a3:Number = a1 - 180;
				/*
				if(Math.abs(a1) < Math.abs(a2) && Math.abs(a1) < Math.abs(a3)){
					angle += Math.abs(a1); // average angle in degrees
				}
				else if(Math.abs(a2) < Math.abs(a3)){
					angle += Math.abs(a2); // average angle in degrees
				}
				else{
					angle += Math.abs(a3); // average angle in degrees
				}*/
			}
			
			angle = angle/(limit-1);
			
			return angle;
		}
		
		private function processLength():void{ // gets a list of the segment lengths of the pointlist
			for(var i:int=0; i<pointlist.length-1; i++){
				lengthlist.push(Point.distance(pointlist[i],pointlist[i+1]));
			}
			
		}
		
		private function processCurvature():void{ // combine angle and length data into curvature, where curvature = dA/dL
			for(var i:int=0; i<angles.length-1; i++){
				var c:Number = (angles[i+1]-angles[i])/lengthlist[i];
				var c1:Number = (angles[i+1]+angles[i])/lengthlist[i];
				if(Math.abs(c1) < Math.abs(c)){
					curvature.push(Math.abs(c1));
				}
				else{
					curvature.push(Math.abs(c));
				}
			}
		}
		
		private function processCurvatureFit():void{
			// generate output list based on curvature data
			// use averaging to determine position of feature points
			
			var av:Number = 0;
			
			for(var i:int=0; i<curvature.length; i++){
				av += curvature[i];
			}
			
			//av = 0.9*Math.pow((av/curvature.length),2);
			//av = 2.8*av/curvature.length;
			av = 2.5*av/curvature.length;
			
			// find peaks
			var entered:Boolean = false; // entered a peak
			var peak:Object = {};
			for(i=0; i<curvature.length; i++){
				if(!entered && curvature[i] > av){
					entered = true;
					peak.num = curvature[i];
					peak.index = i;
				}
				if(entered){
					if(curvature[i] > peak.num){
						peak.num = curvature[i];
						peak.index = i;
					}
					if(curvature[i] < av){
						entered = false;
						outputlist.push(pointlist[peak.index]);
						peak.num = 0;
					}
				}
			}
			
		}
		
		private function proximityFilter():void{
			// filter out points within 3 pixels of eachother
			if(outputlist.length > 2){
				var newlist:Array = new Array();
				var radius:int = 5;
				var skipnext:Boolean = false;
				for(var i:int=0; i<outputlist.length - 1; i++){
					if(skipnext == false){
						newlist.push(outputlist[i]);
					}
					else{
						skipnext = false;
					}
					if(Math.abs(outputlist[i].x - outputlist[i+1].x) < radius && Math.abs(outputlist[i].y - outputlist[i+1].y) < radius){
						skipnext = true;
					}
				}
				
				if(skipnext == false){
					newlist.push(outputlist[outputlist.length-1]);
				}
				
				outputlist = newlist;
			}
		}
		
		// timing based method starts here
		
		private function processSpeed():void{
			for(var i:int=0; i<pointlist.length-1; i++){
				speedlist.push(Number(timelist[i]/(lengthlist[i] + 2)));
			}
			
			var av:Number = 0;
			
			for(i=0; i<speedlist.length; i++){
				av += speedlist[i];
			}
			
			av = av/speedlist.length;
			
			for(i=0; i<speedlist.length; i++){
				speedlist[i] = speedlist[i]/(0.5*av);
			}
			//trace(speedlist);
		}
		
		private function addSpeed():void{
			for(var i:int=0; i<pointlist.length-1; i++){
				curvature[i] = curvature[i] + speedlist[i];
			}
		}
		
		private function fitBeziers():void{
			// detect when the user means to draw a bezier curve, and replace line with curve
			
			var prevind:int = 0;
			var len:Number = 0;
			
			var error:Number = 0;
			var errorlist:Array = new Array();
			var tempind:int = 0;
			
			//var errorlimit:Number = -0.03*avdis + 1.3; // vary the error limit based on drawing scale, this is to account for higher error rates when pointlist density is high
			
			var errorlimit:Number = -0.01*avdis + 1.3;
			
			//var errorlimit:Number = 1.3;
			
			if(errorlimit < 1.07){
				errorlimit = 1.07;
			}
			
			var templen:int = outputlist.length;
			for(var i:int = 1; i<templen; i++){
				tempind = prevind;
				for(var j:int = prevind; j<pointlist.length; j++){
					if(outputlist[i].equals(pointlist[j])){
						prevind = j;
						break;
					}
					if(j < lengthlist.length){
						len += lengthlist[j];
					}
				}
				
				var euclid:Number = Point.distance(outputlist[i], outputlist[i-1]); // euclid = euclidean distance between feature points
				if(isNaN(euclid) || euclid == 0){
					euclid = 0.0001;
				}
				
				error = len/euclid;
				len = 0;
				
				if(error > errorlimit){
					// error too high, use bezier method to interpolate between point o[i] and o[i-1]
					bezierlist.push(bezierRecurs(tempind,prevind));
				}
				trace("error: ", error);
			}
			
		}
		
		private function remDoubles():void{
			for(var i:int=0; i<bezierlist.length; i++){
				var b:Array = bezierlist[i];
				
				for(var j:int=0; j<b.length; j++){
					for(var k:int=0; k<b.length; k++){
						if(b[j].p1.equals(b[k].p2) && b[j].p1 != b[k].p2){
							b[k].p2 = b[j].p1;
						}
					}
				}
			}
		}
		
		private function bezierRecurs(ind1:int, ind2:int, smooth:int = 0):Array{
			
			// recursively subdivide a segment into beziers until the specified tolerances have been met
			
			var returnarray = new Array();
			var limit:int;
			
			limit = (ind2 - ind1)/3;
			
			var c1:Point = new Point(pointlist[ind1].x/Global.zoom, pointlist[ind1].y/Global.zoom);
			var c2:Point = new Point(pointlist[ind2].x/Global.zoom, pointlist[ind2].y/Global.zoom);
			
			var c1b:Point = new Point(0,0);
			var c2b:Point = new Point(0,0);
			
			var c1c:Point = new Point(0,0);
			var c2c:Point = new Point(0,0);
			
			var lim1:int = 0;
			var lim2:int = 0;
			
			var i:int = 0;
			
			if(ind2 - ind1 < 6){
				var avind:int = 0;
				avind = Math.floor((ind2+ind1)/2);
				returnarray.push(new QuadBezierSegment(c1,c2, new Point(pointlist[avind].x/Global.zoom, pointlist[avind].y/Global.zoom)));
				return returnarray;
			}
			
			switch(smooth){
				case 0:
					for(i=1; i<=limit; i++){
						if(pointlist[ind1+i]){
							c1b = c1b.add(pointlist[ind1+i]);
							lim1++;
						}
						if(pointlist[ind2-i]){
							c2b = c2b.add(pointlist[ind2-i]);
							lim2++;
						}
					}
				break;
				
				case 1:
					for(i=1; i<=limit; i++){
						if(pointlist[ind2-i]){
							c2b = c2b.add(pointlist[ind2-i]);
							lim2++;
						}
					}
					
					for(i=1; i<=limit; i++){
						if(pointlist[ind1+i] && pointlist[ind1-i]){
							c1b = c1b.add(pointlist[ind1+i]);
							c1c = c1c.add(pointlist[ind1-i]);
							lim1++;
						}
					}
				break;
				
				case 2:
					for(i=1; i<=limit; i++){
						if(pointlist[ind1+i]){
							c1b = c1b.add(pointlist[ind1+i]);
							lim1++;
						}
					}
					
					for(i=1; i<=limit; i++){
						if(pointlist[ind2-i] && pointlist[ind2+i]){
							c2b = c2b.add(pointlist[ind2-i]);
							c2c = c2c.add(pointlist[ind2+i]);
							lim2++;
						}
					}
				break;
				
				case 3:
					for(i=1; i<=limit; i++){
						if(pointlist[ind1+i] && pointlist[ind1-i]){
							c1b = c1b.add(pointlist[ind1+i]);
							c1c = c1c.add(pointlist[ind1-i]);
							lim1++;
						}
						if(pointlist[ind2-i] && pointlist[ind2+i]){
							c2b = c2b.add(pointlist[ind2-i]);
							c2c = c2c.add(pointlist[ind2+i]);
							lim2++;
						}
					}
				break;
			}
			
			c1b.x = c1b.x/(lim1*Global.zoom);
			c1b.y = c1b.y/(lim1*Global.zoom);
			
			c2b.x = c2b.x/(lim2*Global.zoom);
			c2b.y = c2b.y/(lim2*Global.zoom);
			
			c1c.x = c1c.x/(lim1*Global.zoom);
			c1c.y = c1c.y/(lim1*Global.zoom);
			
			c2c.x = c2c.x/(lim2*Global.zoom);
			c2c.y = c2c.y/(lim2*Global.zoom);
			
			var control:Point = new Point(0,0);
			var con1:Point;
			var con2:Point;
			
			var con3:Point;
			var con4:Point;
			
			var conlim:int = 0;
			
			switch(smooth){
				case 0: // no smoothing
					control = Global.lineIntersect(c1,c1b,c2,c2b);
				break;
				
				case 1: // smooth one end
					con1 = Global.lineIntersect(c1,c1b,c2,c2b);
					con2 = Global.lineIntersect(c1,c1c,c2,c2b);
					
					if(con1){
						control = control.add(con1);
						conlim++;
					}
					if(con2){
						control = control.add(con2);
						conlim++;
					}
					if(con1 || con2){
						control.x = control.x/conlim;
						control.y = control.y/conlim;
					}
					else{
						control = new Point(0,0);
						control.x = pointlist[Math.floor((ind1+ind2)/2)].x/Global.zoom;
						control.y = pointlist[Math.floor((ind1+ind2)/2)].y/Global.zoom;
					}
				break;
				
				case 2: // smooth the other end
					con1 = Global.lineIntersect(c1,c1b,c2,c2b);
					con2 = Global.lineIntersect(c1,c1b,c2,c2c);
					
					if(con1){
						control = control.add(con1);
						conlim++;
					}
					if(con2){
						control = control.add(con2);
						conlim++;
					}
					if(con1 || con2){
						control.x = control.x/conlim;
						control.y = control.y/conlim;
					}
					else{
						control = new Point(0,0);
						control.x = pointlist[Math.floor((ind1+ind2)/2)].x/Global.zoom;
						control.y = pointlist[Math.floor((ind1+ind2)/2)].y/Global.zoom;
					}
				break;
				
				case 3: // smooth both ends
					con1 = Global.lineIntersect(c1,c1b,c2,c2b);
					con2 = Global.lineIntersect(c1,c1c,c2,c2b);
					
					con3 = Global.lineIntersect(c1,c1b,c2,c2b);
					con4 = Global.lineIntersect(c1,c1b,c2,c2c);
					
					if(con1){
						control = control.add(con1);
						conlim++;
					}
					if(con2){
						control = control.add(con2);
						conlim++;
					}
					if(con3){
						control = control.add(con3);
						conlim++;
					}
					if(con4){
						control = control.add(con4);
						conlim++;
					}
					if(con1 || con2 || con3 || con4){
						control.x = control.x/conlim;
						control.y = control.y/conlim;
					}
					else{
						control = new Point(0,0);
						control.x = pointlist[Math.floor((ind1+ind2)/2)].x/Global.zoom;
						control.y = pointlist[Math.floor((ind1+ind2)/2)].y/Global.zoom;
					}
				break;
			}
			
			if(!control){
				control = new Point(0,0);
				control.x = pointlist[Math.floor((ind1+ind2)/2)].x/Global.zoom;
				control.y = pointlist[Math.floor((ind1+ind2)/2)].y/Global.zoom;
			}
			
			trace(control);

			var bezier:QuadBezierSegment = new QuadBezierSegment(c1,c2,control);
			
			// calculate curve error
			var starttime:Number = 0;
			var timelimit:int = 2*Math.abs((ind2-ind1)); // how many points along the bezier curve to search for the closest point
			// this is grossly inefficient, consider revising in the future
			
			var lowest:Number;
			var temp:Number;
			var total:Number = 0;
			var av:Number;
			
			var currentpoint:Point;
			
			for(i=ind1+1; i<ind2; i++){
				starttime = (i-ind1)/(ind2-ind1);
				currentpoint = new Point(pointlist[i].x/Global.zoom, pointlist[i].y/Global.zoom);
				lowest = Point.distance(bezier.getPoint(starttime), currentpoint);
				
				for(var j:int = 0; j<timelimit; j++){
					temp = Point.distance(bezier.getPoint((1/timelimit)*j), currentpoint);
					if(temp < lowest){
						lowest = temp;
					}
				}
				total += lowest;
			}
			
			av = total/(ind2-ind1-1);
			
			if(av > .17){
				// curve approximation not good enough, recursively subdivide and approximate
				switch(smooth){
					case 0:
						returnarray = returnarray.concat(bezierRecurs(ind1, ind1 + (ind2-ind1)/2, 2));
						returnarray = returnarray.concat(bezierRecurs(ind1 + (ind2-ind1)/2, ind2, 1));
					break;
					
					case 1:
						returnarray = returnarray.concat(bezierRecurs(ind1, ind1 + (ind2-ind1)/2, 3));
						returnarray = returnarray.concat(bezierRecurs(ind1 + (ind2-ind1)/2, ind2, 1));
					break;
					
					case 2:
						returnarray = returnarray.concat(bezierRecurs(ind1, ind1 + (ind2-ind1)/2, 2));
						returnarray = returnarray.concat(bezierRecurs(ind1 + (ind2-ind1)/2, ind2, 3));
					break;
					
					case 3:
						returnarray = returnarray.concat(bezierRecurs(ind1, ind1 + (ind2-ind1)/2, 3));
						returnarray = returnarray.concat(bezierRecurs(ind1 + (ind2-ind1)/2, ind2, 3));
					break;
				}
			}
			else{
				returnarray.push(bezier);
			}
			return returnarray;
		}
		
		/*private function getPointDistance(p:Point,lineP1:Point, lineP2:Point){
			
			//get the normalized vector of the line
			var norm:Point = new Point(lineP2.x-lineP1.x,lineP2.y-lineP1.y);
			var mag:Number = Math.sqrt(norm.x*norm.x + norm.y*norm.y);
			norm.x/=mag;
			norm.y/=mag;
			
			//now project your point on the line
			var pointVector:Point = new Point(p.x-lineP1.x,p.y-lineP1.y);
			var dotProduct:Number = pointVector.x*norm.x + pointVector.y*norm.y;
			
			//get the point on the line closest to our point
			var newPoint:Point = new Point(norm.x*dotProduct + lineP1.x, norm.y*dotProduct + lineP1.y);
			
			//now get the distance between the points
			var minDist:Number = Math.sqrt(Math.pow(p.x-newPoint.x,2)+Math.pow(p.y-newPoint.y,2));
		}*/
	}
}