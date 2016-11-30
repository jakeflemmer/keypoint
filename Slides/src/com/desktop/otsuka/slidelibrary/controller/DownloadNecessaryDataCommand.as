package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.LoginPanel;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestDefaults;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	import mx.controls.Alert;
	
	public class DownloadNecessaryDataCommand extends EventDispatcher
	{
		private const DATA_URL:String = LoginPanel.BETA_OR_PROD_URL + "library/userdata/"; // + hash + /slides/
		public static const ALT_DATA_URL:String = LoginPanel.BETA_OR_PROD_URL + "library/api/"+LoginPanel.versionNumGlobal + "/user/"; // + hash + /slides/
		//private const DATA_URL:String = "http://beta.otsukaweb.visual-a.com/library/userdata/"; // + hash + /slides/
		private const SLIDES_DATA:String = "/slides/"; //jcf all data for slides including notes, jpgs etc
		private const PRESENTATIONS_DATA:String = "/presentations/"; //jcf data for presentations
		private const UPDATES_DATA:String = "/updates/";	// jcf things to be deleted , created or updated after initial setup
		private const UPDATE_TIMESTAMP:String = "1343174400/";
		
		/*
		The 3 new URL's are:
		/library/api/5.1/user/userhash/updates/timestamp/?m=machine_id
		/library/api/5.1/user/userhash/presentations/?m=machine_id
		/library/api/5.1/user/userhash/slides/?m=machine_id
		*/
		
		//  DATA_URL + user_hash + UPDATES_DATA + userData.last_updated + "?format=flash&version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;
		
		private var _updateTimer:Timer;
		
		//charlie = f25e2b7093f6441189ec57a01c6a303a
		//private const SLIDES_DATA_URL:String = "http://beta.otsukaweb.visual-a.com/library/userdata/db2989257e944480aea23b02f6d25b6f/slides/";
		//private const PRESENTATIONS_DATA_URL:String = "http://beta.otsukaweb.visual-a.com/library/userdata/db2989257e944480aea23b02f6d25b6f/presentations/";
		//private const UPDATES_DATA_URL:String = "http://beta.otsukaweb.visual-a.com/library/userdata/db2989257e944480aea23b02f6d25b6f/updates/";
		
		private var _urlRequest:URLRequest;
		private var _loader:URLLoader;
		private var _slidesBA:ByteArray;
		private var _presentationsBA:ByteArray;
		private var _slidesDataFile:File;
		private var _presentationsDataFile:File;
		
		public var loaderData:Object;
		public var slidesAloneData:Object;
		public var bundlesAloneData:Object;
		public var presentationsData:Object;
		public var updatesData:Object;
		
		private var user_hash:String;
		
		public function DownloadNecessaryDataCommand($user_hash:String)
		{
			_loader = new URLLoader();
			_loader.dataFormat = URLLoaderDataFormat.TEXT;
			this.user_hash = $user_hash;
		}
		
		
		public function downloadAllUserData():void{
			
			downloadSlidesData();
			// which then calls downloadPresentationsData()
		}
		//===================================================================================================
		// DOWNLOAD UPDATES DATA
		//===================================================================================================
		
		public function downloadUpdatesData(userHash:String):void 
		{ 
//			URLRequestDefaults.idleTimeout = 90000; //fixed timeout
			URLRequestDefaults.idleTimeout = 240000; //fixed timeout - 240 seconds as directed by Tom 4/23/2014
			_loader.addEventListener(Event.COMPLETE, updatesDataLoadCompleteHandler);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, updatesDataLoaderErrorHandler);
			_loader.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			
			//var usersData:Array = dbModel.getUserWithUserName(userName); 
			var userData:Object = dbModel.getUserWithUserHash(userHash); //usersData[0];
			//last_updated:String = "100000000"
			/*var date:Date = new Date();
			date.time = userData.last_updated * 1000;*/
			//trace( "Gathering updates since: " + userData.last_updated + " or: " + date);
			trace( "Gathering updates since: " + userData.last_updated);
			
			var urlString:String = "";
			
			if ( LoginPanel.MUST_USE_MALKAS_NEW_URLS == false )
			{
				urlString =  DATA_URL + user_hash + UPDATES_DATA + userData.last_updated + "?format=flash&version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;			
			}else{
				urlString =  ALT_DATA_URL + user_hash + UPDATES_DATA + userData.last_updated + "?format=flash&m="+LoginPanel.m;
			}
			
			
			
			/////   **************  TEST MOCK UP JSON
			//	var urlString:String = "http://mesdb.iguffy.va-dev.net/events/testing_keypoint/library/userdata/123/updates/456/"+userData.last_updated +"?format=flash&version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;
			//*****************************************************************
			
			_urlRequest = new URLRequest( urlString );			
			trace(" Downloading updates data from " + _urlRequest.url ); 
			
			_loader.load( _urlRequest ); 
		}		
		
		protected function updatesDataLoadCompleteHandler(event:Event):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, updatesDataLoadCompleteHandler); //This ensures that this is not executed in a loop. //NOTE
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, slidesDataLoaderErrorHandler);			
			
			_loader.close();
			
			trace("Update data : " + _loader.data);
			this.updatesData = JSON.parse(_loader.data);
			
			if (SlidesUtilities.testSlidesAloneDataTableForV3Compatability(true)) // return true if it is compatible
			{
				var se:SlidesEvent = new SlidesEvent(SlidesEvent.UPDATES_DATA_LOADED);
				dispatchEvent(se);	
			}else{
				downloadSlidesData(true);
			}
			
			
		}
		private function slidesDataLoadCompleteForDataBaseMigrationHandler(event:Event):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, slidesDataLoadCompleteForDataBaseMigrationHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, slidesDataLoaderErrorHandler);
			
			_loader.close();
			
			var groupedSlidesAndBundlesData:Object = JSON.parse( _loader.data );
			this.slidesAloneData = groupedSlidesAndBundlesData.Slides;
			
			var oldTableCleaner:ClearDatabaseCommand = new ClearDatabaseCommand();
			oldTableCleaner.dropOldSlidesAloneTableForMigrationToV3();
			
			var newTableCreator:CreateDatabaseCommand = new CreateDatabaseCommand();
			newTableCreator.createNewSlidesAloneTableForV3();
			
			dbModel.insertSlidesAloneData(this.slidesAloneData, dbModel.systemSQLConnection);
			
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.UPDATES_DATA_LOADED);
			dispatchEvent(se);	
			
			
		}
		
		
		
		//===================================================================================================
		// DOWNLOAD ALL DATA
		//===================================================================================================
		
		// 1. DOWNLOAD SLIDES
		private function downloadSlidesData(forDataBaseMigration:Boolean = false):void
		{
			_loader.addEventListener(IOErrorEvent.IO_ERROR, slidesDataLoaderErrorHandler);
			_loader.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			if ( ! forDataBaseMigration )
			{
				_loader.addEventListener(Event.COMPLETE, slidesDataLoadCompleteHandler);
			} else {
				_loader.addEventListener(Event.COMPLETE, slidesDataLoadCompleteForDataBaseMigrationHandler);
			}
			
			var url:String = "";
			
			if ( LoginPanel.MUST_USE_MALKAS_NEW_URLS == false )
			{
				url = DATA_URL + user_hash + SLIDES_DATA + "?format=flash&version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;
			}else{
				url = ALT_DATA_URL + user_hash + SLIDES_DATA + "?format=flash&m="+LoginPanel.m;
			}
			
			
			/// MOCK UP JSON *****************************
			//var url:String = "http://mesdb.iguffy.va-dev.net/events/testing_keypoint/library/userdata/123/slides/"+ "?format=flash&version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;// DANGER VIDEO+ "?format=flash";
			//*********************************************
			_urlRequest = new URLRequest( url );
			
			trace(" Downloading slides data from " + url);
			_loader.load( _urlRequest ); //
		}
		// 2. SLIDES COMPLETE
		protected function slidesDataLoadCompleteHandler(event:Event):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, slidesDataLoadCompleteHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, slidesDataLoaderErrorHandler);
			
			_loader.close();
			
			var groupedSlidesAndBundlesData:Object = JSON.parse( _loader.data );
			this.slidesAloneData = groupedSlidesAndBundlesData.Slides;
			this.bundlesAloneData = groupedSlidesAndBundlesData.Bundles;
			
			// V3 databse migration
			if (SlidesUtilities.testSlidesAloneDataTableForV3Compatability()) // return true if it is compatible
			{
				// we are good - proceed as usual	
			}else{
				var oldTableCleaner:ClearDatabaseCommand = new ClearDatabaseCommand();
				oldTableCleaner.dropOldSlidesAloneTableForMigrationToV3();
				
				var newTableCreator:CreateDatabaseCommand = new CreateDatabaseCommand();
				newTableCreator.createNewSlidesAloneTableForV3();				
			}			
			
			downloadPresentationsData();
		}
		// 3. DOWNLOAD PRESENTATIONS
		private function downloadPresentationsData():void
		{
			_loader.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.addEventListener(Event.COMPLETE, presentationsDataLoadCompleteHandler);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, presentationsDataLoaderErrorHandler);
			
			
			
			var url:String = "";
			
			if ( LoginPanel.MUST_USE_MALKAS_NEW_URLS == false )
			{
				url = DATA_URL + this.user_hash + PRESENTATIONS_DATA+"?version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;
			}else{
				url = ALT_DATA_URL + user_hash + PRESENTATIONS_DATA + "?format=flash&m="+LoginPanel.m;
			}			
			trace(" Loading presentations data from " + url);
			
			// JSON MOCK PAGE *************************
			//var url:String = "http://mesdb.iguffy.va-dev.net/events/testing_keypoint/library/userdata/123/presentations/"+"?version="+LoginPanel.versionNumGlobal+"&m="+LoginPanel.m;
			//****************************************************
			
			_loader.load( new URLRequest( url ) );
		}		
		// 4. PRESENTATIONS COMPLETE
		protected function presentationsDataLoadCompleteHandler(event:Event):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, presentationsDataLoadCompleteHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, presentationsDataLoaderErrorHandler);
			
			trace("Populating Presentations Data");
			
			_loader.close();
			
			this.presentationsData = JSON.parse( _loader.data );
			
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.NEW_USER_DATA_LOADED);
			dispatchEvent(se);	
			
		}
		
		
		
		
		//==============================================================================
		// MODIFY DATA
		//==============================================================================
		
		// and i dont plan on modifying any data !! :)
		
		//==============================================================================
		// ERROR AND PROGRESS HANDLERS
		//==============================================================================
		
		protected function loaderProgressHandler(event:ProgressEvent):void
		{
			trace("downloading...");
		}
		protected function presentationsDataLoaderErrorHandler(event:IOErrorEvent):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, presentationsDataLoadCompleteHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, presentationsDataLoaderErrorHandler);
			
			errorHandler();
		}
		protected function slidesDataLoaderErrorHandler(event:IOErrorEvent):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, slidesDataLoadCompleteHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, slidesDataLoaderErrorHandler);
			
			errorHandler();
		}
		
		protected function updatesDataLoaderErrorHandler(event:IOErrorEvent):void
		{
			_loader.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
			_loader.removeEventListener(Event.COMPLETE, updatesDataLoadCompleteHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, updatesDataLoaderErrorHandler);
			
			errorHandler();
		}
		
		private function errorHandler():void
		{
			Alert.show("I/O ERROR Connecting to JSON data");			
		}	
		
		private function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
	}
}

