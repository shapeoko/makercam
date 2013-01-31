/*
Copyright (c) 2008 Tink Ltd - http://www.tink.ws

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and
to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions
of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO 
THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

package com.tink.display
{
    
    import flash.display.BitmapData;
    import flash.display.BlendMode;
    import flash.display.DisplayObject;
    import flash.display.Sprite;
    
    import flash.geom.ColorTransform;
    import flash.geom.Matrix;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    
    public class HitTest
    {

        public static function complexHitTestObject( target1:DisplayObject, target2:DisplayObject,  accuracy:Number = 1, perfect:Boolean = true ):Boolean
        {
            return complexIntersectionRectangle( target1, target2, accuracy , perfect).width != 0;
        }
        
        public static function intersectionRectangle( target1:DisplayObject, target2:DisplayObject, perfect:Boolean = true):Rectangle
        {
            // If either of the items don't have a reference to stage, then they are not in a display list
            // or if a simple hitTestObject is false, they cannot be intersecting.
            if( !target1.root || !target2.root || !target1.hitTestObject( target2 ) ) return new Rectangle();
            
			if(perfect == false){
				return new Rectangle();
			}
			
            // Get the bounds of each DisplayObject.
            var bounds1:Rectangle = target1.getBounds( target1.root );
            var bounds2:Rectangle = target2.getBounds( target2.root );
            
            // Determine test area boundaries.
            var intersection:Rectangle = new Rectangle();
            intersection.x         = Math.max( bounds1.x, bounds2.x );
            intersection.y        = Math.max( bounds1.y, bounds2.y );
            intersection.width     = Math.min( ( bounds1.x + bounds1.width ) - intersection.x, ( bounds2.x + bounds2.width ) - intersection.x );
            intersection.height = Math.min( ( bounds1.y + bounds1.height ) - intersection.y, ( bounds2.y + bounds2.height ) - intersection.y );
        
            return intersection;
        }
        
        public static function complexIntersectionRectangle( target1:DisplayObject, target2:DisplayObject, accuracy:Number = 1, perfect:Boolean = true ):Rectangle
        {            
            if( accuracy <= 0 ) throw new Error( "ArgumentError: Error #5001: Invalid value for accuracy", 5001 );
            
            // If a simple hitTestObject is false, they cannot be intersecting.
            if( !target1.hitTestObject( target2 ) ) return new Rectangle();
            
            var hitRectangle:Rectangle = intersectionRectangle( target1, target2 , perfect );
            // If their boundaries are no interesecting, they cannot be intersecting.
            if( hitRectangle.width * accuracy < 1 || hitRectangle.height * accuracy < 1 ) return new Rectangle();
            
			if(perfect == false){
				return new Rectangle();
			}
			
            var bitmapData:BitmapData = new BitmapData( hitRectangle.width * accuracy, hitRectangle.height * accuracy, false, 0x000000 );    

            // Draw the first target.
            bitmapData.draw( target1, HitTest.getDrawMatrix( target1, hitRectangle, accuracy ), new ColorTransform( 1, 1, 1, 1, 255, -255, -255, 255 ) );
            // Overlay the second target.
            bitmapData.draw( target2, HitTest.getDrawMatrix( target2, hitRectangle, accuracy ), new ColorTransform( 1, 1, 1, 1, 255, 255, 255, 255 ), BlendMode.DIFFERENCE );
            
            // Find the intersection.
            var intersection:Rectangle = bitmapData.getColorBoundsRect( 0xFFFFFFFF,0xFF00FFFF );
            
            bitmapData.dispose();
            
            // Alter width and positions to compensate for accuracy
            if( accuracy != 1 )
            {
                intersection.x /= accuracy;
                intersection.y /= accuracy;
                intersection.width /= accuracy;
                intersection.height /= accuracy;
            }
            
            intersection.x += hitRectangle.x;
            intersection.y += hitRectangle.y;
            
            return intersection;
        }
        
        
        protected static function getDrawMatrix( target:DisplayObject, hitRectangle:Rectangle, accuracy:Number ):Matrix
        {
            var localToGlobal:Point;
            var matrix:Matrix;
            
            var rootConcatenatedMatrix:Matrix = target.root.transform.concatenatedMatrix;
            
           
            
            localToGlobal = target.localToGlobal( new Point( ) );
            matrix = target.transform.concatenatedMatrix;
            matrix.tx = localToGlobal.x - hitRectangle.x;
            matrix.ty = localToGlobal.y - hitRectangle.y;
            
            matrix.a = matrix.a / rootConcatenatedMatrix.a;
            matrix.d = matrix.d / rootConcatenatedMatrix.d;
            if( accuracy != 1 ) matrix.scale( accuracy, accuracy );

            return matrix;
        }

    }

}
