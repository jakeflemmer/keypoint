package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.view.TitleSlideWidget;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	
	import mx.controls.SWFLoader;
	
	public class SlidesEvent extends Event
	{
		
		public static const NAVIGATE:String = "navigate";
		public static const PREVIEW_PAGE:String = "previewPage";
		public static const CUSTOMIZE_PAGE:String = "customizePage";
		public static const PRINT_PAGE:String = "printPage";
		public static const PRESENT_PAGE:String = "presentPage";
		public static const PRESENTATIONS_LIST:String = "presentationsList";
		public static const RESOURCES_LIST:String = "resourcesList";
		public static const EXTERNAL_APPS_LIST:String = "externalAppsList";
		public static const LOGOUT:String = "logout";
		public static const RETURN_TO_BRANDS:String = "brands"; //NOTE
		public static const COPY_CUSTOM_PRESENTATION:String = "copyCustomPresentation";
		public static const FULL_SIZE_PREVIEW:String = "fullSizePreview";
		public static const DELETE_CUSTOM_PRESENTATION:String = "deleteCustomPresentation";
		public static const ZOOM_IN_ON_SLIDE:String = "zoomInOnSlide";
		public static const ADD_SLIDE_TO_WANTED_GROUP:String = "addSlideToWantedGroup";
		public static const PREVIEW_UNWANTED_SLIDE:String = "previewUnwantedSlide";
		public static const TITLE_SLIDE_CLOSED:String = "titleSlideClosed";
		public static const DELETED_LAST_CUSTOM_PRESENTATION:String = "deletedLastPresentation";
		public static const NEW_USER_DATA_LOADED:String = "newUserDataLoaded";
		public static const UPDATES_DATA_LOADED:String = "updatesDataLoaded";
		public static const FINISHED_WRITING_FILES_TO_DISK:String = "finishedWritingFilesToDisk";
		public static const LOGIN_COMPLETE:String = "loginComplete";
		public static const WE_ARE_WORKING:String = "weAreWorking";
		public static const PRINT_ALL_COMPLETE:String = "printAllComplete";
		public static const PRINT_SLIDE_COMPLETE:String = "printSlideComplete";
		public static const HIDE_WHILE_PRINTING:String = "hideWhilePrinting";
		public static const PDF_LOADED:String = "pdfLoaded";
		public static const UPDATE_PREVIEWING_SCREEN:String = "updatePreviewingScreen";	
		public static const SAFE_UPDATE_PREVIEWING_SCREEN:String = "safeUpdatePreviewingScreen";
		public static const OPTIONAL_DECK_HIDDEN:String = "optionalDeckHidden";
		public static const OPTIONAL_DECK_SHOWN:String = "optionalDeckShown";
		public static const SEND_SWF_FROM_PROJECTOR_TO_PREVIEW:String = "sendSwfFromProjectorToPreview";
		public static const DOWNLOAD_TIMEOUT:String = "downloadTimeout";
		public static const UPDATES_AND_DOWNLOADS_COMPLETE:String = "updatesAndDownloadsComplete";
		public static const EXTERNAL_APP_CLOSED:String = "externalAppClosed";
		public static const UPGRADE_SOFTWARE_VERSION_AVAILABLE:String = "upgradeSoftwareVersionAvailable";
		public static const HELP_LIST:String = "helpList";
		public static const SWAP_EITHER_OR_BUNDLE:String = "swapEitherOrBundle";
		public static const ON_ANIMATING_SWF_CLICK:String = "onAnimatingSwfClick";
		
		
		
		public var navigateToPage:String;
		public var presentationObject:Object;
		public var showCorePresentationsList:Boolean;
		public var bitmap:Bitmap;
		public var slide:Object;
		public var slides:Array;
		public var loadedSlidesMap:Object;
		public var dirtyFlag:Boolean;
		public var pdfLoaded:Object;
		public var frameCounter:uint;
		public var newHeight:Number;
		public var swfLoader:SWFLoader;
		public var titleSlideWidget:TitleSlideWidget;
		public var offlineLogIn:Boolean = false;
		public var hasNnpe:Boolean = false;
		public var hasExcel:Boolean = false;
		public var nnpeImageVisible:Boolean = false;
		
		
		public function SlidesEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}

