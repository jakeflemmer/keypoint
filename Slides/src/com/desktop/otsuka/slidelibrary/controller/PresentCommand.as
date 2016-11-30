package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.view.TitleSlideWidget;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.display.NativeWindowType;
	import flash.display.Screen;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.controls.VideoDisplay;
	
	import spark.components.Image;
	import spark.components.VideoPlayer;
	
	
	public class PresentCommand extends EventDispatcher
	{
		public function PresentCommand(target:IEventDispatcher=null)
		{
			super(target);
		}

		public var isPlayingMovie:Boolean = false;

		public var projectorWindow:ProjectorWindow;
		public var isProjecting:Boolean;
		
		private var _screen:Screen;
		private var _screenBounds:Rectangle;
		private var _background:Shape;
		public var imageContainer:Image;
		private var _currentImage:DisplayObject;
		private var _currentImageSource:DisplayObject;
		
	
		
		public var videoPlayer:VideoDisplay;
		public function get screen():Screen { return _screen; }
		public function get screenBounds():Rectangle { return _screenBounds; }
		
			
//		public function playVideo(vidSource:String,videoPlayer:Object):void{
//			//imageContainer.removeChildren();
//			
//			if ( ! videoPlayer ) {
//				videoPlayer = new VideoDisplay();
//				
//			}
//			videoPlayer.width = 500;
//			videoPlayer.height = 500;
//			videoPlayer.source = vidSource;
//			
//			
//			//projectorWindow.stage.addChild(videoPlayer);
//			//imageContainer.addChild(videoPlayer);
//			projectorWindow.addChildControls(videoPlayer);
//			//projectorWindow.activate();
//		}
//		
		public function playSwf(swf:Object):void
		{
			if ( ! isProjecting ) return;
			
			//imageContainer.removeChildren();
			
				isPlayingMovie = true;
				var movie:MovieClip = swf as MovieClip;
				
				movie.width = _screenBounds.width;
				movie.height = _screenBounds.height;
				
				
				imageContainer.source = movie;
				projectorWindow.addChildControls(imageContainer);
				//projectorWindow.activate();
				
		}
		public function displayImage(image:Bitmap):void
		{
			if ( ! isProjecting ) return;
			
			//imageContainer.removeChildren();
			
			
				isPlayingMovie = false;
				var clonedBitmapData:BitmapData = image.bitmapData.clone();
				var newBitmap:Bitmap = new Bitmap(clonedBitmapData);
			
				newBitmap.smoothing = true;
				newBitmap.scaleX = _screenBounds.width/newBitmap.width;
				newBitmap.scaleY = _screenBounds.height/newBitmap.height;
		
				imageContainer.source =  newBitmap ;
				projectorWindow.addChildControls(imageContainer);
				//projectorWindow.activate();
			
		}
		public function displayTitleSlideWidget(titleSlideWidget:TitleSlideWidget):void{
			
			if ( ! isProjecting ) return;
			titleSlideWidget.scaleX = _screenBounds.width/titleSlideWidget.width;
			titleSlideWidget.scaleY = _screenBounds.height/titleSlideWidget.height;
			imageContainer.addChild( titleSlideWidget );
		}
		
		
		public function startProjectorWindow(keyPressHandlers:Function):Boolean
		{
			var numberOfScreen:Array = Screen.screens;
	/*	/*	if ( numberOfScreen.length < 2 )
			{
				Alert.show("You must connect computer to external display before being able to present","Alert");
				isProjecting = false;
				return false;*/
		//		_screen= Screen.screens[0];
		//		_screenBounds = _screen.bounds;
		//		isProjecting = true;
		
		//	}		
		//	else{
			
			// init screen bounds
		//		_screen = Screen.screens[1];  // V@ Baby!!//Screen.mainScreen;
			//	_screenBounds = _screen.bounds;
			//}
			
			_screen= Screen.screens[0];
			_screenBounds = _screen.bounds;
			_currentImage = null;
			_currentImageSource = null;
			
			isProjecting = true;
			
			var windowInitOptions:NativeWindowInitOptions = new NativeWindowInitOptions();
			windowInitOptions.systemChrome = NativeWindowSystemChrome.NONE; //STANDARD
			windowInitOptions.type = NativeWindowType.NORMAL; //UTILITY //NORMAL (popup will appear in the win/linux taskbar)
			windowInitOptions.minimizable = false;
			windowInitOptions.maximizable = false;
			windowInitOptions.transparent = false;
			windowInitOptions.resizable = false;
			//windowInitOptions.owner = null;
			
			projectorWindow = new ProjectorWindow( windowInitOptions );
			projectorWindow.stage.scaleMode = StageScaleMode.NO_SCALE;
			projectorWindow.stage.align = StageAlign.TOP_LEFT;
			
			projectorWindow.x = _screenBounds.x;
			projectorWindow.y = _screenBounds.y;
			projectorWindow.width = _screenBounds.width;
			projectorWindow.height = _screenBounds.height;
			projectorWindow.alwaysInFront = true;
			
			_background = new Shape();
			_background.graphics.beginFill(0x0, 1.0);
			_background.graphics.drawRect(0,0, _screenBounds.width, _screenBounds.height);
			_background.graphics.endFill();
			
			imageContainer = new Image();
			
			//projectorWindow.stage.addChild(_background);
			//projectorWindow.stage.addChild(imageContainer);
			
			
			
			projectorWindow.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE; 
			
			projectorWindow.stage.addEventListener(KeyboardEvent.KEY_UP, keyPressHandlers);
			
			return true;
		}
		
		private function closeWarningHandler(event:Event = null):void
		{
			//eventDispatcher.dispatchEvent(new DialogEvent(DialogEvent.CLOSE_POPUP_WINDOW));
		}
		
		public function stopProjectorWindow():void
		{
			if ( ! isProjecting ) return;
			if( projectorWindow && ( ! projectorWindow.closed ) ) { 
				projectorWindow.stage.removeEventListener(KeyboardEvent.KEY_UP, projectorWindowKeyUpHandler);
				
				if( projectorWindow.stage.contains(_background) ) projectorWindow.stage.removeChild(_background);
				if( projectorWindow.stage.contains(imageContainer) ) projectorWindow.stage.removeChild(imageContainer);
				
				trace("Stopping projector window.");
				
				projectorWindow.close();
			}
			
			isProjecting = false;
		}
		
		protected function projectorWindowKeyUpHandler(event:KeyboardEvent):void
		{
			switch( event.keyCode ) { 
			//	case Keyboard.LEFT :
				case Keyboard.PAGE_DOWN:
					trace("left key pressed");
					//eventDispatcher.dispatchEvent(new PresentationEvent(PresentationEvent.LEFT_KEY_PRESSED));
					break;
			//	case Keyboard.RIGHT :
				case Keyboard.PAGE_UP:
					//eventDispatcher.dispatchEvent(new PresentationEvent(PresentationEvent.RIGHT_KEY_PRESSED));
					break;
				case Keyboard.ESCAPE : 
					//eventDispatcher.dispatchEvent(new PresentationEvent(PresentationEvent.ESCAPE_KEY_PRESSED));
					break;
				case Keyboard.BACKSPACE : 
					//eventDispatcher.dispatchEvent(new PresentationEvent(PresentationEvent.ESCAPE_KEY_PRESSED));
					break;
				default : break;
			}
		}
		
		
		
		private function fitIntoRect( displayObject:DisplayObject, rectangle:Rectangle, fillRect:Boolean = true, applyTransform:Boolean = true ):Matrix //align:String = "C", 
		{
			var matrix : Matrix = new Matrix();
			
			var wD : Number = displayObject.width / displayObject.scaleX;
			var hD : Number = displayObject.height / displayObject.scaleY;
			
			var wR : Number = rectangle.width;
			var hR : Number = rectangle.height;
			
			var sX : Number = wR / wD;
			var sY : Number = hR / hD;
			
			var rD : Number = wD / hD;
			var rR : Number = wR / hR;
			
			var sH : Number = fillRect ? sY : sX;
			var sV : Number = fillRect ? sX : sY;
			
			var s : Number = rD >= rR ? sH : sV;
			matrix.scale(s, s);
			
			if(applyTransform) displayObject.transform.matrix = matrix;
			
			return matrix;
		}
	}
}