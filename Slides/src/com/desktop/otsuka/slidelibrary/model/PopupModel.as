package com.desktop.otsuka.slidelibrary.model
{
	import flash.display.Shape;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class PopupModel extends EventDispatcher
	{
		public var modalCanvas:Shape;
		
		private static var _instance:PopupModel;

		
		public function PopupModel(singletonEnforcer:String,target:IEventDispatcher=null)
		{
			super(target);
			
			if ( singletonEnforcer != "sing" ) throw new Error("can't instantiate singleton directly");
		}
		
		public static function getInstance():PopupModel{
			if ( _instance == null )
			{
				_instance = new PopupModel("sing");
			} 
			return _instance;
		}
		
		
		public function drawModalCanvas():void{
			modalCanvas = new Shape();
			modalCanvas.graphics.beginFill(0x000000,.2);
			modalCanvas.graphics.drawRect(0,0,1024,768);
			modalCanvas.graphics.endFill();			
		}		
		
	}
}