package com.partkart{

	import flash.display.Sprite;
	import flash.utils.getTimer;
	import com.greenthreads.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Matrix;
	import com.tink.display.HitTest;

	public class Nest extends GreenThread{

		// the outer contour
		public var blank:Path;
		public var blankbitmap:BitmapData;

		// keep a reference to the original blank with no nest objects in it (for when we want to star over)
		private var blankoriginal:BitmapData;

		// the total area of the material blank, in user units (used to compute % material utilization)
		private var blankweight:Number;

		// nestbitmap is an exact copy of blankbitmap, except without the blank material
		// it is used to calculate the space taken up by the nest objects
		private var nestbitmap:BitmapData;

		// gap between each nest object
		private var gap:Number;

		// array of cutobjects to be nested (only cutobjects are supported, regular paths must be converted to profiles in order to use nest)
		public var cutlist:Array;

		// in the same order as cutlist, weightlist stores the "weights" of each nest object. The weight of each object is its area in user units (inch or cm)
		private var weightlist:Array;

		// marker for currently processing nest object
		private var current:int = 0;

		// marker for currently processing rotation
		private var currentrotation:Number = 0;

		private var objectlist:Array;

		// scaling factor between current blank size and ideal blank size (as bit as possible or Global.nestbitmapsize pix wide/high)
		public var scale:Number = 1;

		// number of angles to consider for each nest object
		private var divisions:int = 4;

		// object contains x,y coordinates, bitmap of best rotation angle
		private var bestangle:Object;

		// reference to the genetic algorithm
		private var ga:GeneticAlgorithm;

		// reference to the current individual that is being calculated
		private var currentindividual:Individual;

		// the fittest individual discovered thus far
		public var fittest:Individual;

		private var renderbitmap:Bitmap;

		// flag to indicate less than acceptable number of nest objects
		public var underlimit:Boolean = false;

		private var group:Boolean = true;
		private var groupprofile:Boolean = false;

		public function Nest(inputblank:Path, inputcutlist:Array, inputdivisions:int = 4, inputgap:Number = 0, inputgroup:Boolean = true, inputgroupprofile:Boolean = false):void{
			blank = inputblank;
			cutlist = inputcutlist;
			divisions = inputdivisions;
			gap = inputgap;
			group = inputgroup;
			groupprofile = inputgroupprofile;
		}

		override protected function initialize():void{
			// draw blanks for each cutpath - a blank is representative of the area taken up by the cut, including overcut
			for each(var cut:* in cutlist){
				cut.zeroOrigin();
				cut.drawNestBlank(0x000000, gap);
			}

			// merge overlapping cuts into a single object (we will treat these as individual units to be nested)
			if(group == true){
				for(var i:int=0; i<cutlist.length; i++){
					for(var j:int=0; j<cutlist.length; j++){
						if(!(cutlist[j] is ProfileCutObject) || (cutlist[j] is ProfileCutObject && groupprofile == true)){
							if(i != j && HitTest.complexHitTestObject(cutlist[i], cutlist[j])){
								cutlist[i].addChild(cutlist[j]);
								cutlist.splice(j,1);
								if(i >= j){
									i--;
								}
								j--;
							}
						}
					}
				}
			}

			// at least two is required for nesting
			if(cutlist.length < 2){
				underlimit = true;
				return;
			}

			// sort the cutlist - largest first
			cutlist.sort(sortarea);

			// calculate the weights of each nest object
			weightlist = new Array();
			for(i=0; i<cutlist.length; i++){
				var weight:Number = 0;
				var rect:Rectangle = cutlist[i].getBounds(this);
				var matrix:Matrix = new Matrix(1,0,0,1, -rect.x, -rect.y);

				var weightbitmap:BitmapData = new BitmapData(rect.width, rect.height, false, 0xFFFFFF);
				weightbitmap.draw(cutlist[i], matrix);

				// count number of black pixels
				var total:uint = 0;
				for(j = 0; j<weightbitmap.width; j++){
					for(var k:int = 0; k<weightbitmap.height; k++){
						if(weightbitmap.getPixel(j,k) == 0x000000){
							total++;
						}
					}
				}

				// turn total number of black pixels into weight in user units
				weight = total/(Global.zoom*Global.zoom);
				weightlist.push(weight);

				weightbitmap.dispose();
			}

			// draw the blank into a bitmap (we will just load it into a pocket cut object since it already has the drawing functions)
			var cutobject:PocketCutObject = new PocketCutObject();
			cutobject.pathlist = new Array(blank);
			addChild(cutobject);
			cutobject.drawNestBlank(0xffffff);

			// draw the blank into a bitmap (maximize Global.nestbitmapsize width or height)
			var region:Rectangle = cutobject.getBounds(this);
			var bitmapwidth:Number = region.width;
			var bitmapheight:Number = region.height;

			if(region.width > region.height){
				scale = Global.nestbitmapsize/region.width;
				bitmapwidth = Global.nestbitmapsize;
				bitmapheight = region.height*scale;
			}
			else{
				scale = Global.nestbitmapsize/region.height;
				bitmapwidth = region.width*scale;
				bitmapheight = Global.nestbitmapsize;
			}

			var trans:Matrix = new Matrix(scale,0,0,scale, -region.x*scale,-region.y*scale);

			blankbitmap = new BitmapData(region.width*scale,region.height*scale,false,0x000000);
			blankbitmap.draw(cutobject, trans);

			blankoriginal = blankbitmap.clone();

			nestbitmap = new BitmapData(blankbitmap.width, blankbitmap.height,true,0);

			// calculate the weight of the blank
			blankweight = 0;
			for(i=0; i<blankbitmap.width; i++){
				for(j=0; j<blankbitmap.height; j++){
					if(blankbitmap.getPixel(i,j) == 0xffffff){
						blankweight++;
					}
				}
			}

			blankweight = blankweight/(Global.zoom*Global.zoom*scale*scale)

			var blankrect:Rectangle = blank.getBounds(this);
			renderbitmap = new Bitmap(nestbitmap.clone());
			renderbitmap.width = blankrect.width;
			renderbitmap.height = blankrect.height;
			renderbitmap.x = blankrect.x;
			renderbitmap.y = blankrect.y;

			addChild(renderbitmap);

			removeChild(cutobject);

			_maximum = 100;
		}

		private function sortarea(a:*, b:*):Number{
			var area1:int = a.width*a.height;
			var area2:int = b.width*b.height;

			if(area1 > area2){
				return -1;
			}
			else if(area1 < area2){
				return 1;
			}

			return 0;
		}

		protected override function run():Boolean{

			if(underlimit == true){
				return false;
			}

			if(fittest != null){
				_progress = (fittest.fitness/blankweight)*100;
			}

			if(current >= cutlist.length){
				// if no GA exists, we are at the beginning of the GA process and have just finished calculating adam
				if(ga == null){
					var adam:Individual = new Individual();
					var genes:Array = new Array();
					for(var i:int=0; i<objectlist.length; i++){
						genes.push(objectlist[i].index);
					}
					adam.genes = genes;
					adam.data = objectlist;

					var fitness:Number = 0;
					for(i=0; i<objectlist.length; i++){
						if(!objectlist[i].failed){
							fitness += weightlist[objectlist[i].index];
						}
					}

					adam.fitness = fitness;

					var rect:Rectangle = nestbitmap.getColorBoundsRect(0xFFFFFFFF,0xFF000000);
					var area:Number = rect.width*rect.height;

					adam.secondaryfitness = 100/area;

					ga = new GeneticAlgorithm(adam);

					fittest = adam;

					renderbitmap.bitmapData.dispose();
					renderbitmap.bitmapData = nestbitmap.clone();
				}
				else{
					// we've finished calculating the current individual, save the data and move on to the next individual
					currentindividual.data = objectlist;
					var currentfitness:Number = 0;
					for(i=0; i<objectlist.length; i++){
						if(!objectlist[i].failed){
							currentfitness += weightlist[objectlist[i].index];
						}
					}
					currentindividual.fitness = currentfitness;

					rect = nestbitmap.getColorBoundsRect(0xFFFFFFFF,0xFF000000);
					area = rect.width*rect.height;

					currentindividual.secondaryfitness = 100/area;

					if(ga.sortByFitness(currentindividual, fittest) == -1){
						fittest = currentindividual;

						renderbitmap.bitmapData.dispose();
						renderbitmap.bitmapData = nestbitmap.clone();
					}

					trace('fitness: ', currentindividual.fitness, 'fitness2: ', currentindividual.secondaryfitness);
				}

				var pending:Array = ga.getPending();
				if(pending.length == 0){
					ga.generationStep();
					trace('next generation!');
					pending = ga.getPending();
				}
				currentindividual = pending[0];

				// reset variables
				current = 0;
				currentrotation = 0;

				blankbitmap.dispose();
				nestbitmap.dispose();

				blankbitmap = blankoriginal.clone();
				nestbitmap = new BitmapData(blankbitmap.width, blankbitmap.height,true,0);

				objectlist = null;
			}

			if(currentrotation >= 360){
				obj = new Object();

				if(bestangle == null){
					// no suitable placement was found for the current nest object, store a marker noting the failure and move to the next object
					obj.i = 0;
					obj.j = 0;
					obj.index = (currentindividual == null ? current : currentindividual.genes[current]);
					obj.rotation = 0;
					obj.failed = true;

					if(objectlist == null){
						objectlist = new Array();
					}

					objectlist.push(obj);
				}
				else{
					// an entire rotation cycle has been completed, commit the best bitmap to the blank and move on to the next nest object
					blankbitmap.copyPixels(bestangle.bitmapdata,new Rectangle(0,0,bestangle.bitmapdata.width,bestangle.bitmapdata.height), new Point(bestangle.i,bestangle.j),bestangle.bitmapdata,new Point(0,0),true);
					nestbitmap.copyPixels(bestangle.bitmapdata,new Rectangle(0,0,bestangle.bitmapdata.width,bestangle.bitmapdata.height), new Point(bestangle.i,bestangle.j),bestangle.bitmapdata,new Point(0,0),true);

					// store in object list for future retrieval (when an individual is created)
					if(objectlist == null){
						objectlist = new Array();
					}

					obj.i = bestangle.i;
					obj.j = bestangle.j;
					obj.x = bestangle.x;
					obj.y = bestangle.y;
					obj.index = (currentindividual == null ? current : currentindividual.genes[current]);
					obj.rotation = bestangle.rotation;

					objectlist.push(obj);

					bestangle.bitmapdata.dispose();
					bestangle = null;
				}

				currentrotation = 0;
				current++;
			}

			var obj:Object = place();

			if(obj != null){
				var tempbitmap:BitmapData = nestbitmap.clone();
				tempbitmap.copyPixels(obj.bitmapdata,new Rectangle(0,0,obj.bitmapdata.width,obj.bitmapdata.height), new Point(obj.i,obj.j),obj.bitmapdata,new Point(0,0),true);
				rect = tempbitmap.getColorBoundsRect(0xFFFFFFFF,0xFF000000);
				tempbitmap.dispose();

				obj.area = rect.width*rect.height;

				if(bestangle == null || bestangle.area > obj.area){
					if(bestangle != null){
						bestangle.bitmapdata.dispose();
					}
					bestangle = obj;
				}
				else{
					obj.bitmapdata.dispose();
				}
			}

			currentrotation += 360/divisions;

			//current++;

			return true;
		}

		private function place():Object{
			var nestobject:*;

			if(currentindividual == null){
				nestobject = cutlist[current];
			}
			else{
				nestobject = cutlist[currentindividual.genes[current]];
			}

			if(nestobject == null){
				return null;
			}

			var tempsprite:Sprite = new Sprite();
			addChild(tempsprite);
			tempsprite.addChild(nestobject);
			nestobject.rotation = currentrotation;

			var region:Rectangle = tempsprite.getBounds(this);

			if(region.width*scale > blankbitmap.width || region.height*scale > blankbitmap.height){
				return null;
			}

			//var trans:Matrix = new Matrix(scale,0,0,scale, -region.x*scale,-region.y*scale);
			var trans:Matrix = new Matrix();
			//trans.rotate(Math.PI);
			trans.scale(scale,scale);
			trans.translate(-region.x*scale,-region.y*scale);

			// account for rotation
			/*trans.translate(-(region.width*scale)/2,-(region.height*scale)/2);
			trans.rotate(Math.PI/2);
			trans.translate((region.width*scale)/2, (region.height*scale)/2);*/

			/*var angle:Number = Math.PI/4;

			trans.rotate(angle);
			trans.translate((region.height*scale)*Math.sin(angle), 0);*/

			//var nestbitmap:BitmapData = new BitmapData(region.width*scale*Math.abs(Math.cos(angle)) + region.height*scale*Math.abs(Math.sin(angle)), region.width*scale*Math.abs(Math.sin(angle)) + region.height*scale*Math.abs(Math.cos(angle)), true,0);

			var nestbitmap:BitmapData = new BitmapData(region.width*scale, region.height*scale, true,0);

			nestbitmap.draw(tempsprite,trans);

			removeChild(tempsprite);

			/*var rot:Matrix = new Matrix();
			rot.translate(-nestbitmap.width/2,-nestbitmap.height/2);
			rot.rotate(Math.PI);
			rot.translate(nestbitmap.width/2, nestbitmap.height/2);

			var rotated:BitmapData = new BitmapData(nestbitmap.width,nestbitmap.height,true,0);
			rotated.draw(nestbitmap,rot);

			nestbitmap.dispose();

			nestbitmap = rotated;*/

			//return false;
			var i:int = 0;
			var j:int = blankbitmap.height-nestbitmap.height;

			var overlap:Rectangle = getOverlap(nestbitmap, i,j);
			//return false;
			while(overlap.width > 0){
				//i += Math.ceil(overlap.width/2);
				i += overlap.width+1;

				if(i+nestbitmap.width > blankbitmap.width){
					j -= nestbitmap.height/10;
					i = 0;
				}

				if(j < 0){
					nestbitmap.dispose();
					return null;
				}

				overlap = getOverlap(nestbitmap,i,j);
			}

			var obj:Object = new Object();

			obj.i = i;
			obj.j = j;
			obj.x = region.x;
			obj.y = region.y;
			obj.bitmapdata = nestbitmap;
			obj.rotation = currentrotation;

			return obj;
		}

		// returns a rectangle for the given nestobject at i (x coord) and j (y coord) where it overlaps with the blank
		private function getOverlap(nestbitmap:BitmapData, i:int, j:int):Rectangle{
			var intersectbitmap:BitmapData = new BitmapData(nestbitmap.width, nestbitmap.height, true,0);
			intersectbitmap.copyPixels(blankbitmap, new Rectangle(i,j,nestbitmap.width,nestbitmap.height), new Point(0,0), nestbitmap, new Point(0,0));
			var intersectrect:Rectangle = intersectbitmap.getColorBoundsRect(0xFFFFFFFF,0xFF000000);
			//var bitmap:Bitmap = new Bitmap(intersectbitmap);
			//addChild(bitmap);
			intersectbitmap.dispose();
			return intersectrect;
		}

		public function finish():void{
			if(blankbitmap){
				blankbitmap.dispose();
			}
			if(blankoriginal){
				blankoriginal.dispose();
			}
			if(nestbitmap){
				nestbitmap.dispose();
			}
		}

	}
}