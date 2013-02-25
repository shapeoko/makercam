package com.partkart{
	public dynamic class MonotoneChain extends Array{

		public var frontindex:int = 0; // index of front
		public var frontvalue:Number; // x value of front vertex (used for sorting)
		public var reversed:Boolean = false;
		public function MonotoneChain(... args):void{
			for each(var arg in args){
				super.push(arg);
			}
		}
	}
}