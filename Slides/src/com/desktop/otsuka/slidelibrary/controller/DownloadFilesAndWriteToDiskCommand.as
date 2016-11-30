package com.desktop.otsuka.slidelibrary.controller
{
	
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.PopupAlert;
	
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.utils.Timer;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	
	public class DownloadFilesAndWriteToDiskCommand extends EventDispatcher
	{
		private var slideFileDownloader:FileDownloader;
		private var pdfFileDownloader:FileDownloader;
		private var masterFileDownloader:FileDownloader;
		private var swfFileDownloader:FileDownloader;
		private var dataDownloader:FileDownloader;
		private var resourceFileDownloader:FileDownloader;
		
		private var _totalFilesToDownloadArray:Array;		
		private var _numberOfFilesToDownload:uint = 0;
		private var _numberOfFilesDownloaded:uint = 0;
		
		private var _totalMastersToDownloadArray:Array;		
		private var _numberOfMastersToDownload:uint = 0;
		private var _numberOfMastersDownloaded:uint = 0;
		
		private var _totalResourcesToDownloadArray:Array;		
		private var _numberOfResourcesToDownload:uint = 0;
		private var _numberOfResourcesDownloaded:uint = 0;
		
		public var slidesFolder:File;
		public var pdfsFolder:File;
		public var masterFolder:File;
		public var swfsFolder:File;
		public var dataFolder:File;
		public var resourcesFolder:File;
		
		public var gotSlide:Boolean;
		public var gotPDF:Boolean;
		public var gotSwf:Boolean;
		public var gotData:Boolean;
		
		private var _forNewUser:Boolean;
		
		public var finishedSlidesAndPDFs:Boolean = false;
		public var finishedMasters:Boolean = false;
		public var finishedResources:Boolean = false;
		
		private var _popupAlert:PopupAlert;
		
		public function DownloadFilesAndWriteToDiskCommand(downloadingTheSlidesToDiskAlert:PopupAlert)
		{
			_popupAlert = downloadingTheSlidesToDiskAlert;
		}
		
		//============================================================================================
		// DOWNLOAD FILES
		//============================================================================================
		
		public function downloadAllFiles(forNewUser:Boolean):void
		{
			_forNewUser = forNewUser;
			_totalFilesToDownloadArray = dbModel.getAllSlides( dbModel.systemSQLConnection);
			
			if( _totalFilesToDownloadArray.length == 0 ) { 
				slidesPDFsSwfsAndFlvsEnd();
				return;
			}
			
			_numberOfFilesDownloaded = 0;			
			_numberOfFilesToDownload = _totalFilesToDownloadArray.length;
			
			trace("PREPARING TO DOWNLOAD " + _numberOfFilesToDownload + " FILES.");
			
			if ( slideFileDownloader == null )slideFileDownloader = new FileDownloader();
			if ( pdfFileDownloader == null )pdfFileDownloader = new FileDownloader();
			if ( swfFileDownloader == null)swfFileDownloader = new FileDownloader();
			if ( dataDownloader == null )dataDownloader = new FileDownloader();
			
			slidesFolder = File.applicationStorageDirectory.resolvePath("slides" + File.separator);
			pdfsFolder = File.applicationStorageDirectory.resolvePath("pdfs" + File.separator);
			swfsFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
			
			if( ! slidesFolder.exists ) slidesFolder.createDirectory();
			if( ! pdfsFolder.exists ) pdfsFolder.createDirectory();
			if( ! swfsFolder.exists ) swfsFolder.createDirectory();
			
			/*
			var popupTimer:Timer = new Timer(500,1000000000);
			popupTimer.addEventListener(TimerEvent.TIMER, 
				function ( o:Object = null ):void{
					if ( _numberOfFilesDownloaded < _numberOfFilesToDownload )
					{
						_popupAlert.bodyTextArea.text = "Downloaded " + _numberOfFilesDownloaded + " / " + _numberOfFilesToDownload;
					}else{
						popupTimer.stop();
						popupTimer=null;
					}
					});
			popupTimer.start();
			*/
			
			fileLoadManagerFunction();
		}
		
		private function fileLoadManagerFunction():void{
			if ( _numberOfFilesDownloaded < _numberOfFilesToDownload )
			{
				var slideObject:Object = _totalFilesToDownloadArray[_numberOfFilesDownloaded]; 
				gotSlide = false;
				gotPDF = false;
				gotSwf = false;
				gotData = false;
				downloadSingleImage(slideObject);
				downloadSinglePDF(slideObject);
				downloadSingleSwf(slideObject);
				downloadSingleFlv(slideObject);
				
			}else{
				filesLoadedComplete();
			}
		}
		
		
		private function downloadSingleImage( slideObject:Object ):void
		{
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = slideObject.thumbnail;			
			
			destinationFolder = slidesFolder.resolvePath(slideObject.slide_id);
			if( ! destinationFolder.exists ) destinationFolder.createDirectory();
			
			filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 ) 
			{ 
				fileDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				slideFileDownloader.download( fileUrl, localPath, localFile, fileDownloadCompleteHandler, timeoutError); 
			}
		}
		private function downloadSinglePDF( slideObject:Object ):void
		{
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = slideObject.printable_pdf;			
			
			destinationFolder = pdfsFolder.resolvePath(slideObject.slide_id);
			if( ! destinationFolder.exists ) pdfsFolder.createDirectory();
			
			filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			//filename += ".pdf";
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 && dbModel.updatedPDFSlidesMap[slideObject.slide_id] == null) 
			{ 
				pdfFileDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				pdfFileDownloader.download( fileUrl, localPath, localFile, pdfFileDownloadCompleteHandler, timeoutError); 
			}
		}
		private function downloadSingleSwf( slideObject:Object ):void
		{
			
			if ( slideObject.hasOwnProperty("swf") && (slideObject.swf as String).length > 0 )
			{					
				//continue
			}else{
				swfFileDownloadCompleteHandler(null,null);
				return;
			}
			// TODO sloppy
			slideObject.swfDownloaded = true;
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = slideObject.swf;			
			
			destinationFolder = swfsFolder.resolvePath(slideObject.slide_id);
			if( ! destinationFolder.exists ) destinationFolder.createDirectory();
			
			filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			//filename += ".pdf";
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 ) 
			{ 
				swfFileDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				swfFileDownloader.download( fileUrl, localPath, localFile, swfFileDownloadCompleteHandler, timeoutError); 
			}
		}
		private function downloadSingleFlv( slideObject:Object ):void
		{
			if ( slideObject.hasOwnProperty("flv") && (slideObject.flv as String).length > 0 && slideObject.flv != "undefined")
			{
				//continue
			}else{
				dataDownloadCompleteHandler(null,null);
				return;
			} 
			
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = slideObject.flv;			
			
			destinationFolder = swfsFolder.resolvePath(slideObject.slide_id+"/data");
			if( ! destinationFolder.exists ) destinationFolder.createDirectory();
			
			filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			//filename += ".pdf";
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 ) 
			{ 
				dataDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				dataDownloader.download( fileUrl, localPath, localFile, dataDownloadCompleteHandler, timeoutError); 
			}
		}
		
		//============================================================================================
		// PDF MASTERS DOWNLOAD
		//============================================================================================
		
		public function downloadMasterPDF():void{
			_totalMastersToDownloadArray = dbModel.getAllPresentationsByDate(dbModel.systemSQLConnection);
			
			if( _totalMastersToDownloadArray.length == 0 ) { 
				mastersEnd();
				return;
			}
			
			_numberOfMastersDownloaded = 0;			
			_numberOfMastersToDownload = _totalMastersToDownloadArray.length;
			
			trace("PREPARING TO DOWNLOAD " + _numberOfMastersToDownload + " FILES.");
			
			if ( masterFileDownloader == null )masterFileDownloader = new FileDownloader();
			
			masterFolder = File.applicationStorageDirectory.resolvePath("masters" + File.separator);
			if( ! masterFolder.exists ) masterFolder.createDirectory();
			
			mastersLoadManagerFunction();
		}
		
		private function mastersLoadManagerFunction():void{
			if ( _numberOfMastersDownloaded < _numberOfMastersToDownload )
			{
				var fileObject:Object = _totalMastersToDownloadArray[_numberOfMastersDownloaded]; 
				// DANGER
				if ( fileObject.printable_pdf && (fileObject.printable_pdf as String).length > 0 )
				{
					downloadSingleMaster(fileObject);	
				}else{
					masterLoadedHandler();
					// DANGER this is a good warning Alert.show("There is no master PDF for printing an entire core deck - admin must populate this master PDF","Alert");
				}
				
			}else{
				mastersLoadedComplete();
			}
		}
		
		private function downloadSingleMaster( fileObject:Object ):void
		{
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = fileObject.printable_pdf;			
			
			destinationFolder = masterFolder.resolvePath(fileObject.presentation_id);
			if( ! destinationFolder.exists ) destinationFolder.createDirectory();
			
			filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			//filename += ".pdf";
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 && dbModel.updatedPDFMastersMap[fileObject.presentation_id] == null) 
			{ 
				masterFileDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				masterFileDownloader.download( fileUrl, localPath, localFile, masterFileDownloadCompleteHandler, timeoutError); 
			}
		}
		
		//============================================================================================
		// RESOURCES DOWNLOAD
		//============================================================================================
		
		public function downloadAllResourcePDFs():void{
			_totalResourcesToDownloadArray = dbModel.getAllResources(dbModel.systemSQLConnection);
			
			if( _totalResourcesToDownloadArray.length == 0 ) { 
				resourcesEnd();
				return;
			}
			
			_numberOfResourcesDownloaded = 0;			
			_numberOfResourcesToDownload = _totalResourcesToDownloadArray.length;
			
			trace("PREPARING TO DOWNLOAD " + _numberOfResourcesToDownload + " RESOURCES.");
			
			if ( resourceFileDownloader == null ) resourceFileDownloader = new FileDownloader();
			
			resourcesFolder = File.applicationStorageDirectory.resolvePath("resources" + File.separator);
			if( ! resourcesFolder.exists ) resourcesFolder.createDirectory();
			
			resourcesLoadManagerFunction();
		}
		
		private function resourcesLoadManagerFunction():void{
			if ( _numberOfResourcesDownloaded < _numberOfResourcesToDownload )
			{
				var resourceObject:Object = _totalResourcesToDownloadArray[_numberOfResourcesDownloaded]; 
				
				if ( resourceObject.url && (resourceObject.url as String).length > 0 )
				{
					downloadSingleResource(resourceObject);	
				}else{
					resourcesLoadedHandler();
					Alert.show("There is no url for donwloading a PDF resource","Alert");
				}
				
			}else{
				resourcesLoadedComplete();
			}
		}
		
		private function downloadSingleResource( resourceObject:Object ):void
		{
			var fileUrl:String;
			var filename:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;
			
			fileUrl = resourceObject.url;			
			
			destinationFolder = resourcesFolder.resolvePath(resourceObject.id);
			if( ! destinationFolder.exists ) destinationFolder.createDirectory();
			
			//filename = fileUrl.substr((fileUrl.lastIndexOf("/") + 1)); //text from last "/" to end
			filename = resourceObject.id;
			filename += ".pdf";
			localFile = destinationFolder.resolvePath( filename );
			localPath = destinationFolder.url +"/"+ filename;
			
			if( localFile.exists && localFile.size > 1 &&  dbModel.mustUpdateResourcePDFsMap[ resourceObject.id ] == null) 
			{ 
				resourceFileDownloadCompleteHandler( fileUrl, localPath ); //file already exists! skip the download.
			}
			else { 
				resourceFileDownloader.download( fileUrl, localPath, localFile, resourceFileDownloadCompleteHandler, timeoutError); 
			}
		}
		
		
		
		//============================================================================================
		// HANDLERS
		//============================================================================================
		
		protected function fileDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			gotSlide = true;
			if ( gotSlide && gotPDF && gotSwf && gotData)mergedHandler();
		}
		protected function pdfFileDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			gotPDF = true;		
			if ( gotSlide && gotPDF && gotSwf && gotData)mergedHandler();
		}
		protected function swfFileDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			gotSwf = true;		
			if ( gotSlide && gotPDF && gotSwf && gotData)mergedHandler();
		}
		protected function dataDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			gotData = true;		
			if ( gotSlide && gotPDF && gotSwf && gotData)mergedHandler();
		}
		protected function masterFileDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			masterLoadedHandler();
		}
		protected function resourceFileDownloadCompleteHandler( remoteUrl:String, localPath:String ):void
		{
			resourcesLoadedHandler();
		}
		
		private function mergedHandler():void{
			
			// hack to prevent "orange line" when progress is < 5 %
			if ( ( _numberOfFilesDownloaded / _numberOfFilesToDownload ) < .05 )
			{
				_popupAlert.progressBar.setProgress(5,100);
			}else{
				_popupAlert.progressBar.setProgress(_numberOfFilesDownloaded, _numberOfFilesToDownload);	
			}
			
			// whoa  - this will break on Mac if more than 815 slides 
			_popupAlert.bodyTextArea.text = "Downloaded " + _numberOfFilesDownloaded + " / " + _numberOfFilesToDownload;
			
			_numberOfFilesDownloaded++;			
			
			setTimeout(function(o:Object=null):void{ fileLoadManagerFunction(); },10);
		}
		private function masterLoadedHandler():void{
			
			//_popupAlert.bodyTextArea.text = "Downloaded " + _numberOfMastersDownloaded + " / " + _numberOfMastersToDownload;
			
			_numberOfMastersDownloaded++;			
			
			mastersLoadManagerFunction();
		}
		private function resourcesLoadedHandler():void{
			
			//_popupAlert.bodyTextArea.text = "Downloaded " + _numberOfMastersDownloaded + " / " + _numberOfMastersToDownload;
			
			_numberOfResourcesDownloaded++;			
			
			resourcesLoadManagerFunction();
		}
		
		private function filesLoadedComplete():void{
			
			trace("ALL SLIDE FILES HAVE BEEN DOWNLOADED");			
			
			slidesPDFsSwfsAndFlvsEnd();
		}
		private function mastersLoadedComplete():void{
			
			trace("ALL MASTER PDFS HAVE BEEN DOWNLOADED");			
			
			mastersEnd();
		}
		
		private function resourcesLoadedComplete():void{
			
			trace("ALL RESOURCES HAVE BEEN DOWNLOADED");			
			
			resourcesEnd();
		}
		
		//============================================================================================
		// END GAME
		//============================================================================================
		
		private function resourcesEnd():void
		{
			finishedResources = true;
			if ( finishedDownloadingEverything() )	dispatchEvent(new SlidesEvent(SlidesEvent.FINISHED_WRITING_FILES_TO_DISK));
		}
		
		private function slidesPDFsSwfsAndFlvsEnd():void
		{
			finishedSlidesAndPDFs = true;
			if ( finishedDownloadingEverything() )	dispatchEvent(new SlidesEvent(SlidesEvent.FINISHED_WRITING_FILES_TO_DISK));
		}
		private function mastersEnd():void
		{
			finishedMasters = true;
			if ( finishedDownloadingEverything() )	dispatchEvent(new SlidesEvent(SlidesEvent.FINISHED_WRITING_FILES_TO_DISK));
		}
		
		
		
		private function finishedDownloadingEverything():Boolean{
			return ( finishedMasters && finishedSlidesAndPDFs && finishedResources );
		}
		private function timeoutError():void
		{
			dispatchEvent(new SlidesEvent(SlidesEvent.DOWNLOAD_TIMEOUT));
		}
		
		
		//============================================================================================
		// GETTERS AND SETTERS
		//============================================================================================
		
		public function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
	}
}

