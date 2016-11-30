package com.desktop.otsuka.slidelibrary.controller
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	
	
	public class FileDownloader
	{
		//======================================================================================================
		//======================================================================================================
		//      THIS IS USED TO LOAD ALL STUFF AT INITIAL LOG IN - 
		//			it saves it to system files - not application memory
		//======================================================================================================
		//======================================================================================================
		
		private var _remotePath:String;
		private var _request:URLRequest;
		private var _urlLoader : URLLoader;
		private var _fileStream:FileStream;
		private var _localPath:String;
		private var _localFile:File;		
		private var _callback:Function;	
		private var _timeoutFunction:Function;
		private var _timeoutTimer:Timer;
		
		public function FileDownloader()
		{
		}
	
		public function download( $remotePath:String, $localPath:String, $localFile:File, $callbackFunction:Function,$timeoutFunction:Function):void 
		{
			_remotePath = $remotePath;
			_localPath = $localPath;
			_localFile = $localFile;
			_callback = $callbackFunction;
			_timeoutFunction = $timeoutFunction;
			
			_request = new URLRequest( _remotePath );			
			
			_urlLoader = new URLLoader(_request);
			_urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
			
			configureLoaderListeners();
			if ( _remotePath && _remotePath.length > 0 )
			{
				//continue
			}else{
				trace("error");
			}
			trace("Attempting to load : " + _remotePath);
			
			//start timer
			//_timeoutTimer = new Timer(120000);	// 2 mins
			_timeoutTimer = new Timer(240000);	// 4 mins
			_timeoutTimer.addEventListener(TimerEvent.TIMER,onTimeout);
			_timeoutTimer.start();
			
			
			
			_urlLoader.load( _request );
		}
		private function onTimeout(e:Event):void{
			_timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onTimeout);			
			_timeoutTimer.stop();
			Alert.show("Connection timed out - please try again..","Alert");
			_timeoutFunction();
			
		}
		
		protected function urlStreamCompleteHandler(event:Event):void
		{
			trace("URL load request completed now writing to disk");
			_timeoutTimer.removeEventListener(TimerEvent.TIMER_COMPLETE,onTimeout);			
			_timeoutTimer.stop();
			
			_fileStream = new FileStream();
			
			configureWriterListeners();
			
			_fileStream.open(_localFile, FileMode.WRITE); 
			_fileStream.writeBytes(event.target.data);
			_fileStream.close();
			
			configureWriterListeners(true);
			configureLoaderListeners(true);
			
			setTimeout(function():void{
			_callback(_remotePath, _localPath);
			},100);	// prevents Error #3013: File or directory is in use.
		}	
		
		
		
		
		//==============================================================================================
		// HANDLERS
		//==============================================================================================
		
		protected function ioErrorHandler(event:IOErrorEvent):void
		{
			trace(" IOError! " + event.errorID + ", downloading: " + _remotePath );
			Alert.show("Connection timed out - please try again..","Alert");
			_timeoutFunction();	
		}
		protected function fileStreamProgressEventHandler(event:OutputProgressEvent):void
		{
			//trace("fileStreamProgressEventHandler");
			
		}
		protected function urlStreamProgressHandler(event:ProgressEvent):void
		{
			//trace("urlStreamProgressHandler");			
		}
		
		//==============================================================================================
		// LISTENERS
		//==============================================================================================
		
		public function configureLoaderListeners(remove:Boolean = false):void
		{
			if ( ! remove )
			{
				_urlLoader.addEventListener( Event.COMPLETE, urlStreamCompleteHandler ); 
				_urlLoader.addEventListener( ProgressEvent.PROGRESS, urlStreamProgressHandler );
				_urlLoader.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );				
			}
			else
			{
				_urlLoader.removeEventListener( Event.COMPLETE, urlStreamCompleteHandler ); 
				_urlLoader.removeEventListener( ProgressEvent.PROGRESS, urlStreamProgressHandler );
				_urlLoader.removeEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );	
			}			
		}
		public function configureWriterListeners(remove:Boolean = false):void
		{
			if ( ! remove )
			{
				_fileStream.addEventListener( OutputProgressEvent.OUTPUT_PROGRESS, fileStreamProgressEventHandler ); 
				_fileStream.addEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
			}
			else
			{
				_fileStream.removeEventListener( OutputProgressEvent.OUTPUT_PROGRESS, fileStreamProgressEventHandler ); 
				_fileStream.removeEventListener( IOErrorEvent.IO_ERROR, ioErrorHandler );
				_fileStream = null;
			}		
			
			
		}
		
	}// close class
}// close package