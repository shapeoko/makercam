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
	import flash.utils.getTimer;

	public class ThreadStatistics {

		public var numCycles:int;
		public var numTimeouts:int;

		public var totalTime:int;

		public var times : Array;
		public var allocationDifferentials : Array;

		private var currentCycleStart:int;

		public function ThreadStatistics() {
			times = [];
			allocationDifferentials = [];
		}

		public function startCycle() : void {
			currentCycleStart = getTimer();
		}

		public function endCycle( allocation:int ) : void {

			var time:Number = getTimer() - currentCycleStart;

			totalTime += time;

			times[ numCycles ] = time;
			allocationDifferentials[ numCycles ] = time - allocation;

			numCycles++;
		}

		public function recordTimeout() : void {
			numTimeouts++;
		}

		public function get meanTime() : Number {
			return totalTime / numCycles;
		}

		public function get averageDifferential() : Number {

			var sum:int = 0;

			for each( var differential : int in allocationDifferentials ) {
				sum += differential;
			}

			return sum / numCycles;
		}

		public function get maxTime() : int {
			var max:int = 0;

			for each( var time:int in times ) {
				max = Math.max( max, time );
			}

			return max;
		}

		public function get minTime() : int {
			var min:int = Number.MAX_VALUE;

			for each( var time : int in times ) {
				min = Math.min( min, time );
			}

			return min;
		}

		public function print() : String {
			return "Total Time: " + totalTime + "(ms)" +
					"\nNumber Of Cycles: " + numCycles +
					"\nMean time per cycle: " + this.meanTime + "(ms)" +
					"\nMinimum Time, Maximum Time " + this.minTime + "(ms), " + this.maxTime + " (ms)" +
					"\nAverage Differential: " + this.averageDifferential + "(ms)" +
					"\nAverage Allocation Diff: " + this.allocationDifferentials + "(ms)" +
					"\nNumber Of Timeouts: " + numTimeouts;
		}


	}
}