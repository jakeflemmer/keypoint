package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.html.HTMLLoader;
	import flash.net.URLRequest;
	
	public class PrintPDFsCommand extends EventDispatcher
	{
		
		public var pdfsFolder:File;
		public var mastersFolder:File;
		
		
		public function PrintPDFsCommand(target:IEventDispatcher=null)
		{
			super(target);
		}
		public function loadAPDF(slide:Object):void{
			
			//var url:String;
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;					
			
			pdfsFolder = File.applicationStorageDirectory.resolvePath("pdfs" + File.separator);
			//if( ! pdfsFolder.exists ) Alert.show("ERROR - slidesystemcontroller line 277 - model.slidesfolder does not exist");
			destinationFolder = pdfsFolder.resolvePath(slide.slide_id);			
			//if( ! destinationFolder.exists ) Alert.show("ERROR - slidesystemcontroller line 279 - destination folder does not exist");
			
			var slide_alone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone","slide_id",slide.slide_id);
			var thumbnail:String = slide_alone[0].printable_pdf;
			var filename:String = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
			localPath = destinationFolder.url +"/"+ filename;
			
			var actualPDFFile:File = destinationFolder.resolvePath(filename);

			actualPDFFile.openWithDefaultApplication();			

		}
		public function openTheMasterPDF(presentation:Object):void{
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;					
			
			mastersFolder = File.applicationStorageDirectory.resolvePath("masters" + File.separator);
			//if( ! pdfsFolder.exists ) Alert.show("ERROR - slidesystemcontroller line 277 - model.slidesfolder does not exist");
			destinationFolder = mastersFolder.resolvePath(presentation.presentation_id);			
			//if( ! destinationFolder.exists ) Alert.show("ERROR - slidesystemcontroller line 279 - destination folder does not exist");
			
			//var presentationObject:Object = dbModel.getPresentation(dbModel.systemSQLConnection,presentation.pre
			//var slide_alone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone","slide_id",slide.slide_id);
			var pdfUrl:String = presentation.printable_pdf;
			var filename:String = pdfUrl.substr((pdfUrl.lastIndexOf("/") + 1)); //text from last "/" to end 
			localPath = destinationFolder.url +"/"+ filename;
			
			var actualPDFFile:File = destinationFolder.resolvePath(filename);
			
			actualPDFFile.openWithDefaultApplication();			
		}
				
		private function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
	}
}