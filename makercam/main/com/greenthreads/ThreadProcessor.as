/**
   Copyright 2009 Charles E Hubbard

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
 */ 
package com.greenthreads {
	
	import flash.events.Event;
	import flash.utils.getTimer;
	
	//import mx.core.Application;
	
	public class ThreadProcessor {
		
		private static var _instance : ThreadProcessor;
		private static const EPSILON : int = 1;
		
		public static var stage:*;
		
		private var frameRate : int;
		private var _share : Number;
		private var activeThreads : Array;
		private var errorTerm:int;
		
		public function ThreadProcessor( share : Number = 0.99 ) {
			if( !_instance ) {
				this.frameRate = stage.frameRate;
				this.share = share;
				this.activeThreads = null;
				_instance = this;
			} else {
				throw new Error("Error: Instantiation failed: Use ThreadProcessor.getInstance() instead of new.");
			}
		}
		
		public static function getInstance( share : Number = 0.99 ) : ThreadProcessor {
			if( !_instance ) {
				_instance = new ThreadProcessor( share );
			}
			return _instance;
		}
		
		public function addThread( thread : GreenThread ) : void {
			if( !activeThreads ) {
				activeThreads = [];
				start();
			}
			activeThreads.push( thread );
		}
		
		private function start() : void {
			stage.addEventListener( Event.ENTER_FRAME, doCycle );
		}
		
		public function stop( thread : GreenThread ) : void {
			var index : int = activeThreads.indexOf( thread );
			if( index >= 0 ) {
				activeThreads.splice( index, 1 );
			}
			if( activeThreads.length == 0 ) {
				stopAll();
			}
		}
		
		public function stopAll() : void {
			activeThreads = null;
			stage.removeEventListener( Event.ENTER_FRAME, doCycle );
		}
		
		private function doCycle( event : Event ) : void {
			var timeAllocation : int = share < 1.0 ? timerDelay * share + 1 : frameRate - share;
			timeAllocation = Math.max(timeAllocation, EPSILON * activeThreads.length);

			//if the error term is too large, skip a cycle
			if( errorTerm > timeAllocation - 1 ) {
				errorTerm = 0;
				return;
			}
						
			var cycleStart:int = getTimer();
			
			var cycleAllocation:int = timeAllocation - errorTerm;
			var processAllocation:int = cycleAllocation / activeThreads.length;			
			
			//decrement for easy removal of processes from list
			for( var i:int = activeThreads.length - 1; i > -1; i-- ) {
				var process:GreenThread = activeThreads[ i ] as GreenThread;
				if( !process.execute( processAllocation ) ) {
					if( activeThreads ) {
						//open up more allocation to remaining processes
						processAllocation = cycleAllocation / activeThreads.length;
					} else {
						break;
					}
				}
			}
			
			//solve for cycle time
			var cycleTime:int = getTimer() - cycleStart;
			var delta:Number = cycleTime - timeAllocation;
			
			//update the error term
			errorTerm = ( errorTerm + delta ) >> 1;
		}

		public function get timerDelay() : Number {
			return 1000 / frameRate;
		}
		
		public function get share() : Number {
			return _share;
		}
		
		public function set share( percent : Number ) : void {
			_share = percent;
		}
	}
}