package com.desktop.otsuka.slidelibrary.model
{
	import flash.display.Bitmap;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	
	public class SlideSystemModel extends EventDispatcher
	{		
		public var selectedBrandObject:Object;
		public var selectedPresentationObject:Object;

		public var optionalSlides:Array;
		
		
		public var slidesToLoadIntoApplicationCache:Array = new Array();
		
		// loading slides
		public var numberOfSlidesLoaded:uint;
		public var numberOfOptionalSlidesLoaded:uint;
		public var urlBeingLoaded:String;
		public var slideIdBeingLoaded:int;
		
	
		
		public var callBackAfterLoadingSlidesIntoApplicationCache:Function;
		
		// previewing slides
		public var slidePreviewingIndex:uint = 0;		
		
		public var loadedSlidesMap:Object = new Object();
		//public var loadedOptionalSlidesMap:Object = new Object();
		
		// misc
//		public var slidesFolder:File;
//		public var swfsFolder:File;
		
		public var storageFolder:File;
		

		public var slidesToPresent:Array;
		public var loadingForPresentMode:Boolean = false;
		public var loadingV3OrAboveSlides:Boolean;
		
		//Detect if user has more than one brand
		private var _moreThanOneBrand2:Boolean; //NOTE
		
		
		
		public function SlideSystemModel(target:IEventDispatcher=null)
		{
			super(target);
		}
		
		public function getSlideBitmap(slideId:int):Bitmap{
			var bitmap:Bitmap = loadedSlidesMap[slideId] as Bitmap;
			return bitmap;
		}
		
		public function set getBrandBoolean(value:Boolean):void{
			_moreThanOneBrand2 = value;
		}
		
		public function get getBrandBoolean():Boolean{
			return _moreThanOneBrand2;
		}
		
		
//		public function get selectedPresentationId():int{
//			return _selectedPresentationId;
//		}
//		public function set selectedPresentationId(id:int):void{
//			this._selectedPresentationId = id;
////			var presentationArray:Array = dbModel.getWhere(dbModel.systemSQLConnection,"slides","presentation_id",id);
////			var presentation:Object = presentationArray[0];
////			for ( var i :uint = 0; i < (presentation.section.Slides as Array).length; i++)
////			{
////				var slideId:int = presentation.section.Slides[i].slide_id;
////				this.slideIdsInPresentationArray.push(slideId);
////			}
//		}
//		
		
		
		
		
		
		
		private function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
		
	}
}