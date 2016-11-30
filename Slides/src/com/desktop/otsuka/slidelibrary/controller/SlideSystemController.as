package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.model.SlideSystemModel;
	import com.desktop.otsuka.slidelibrary.view.LoginView;
	import com.desktop.otsuka.slidelibrary.view.PopupAlert;
	import com.desktop.otsuka.slidelibrary.view.ResourcesListPanel;
	import com.desktop.otsuka.slidelibrary.view.SlideSystemView;
	import com.desktop.otsuka.slidelibrary.view.TitleSlideWidget;
	
	import flash.data.SQLConnection;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.Screen;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.System;
	
	import mx.controls.Alert;
	import mx.managers.PopUpManager;
	import mx.managers.SystemManager;
	
	//NOTE : Need to clear out memory
	
	public class SlideSystemController
	{
		
		private var view:SlideSystemView;
		private var model:SlideSystemModel = new SlideSystemModel();
		// V6 POPUPS private var loadingFilesAlert:PopupAlert; - now spinner instead
		
		private var presentationDomain:ApplicationDomain = new ApplicationDomain(ApplicationDomain.currentDomain);
		
		//======================================================================================================
		//   INIT AND REGISTER LISTENERS
		//======================================================================================================
		public function SlideSystemController($view:SlideSystemView)
		{
			this.view = $view;	
		}
		public function init():void{
			registerListeners();
		}
		private function registerListeners():void{
			view.loginView.addEventListener(SlidesEvent.UPDATES_AND_DOWNLOADS_COMPLETE,onFinishedLogIn);			
			view.presentationsListPanel.addEventListener(SlidesEvent.NAVIGATE,navigateToPage);	
			view.presentationsListPanel.addEventListener(SlidesEvent.DELETED_LAST_CUSTOM_PRESENTATION,onDeletedLastCustomPresentation);
			view.presentationSelectionPanel.addEventListener(SlidesEvent.NAVIGATE,navigateToPage);
			view.previewView.addEventListener(SlidesEvent.NAVIGATE,navigateToPage);
			view.presentView.addEventListener(SlidesEvent.NAVIGATE,navigateToPage); 
			view.presentViewV3OrAbove.addEventListener(SlidesEvent.NAVIGATE,navigateToPage); 
			view.loginView.addEventListener(SlidesEvent.NAVIGATE,navigateToPage);
		}
		//======================================================================================================
		//   HANDLERS
		//======================================================================================================
		private function onFinishedLogIn(e:Event):void{
			model.selectedBrandObject = (e.currentTarget as LoginView).selectedBrandObject; 
			view.loginView.visible = false;					
			
			var hasCustomPresentations:Boolean = view.presentationsListPanel.init(model.selectedBrandObject);
			view.presentationsListPanel.visible = true;
			view.presentationsListPanel.showTheCorePresentations();		
			
			view.presentationSelectionPanel.visible = true;
			view.externalAppsListPanel.visible = false;
			view.presentationSelectionPanel.setBrandImage(model.selectedBrandObject);
			view.presentationSelectionPanel.customPresentationsButton.enabled = hasCustomPresentations;
			
			setClinicalPathwaysButtonsStatus();
			setResourcesButtonsStatus();
		}
		private function setClinicalPathwaysButtonsStatus():void{
			switch ( ( model.selectedBrandObject.name as String).toLowerCase() )
			{
				case "nnpe":
					CreateDatabaseCommand.createExternalAppsDataTableIfItDoesntAlreadyExist();
					var externalAppsArray:Array = dbModel.getAll( dbModel.systemSQLConnection, "external_apps" );
					if ( externalAppsArray && externalAppsArray.length > 0 )
					{
						view.presentationSelectionPanel.clinicalPathwaysButton.visible = true;
					}else{
						view.presentationSelectionPanel.clinicalPathwaysButton.visible = false;
					}
					break
				case "excel":
					view.presentationSelectionPanel.clinicalPathwaysButton.visible = false;
					break
				default:
					Alert.show("Error : status code 07x342"); // the brand does not have a name ?!	
			}
		}
		private function setResourcesButtonsStatus():void{
			// hide or show the resources button
			//switch ( ( model.selectedBrandObject.name as String).toLowerCase() )
			//{
				//case "nnpe":
					// changed - if the brand is nnpe then simply show or hide the resources based on the visibility of the clinical pathways button
					// change 12/18 - show the resources button if resources are present for any brand
					//CreateDatabaseCommand.createExternalAppsDataTableIfItDoesntAlreadyExist();
					//view.presentationSelectionPanel.resourcesButton.visible = view.presentationSelectionPanel.clinicalPathwaysButton.visible;
					//break
				//case "excel":
//					if ( model.selectedBrandObject.hasOwnProperty("has_resources") == false )
//					{
//						view.presentationSelectionPanel.resourcesButton.visible = false;
//					}
//					else
//					{
//						if ( model.selectedBrandObject.has_resources ) 
//						{
//							view.presentationSelectionPanel.resourcesButton.visible = true;
//						}else{
//							view.presentationSelectionPanel.resourcesButton.visible = false;
//						}
//					}
					view.presentationSelectionPanel.resourcesButton.visible = ResourcesListPanel.userHasResources( model.selectedBrandObject );
					//break
				//default:
					//Alert.show("Error : status code 07x342"); // the brand does not have a name ?!	
			//}
		}
		//======================================================================================================
		//   NAVIGATE
		//======================================================================================================
		private function freeImagesFromMemory():void{
			if ( model.loadedSlidesMap != null)
			{
				trace("system total memory : " + System.totalMemory / 1024);
				for ( var k:Object in model.loadedSlidesMap )
				{
					if ( model.loadedSlidesMap[k] is Bitmap )
					{
						 
						
						(model.loadedSlidesMap[k] as Bitmap).bitmapData.dispose();
						model.loadedSlidesMap[k] = null;
						
					}
				}
				model.loadedSlidesMap = null;
				System.gc();
				trace("system total memory 2 : " + System.totalMemory / 1024);
			}
			
		}
		private function navigateToPage(se:SlidesEvent):void{
			
			model.selectedPresentationObject = se.presentationObject;
			
			switch (se.navigateToPage)
			{
				case SlidesEvent.PREVIEW_PAGE:
					
					freeImagesFromMemory();
					
					
					view.presentView.visible = false;
					view.presentViewV3OrAbove.visible = false;
					view.fullSizeVideoPreviewWindowGroup.visible = false; //NOTE ensure the video audio is not playing
					view.fullSizePreviewVideoWindow.stop();
					//System.pauseForGCIfCollectionImminent(1); 
					initializePreviewMode();
					break;
				
				case SlidesEvent.PRESENT_PAGE:
					//freeImagesFromMemory();
					var numberOfScreen:Array = Screen.screens;
					/*if ( numberOfScreen.length < 2 )
					{
					//Alert.show("You must connect computer to external display before being able to present","Alert");
					
					return;
					}	*/
					initializePresentMode(se)					
					break;
				
				case SlidesEvent.CUSTOMIZE_PAGE:
					
					//freeImagesFromMemory();
					
					dbModel._activateKeys=false;
					System.pauseForGCIfCollectionImminent(1); 
					initailizeCustomizeMode();
					break;
				
				case SlidesEvent.PRESENTATIONS_LIST:
					showPresenationsList(se.showCorePresentationsList);
					dbModel._activateKeys=false;
					break;
				
				case SlidesEvent.RESOURCES_LIST:
					showResourcesList();
					dbModel._activateKeys=false;
					break;
				case SlidesEvent.EXTERNAL_APPS_LIST:
					showExternalAppsList();
					dbModel._activateKeys=false;
					break;
				// V6
				case SlidesEvent.HELP_LIST:
					showHelpList( se.nnpeImageVisible );
					dbModel._activateKeys =false;
					break;
				case SlidesEvent.FULL_SIZE_PREVIEW:
					System.pauseForGCIfCollectionImminent(1); 
					//dbModel._activateKeys=false;
					var slide:Object = se.slide;
					var titleSlideWidget:TitleSlideWidget = se.titleSlideWidget;
					if ( titleSlideWidget )
					{
						view.titleSlideWindow.visible = true;
						//titleSlideWidget.inEditMode = false;
						
						view.titleSlideWindow.inEditMode = false;  //This title widget is disabled on Full Preview Screen 
						view.titleSlideWindow.resetLabelsToDefaults();
						view.titleSlideWindow.chosenName = titleSlideWidget.chosenName;
						view.titleSlideWindow.chosenDateString = titleSlideWidget.chosenDateString;
						view.titleSlideWindow.scaleX = 1000/700;
						view.titleSlideWindow.scaleY = 700/500;
						
					}else{
						view.titleSlideWindow.visible = false;
					}
					if ( SlidesUtilities.slideIsVideo(slide))
					{
						view.fullSizeVideoPreviewWindowGroup.visible = true; 
						view.fullSizePreviewVideoWindow.source = slide.flvPath;
						view.fullSizePreviewVideoWindow.play();
					}
					else if ( SlidesUtilities.slideIsSwf(slide))
					{
						var urlRequest:URLRequest = new URLRequest(slide.swfPath);
						var loader:Loader = new Loader();
						loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loadedSwfForFullScreenPreview);
						loader.load( urlRequest );						
					}
					else
					{
						view.fullSizePreviewWindowGroup.visible = true;
						view.fullSizePreviewWindow.source = se.bitmap;	
					}
					//view.fullSizePreviewWindow.width = 1000; dont think this is necessary
					//view.fullSizePreviewWindow.height = 700;
					break
				
				case SlidesEvent.LOGOUT:
					dbModel.mustDropOldTables = true; 
					dbModel._activateKeys=false;
					System.pauseForGCIfCollectionImminent(1); 
					hideAllViews();
					view.loginView.reset();
					view.loginView.visible = true;
					var lastUser:Array = dbModel.getLastUserFromUsersTable(); //will return null if 'users' table doesn't exist
					if ( lastUser == null || lastUser.length == 0 )
					{
						view.loginView.loginPanel.checkForUpgadeVersionOfKeypoint(null);						
					}else{
						view.loginView.loginPanel.checkForUpgadeVersionOfKeypoint(lastUser[0].user_hash);
					}
					break;
				
				case SlidesEvent.RETURN_TO_BRANDS:
					System.pauseForGCIfCollectionImminent(1); 
					hideAllViews();
					//view.loginView.gotoBrandsPage();
					view.loginView.gotoBrandsPage();	
					view.loginView.visible=true;
					dbModel._activateKeys = false;
					
					//	view.presentationSelectionPanel.visible=true;
					break;
			}
		}
		private function loadedSwfForFullScreenPreview(event:Event):void{
			
			(event.target).removeEventListener(Event.COMPLETE, fileLoaderHandler);
			
			var object:Object = event.target.loader;//.content;
			
			view.fullSizePreviewWindow.source = object;		
			
			view.fullSizePreviewWindowGroup.visible = true;
		}
		//		public function displayTitleSlideWidget(titleSlideWidget:TitleSlideWidget):void{
		//			
		//			titleSlideWidget.scaleX = view.titleSlideWidgetGroup.width/titleSlideWidget.width;
		//			titleSlideWidget.scaleY = view.titleSlideWidgetGroup.height/titleSlideWidget.height;
		//			view.titleSlideWidgetGroup.addElement( titleSlideWidget );
		//		}
		
		//======================================================================================================
		//   PRESENTATIONS LIST
		//======================================================================================================
		
		private function showPresenationsList(showCorePresentationsList:Boolean):void{
			hideAllLists();
			
			view.presentationsListPanel.visible = true;
			view.presentationsListPanel.init(model.selectedBrandObject);
			if ( showCorePresentationsList )
			{
				view.presentationsListPanel.showTheCorePresentations();
			}
			else
			{
				
				view.presentationsListPanel.showTheCustomPresentations();
				
			}
		}
		
		private function onDeletedLastCustomPresentation(se:SlidesEvent):void{
			view.presentationSelectionPanel.customPresentationsButton.enabled = false;
			showPresenationsList(true);
		}
		
		//======================================================================================================
		//   RESOURCES LIST
		//======================================================================================================
		
		private function showResourcesList():void{
			hideAllLists();
			
			view.resourcesListPanel.visible = true;
			view.resourcesListPanel.init(model.selectedBrandObject);
			view.resourcesListPanel.showTheResources();
		}
		
		private function showExternalAppsList():void{
			hideAllLists();
			
			view.externalAppsListPanel.visible = true;
			view.externalAppsListPanel.init();
		}
		
		private function showHelpList( nnpeImgVisible:Boolean ):void{
			hideAllLists();
			
			view.helpListPanel.visible = true;
			view.helpListPanel.init(nnpeImgVisible);	 
		}
		
		private function hideAllLists():void{
			view.previewView.visible = false;
			view.customizeView.visible = false;
			view.presentationsListPanel.visible = false;
			view.externalAppsListPanel.visible = false;
			view.resourcesListPanel.visible = false;
			view.helpListPanel.visible = false;
		}
		
		//======================================================================================================
		//   PREVIEW MODE
		//======================================================================================================
		
		private function initializePreviewMode():void{
			
			model.callBackAfterLoadingSlidesIntoApplicationCache = startPreviewMode;
			var slidesToLoad:Array = getAllThePresentationSlides(model.selectedPresentationObject);
			loadAllTheseSlidesIntoApplicationCache(slidesToLoad);
		}		
		private function startPreviewMode():void{
			view.presentationsListPanel.visible = false;
			view.previewView.init(model.slidesToLoadIntoApplicationCache ,model, model.selectedPresentationObject);
			view.previewView.visible = true;
			view.titleLabel.visible = false;			
		}
		
		//======================================================================================================
		//   PRESENT MODE
		//======================================================================================================
		private function initializePresentMode(se:SlidesEvent):void{
			model.slidesToPresent = se.slides;
			model.selectedPresentationObject = se.presentationObject;
			model.callBackAfterLoadingSlidesIntoApplicationCache = startPresentMode;
			var slidesToLoad:Array = getAllThePresentationSlides(model.selectedPresentationObject);
			model.loadingForPresentMode = true;
			
			// for V3 we can refactor the whole load of PresentView and PresentView 
			if ( SlidesUtilities.testSlidesAloneDataTableForV3Compatability()) // return true if IS compatible
			{
				model.loadingV3OrAboveSlides = true;
			}else{
				model.loadingV3OrAboveSlides = false;
			}
			
			loadAllTheseSlidesIntoApplicationCache(slidesToLoad);
			
		}		
		private function startPresentMode():void{			
			model.loadingForPresentMode = false;
			if ( model.loadingV3OrAboveSlides )
			{
				view.presentViewV3OrAbove.init(model.slidesToPresent, model.loadedSlidesMap, model.selectedPresentationObject);
				view.presentViewV3OrAbove.visible = true;
			}else{
				view.presentView.init(model.slidesToPresent, model.loadedSlidesMap, model.selectedPresentationObject);
				view.presentView.visible = true;
			}			
			
		}
		//============================================
		// CUSTOMIZE MODE
		//============================================
		
		private function initailizeCustomizeMode():void{
			var allSlides:Array;
			var presentationSlidesToLoad:Array = getAllThePresentationSlides(model.selectedPresentationObject);
			
			
			if ( dbModel.presentationIsCustomPresentation(model.selectedPresentationObject))	// hasnt been saved as a custom yet
			{				
				allSlides = presentationSlidesToLoad;
			}
			else
			{
				allSlides = presentationSlidesToLoad;
				var optionalSlidesToLoad:Array = SlidesUtilities.getAllTheOptionalSlidesAssociatedToCorePresentation(model.selectedPresentationObject.presentation_id);
				if (optionalSlidesToLoad && optionalSlidesToLoad.length > 0 )
				{
					for ( var i:uint = 0; i < optionalSlidesToLoad.length;i++)
					{
						var optionalSlide:Object = optionalSlidesToLoad[i];
						optionalSlide.unwanted = true;
						allSlides.push(optionalSlide);
					}
				}				
			}
			model.callBackAfterLoadingSlidesIntoApplicationCache = openCustomizeMode;
			loadAllTheseSlidesIntoApplicationCache(allSlides);		
		}
		private function openCustomizeMode():void{
			
			view.presentationSelectionPanel.visible = false;
			view.presentationsListPanel.visible = false;
			view.externalAppsListPanel.visible = false;
			view.previewView.visible = false;
			
			view.customizeView.addEventListener("CLOSE_VIEW", onCloseCustomView);
			view.customizeView.init(model.selectedPresentationObject, model.slidesToLoadIntoApplicationCache,model);
			view.customizeView.visible = true;
			
		}
		private function onCloseCustomView(e:Event):void{
			view.customizeView.visible = false;
			
			
			var hasCustomPresentations:Boolean = view.presentationsListPanel.init(model.selectedBrandObject);
			
			view.presentationSelectionPanel.visible = true;			
			view.presentationSelectionPanel.customPresentationsButton.enabled = hasCustomPresentations;			
			
			view.presentationSelectionPanel.visible = true;
			view.previewView.visible = true;
			view.previewView.init(model.slidesToLoadIntoApplicationCache ,model, model.selectedPresentationObject);
		}
		
		
		
		
		
		
		
		
		//========================================================================================
		//========================================================================================
		//========================================================================================
		//========================================================================================
		//========================================================================================
		//========================================================================================
		
		
		//				LOADING
		
		
		
		
		//============================================
		// GET SLIDES
		//============================================
		
		//private function getAllThePresentationSlides(presentationObject:Object, preProcessEitherOrComboBundles:Boolean = true):Array{
		private function getAllThePresentationSlides(presentationObject:Object):Array{
			var connection:SQLConnection;
			var presId:uint;
			var coreSlides:Array;
			
			if ( ! dbModel.presentationIsCustomPresentation(presentationObject) )
			{
				connection = dbModel.systemSQLConnection;
				presId = presentationObject.presentation_id;
				coreSlides = dbModel.getWhere(connection, "slides","presentation_id",presId );
				if ( coreSlides == null || coreSlides.length < 1 )
				{
					Alert.show("There has been an error opening customized presentation " + presentationObject.custom_title + " which has id of " + presId + ". This deck may have become corrupted.", "ERROR");
					return null;
				}
				
//				if ( preProcessEitherOrComboBundles )
//				{
//					var eitherOrSlidesToAdd:Array = SlidesUtilities.preProcessCoreDecksForEitherOrBundleRule(presId);
//					if ( eitherOrSlidesToAdd && eitherOrSlidesToAdd.length > 0 )
//					{
//						for ( var i:uint = 0 ; i < eitherOrSlidesToAdd.length; i++ ) {
//							coreSlides.push(eitherOrSlidesToAdd[i]);
//						
//						}
//					}
//				}
				return coreSlides;
			}
			else
			{
				// CUSTOM
				connection = dbModel.customSQLConnection;
				presId = presentationObject.custom_presentation_id;
				coreSlides = dbModel.getWhere(connection, "slides","presentation_id",presId );
				if ( coreSlides == null || coreSlides.length < 1 )
				{
					Alert.show("There has been an error opening customized presentation " + presentationObject.custom_title + " which has id of " + presId + ". This deck may have become corrupted.", "ERROR");
					return null;
				}
				return coreSlides;
				// get the optional decks associated to this presenation
				// get all the slides from all these optional decks
				// for now i am simplifying my life - as soon as they customize a deck all of the optional slides get put in the slides table		
			}
		}
		
		
		//============================================
		// LOAD SLIDES
		//============================================
		
		private function loadAllTheseSlidesIntoApplicationCache(slidesToLoad:Array):void{
			model.slidesToLoadIntoApplicationCache = slidesToLoad;
			openTheLoadingAlertPopup();
			downloadAllSlideImages();
		}
		private function openTheLoadingAlertPopup():void{
			
			view.customSpinner.startSpinner();
			/*
			// POPUP ALERT
			loadingFilesAlert = PopupAlert(PopUpManager.createPopUp(view, PopupAlert, true));
			loadingFilesAlert.buttonsHGroup.visible = false;
			loadingFilesAlert.setWidthAndHeight(300,100);
			loadingFilesAlert.titleBarImage.visible = true;
			loadingFilesAlert.titleLabel.text = "Loading Slides";			
			PopUpManager.centerPopUp(loadingFilesAlert);
			*/
		}
		private function downloadAllSlideImages():void
		{				
			model.numberOfSlidesLoaded = 0;			
			loadTheNextSlidesFiles();
		}	
		private function loadTheNextSlidesFiles():void{
			if(model.slidesToLoadIntoApplicationCache[model.numberOfSlidesLoaded] !=null){ //safe gaurd when someone presses escape before running presentation	
				var slide:Object = model.slidesToLoadIntoApplicationCache[model.numberOfSlidesLoaded];
				loadASlide(slide);
			}
		}
		private function oneSlideLoadedHandler():void{
			model.numberOfSlidesLoaded++;
			if ( model.slidesToLoadIntoApplicationCache.length > model.numberOfSlidesLoaded )
			{				
				// V6 POPUPS loadingFilesAlert.bodyTextArea.text = "Loading files... " + model.numberOfSlidesLoaded + "/" + model.slidesToLoadIntoApplicationCache.length;
				loadTheNextSlidesFiles();
			}else{				
				model.callBackAfterLoadingSlidesIntoApplicationCache();
				// V6 POPUPS loadingFilesAlert.close();
				view.customSpinner.closeSpinner();
			}		
		}
		//=============================================
		// LOADING FILES
		//==============================================
		
		private var loader:Loader;
		
		public function loadASlide(slide:Object):void{
			
			if ( model.loadedSlidesMap == null ) model.loadedSlidesMap = new Object();
			
			if ( model.loadingV3OrAboveSlides )
			{
				loadAV3OrAboveSlide(slide);
				return;
			}
			
			
			var loadingSwf:Boolean = false;
			
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;					
			
			model.storageFolder = File.applicationStorageDirectory.resolvePath("slides" + File.separator);
			destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
			
			var slide_alone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone","slide_id",slide.slide_id);
			
			var thumbnail:String;
			var filename:String; 
			var slideObject:Object =  slide_alone[0];
			
			thumbnail = slideObject.thumbnail;
			filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
			localPath = destinationFolder.url +"/"+ filename;
			
			model.urlBeingLoaded = localPath;
			model.slideIdBeingLoaded = slide.slide_id;
			
			if ( model.loadingForPresentMode )
			{
				if ( SlidesUtilities.slideIsVideo(slideObject))
				{
					model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
					destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
					destinationFolder = destinationFolder.resolvePath("data");
					thumbnail = slideObject.flv;
					filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
					localPath = destinationFolder.url +"/"+ filename;
					model.loadedSlidesMap[model.slideIdBeingLoaded+"flv"] = localPath;
					oneSlideLoadedHandler();
					return;
				}
				else if ( SlidesUtilities.slideIsSwf(slideObject))
				{
					model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
					destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
					thumbnail = slide_alone[0].swf;
					filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
					localPath = destinationFolder.url +"/"+ filename;
					
					model.urlBeingLoaded = localPath;
					model.slideIdBeingLoaded = slide.slide_id;
					
					model.loadedSlidesMap[model.slideIdBeingLoaded+"swfPath"] = localPath;
					loadingSwf = true;
					oneSlideLoadedHandler();
					return;
				}
				else
				{
					oneSlideLoadedHandler();
					return;
				}
			}
			// well lets just always put the swfPath and flvPath on so we can do full screen preview from preview screen
			if ( SlidesUtilities.slideIsVideo(slideObject))
			{
				model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
				destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
				destinationFolder = destinationFolder.resolvePath("data");
				thumbnail = slideObject.flv;
				filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
				var flvPath:String = destinationFolder.url +"/"+ filename;
				model.loadedSlidesMap[model.slideIdBeingLoaded+"flvPath"] = flvPath;
			}
			else if ( SlidesUtilities.slideIsSwf(slideObject))
			{
				// just record the swfPath
				model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
				destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
				thumbnail = slide_alone[0].swf;
				filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
				var swfPath:String = destinationFolder.url +"/"+ filename;		
				model.loadedSlidesMap[slide.slide_id +"swfPath"] = swfPath;
			}
			else
			{
				//do nothing
			}
			
			var urlRequest:URLRequest = new URLRequest(localPath);			
			
			// if it is the map don't reload it !
			if ( model.loadedSlidesMap[model.urlBeingLoaded] != null )
			{
				oneSlideLoadedHandler();
				return;
			}			
			//var loader:Loader = new Loader();
			 loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, fileLoaderHandler);
			trace("trying to load url : " + model.urlBeingLoaded );
			
			if ( loadingSwf )
			{
				loader.load( urlRequest , new LoaderContext(false,presentationDomain));	
			}
			else{
				loader.load( urlRequest );
			}
			
		}
		
		
		
		
		//=============================================
		// LOADING V3 OR ABOVE SLIDES !
		//==============================================		
		// REFACTOR FOR V3 SLIDES
		public function loadAV3OrAboveSlide(slide:Object):void{
			
			// With V3 we have a change to the way we are loading slides
			// ` now we know if we can use just an image or if we have to load a swf because there is a build or animation
			// 			( before we had to assume every slide was a build/animation and load its swf )
			
			//if ( model.loadedSlidesMap == null ) model.loadedSlidesMap = new Object();
			
			var loadingSwf:Boolean = false;
			
			var localPath:String;
			var localFile:File;
			var destinationFolder:File;					
			
			model.storageFolder = File.applicationStorageDirectory.resolvePath("slides" + File.separator);
			destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
			
			var slide_alone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone","slide_id",slide.slide_id);
			
			var thumbnail:String;
			var filename:String; 
			var slideObject:Object =  slide_alone[0];
			
			thumbnail = slideObject.thumbnail;
			filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
			localPath = destinationFolder.url +"/"+ filename;
			
			model.urlBeingLoaded = localPath;
			model.slideIdBeingLoaded = slide.slide_id;
			
			if ( model.loadingForPresentMode )
			{
				if ( SlidesUtilities.slideIsVideo(slideObject))
				{
					model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
					destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
					destinationFolder = destinationFolder.resolvePath("data");
					thumbnail = slideObject.flv;
					filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
					localPath = destinationFolder.url +"/"+ filename;
					model.loadedSlidesMap[model.slideIdBeingLoaded+"flv"] = localPath;
					oneSlideLoadedHandler();
					return;
				}
				else if ( SlidesUtilities.slideIsAnimatingSwf(slideObject) )
				{
					model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
					destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
					thumbnail = slide_alone[0].swf;
					filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
					localPath = destinationFolder.url +"/"+ filename;
					
					model.urlBeingLoaded = localPath;
					model.slideIdBeingLoaded = slide.slide_id;
					
					model.loadedSlidesMap[model.slideIdBeingLoaded+"swfPath"] = localPath;
					loadingSwf = true;
					oneSlideLoadedHandler();
					return;
				}
				else
				{
					oneSlideLoadedHandler();
					return;
				}
			}
			// well lets just always put the swfPath and flvPath on so we can do full screen preview from preview screen
			if ( SlidesUtilities.slideIsVideo(slideObject))
			{
				model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
				destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
				destinationFolder = destinationFolder.resolvePath("data");
				thumbnail = slideObject.flv;
				filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
				var flvPath:String = destinationFolder.url +"/"+ filename;
				model.loadedSlidesMap[model.slideIdBeingLoaded+"flvPath"] = flvPath;
			}
			else if ( SlidesUtilities.slideIsSwf(slideObject))
			{
				// just record the swfPath
				model.storageFolder = File.applicationStorageDirectory.resolvePath("swfs" + File.separator);
				destinationFolder = model.storageFolder.resolvePath(slide.slide_id);			
				thumbnail = slide_alone[0].swf;
				filename = thumbnail.substr((thumbnail.lastIndexOf("/") + 1)); //text from last "/" to end 
				var swfPath:String = destinationFolder.url +"/"+ filename;		
				model.loadedSlidesMap[slide.slide_id +"swfPath"] = swfPath;
			}
			else
			{
				//do nothing
			}
			
			var urlRequest:URLRequest = new URLRequest(localPath);			
			
			// if it is the map don't reload it !
			if ( model.loadedSlidesMap[model.urlBeingLoaded] != null )
			{
				oneSlideLoadedHandler();
				return;
			}			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, fileLoaderHandler);
			trace("trying to load url : " + model.urlBeingLoaded );
			
			if ( loadingSwf )
			{
				loader.load( urlRequest , new LoaderContext(false,presentationDomain));	
			}
			else{
				loader.load( urlRequest );
			}
			
		}
		private function fileLoaderHandler(event:Event):void{
			
			(event.target).removeEventListener(Event.COMPLETE, fileLoaderHandler);
			
			var object:Object;// = event.target.loader.content;
			
			if ( model.loadingForPresentMode )
			{
				object = event.target.loader;
				model.loadedSlidesMap[model.slideIdBeingLoaded+"swf"] = object;
				//model.loadedSlidesMap[model.urlBeingLoaded] = true; we dont do this here b/c after presenting all the swfs will be unloaded
			}
			else
			{
				object = event.target.loader.content;
				model.loadedSlidesMap[model.slideIdBeingLoaded] = object;
				model.loadedSlidesMap[model.urlBeingLoaded] = true;
			}			
			oneSlideLoadedHandler();
		}
		//======================================================================================================
		//   UTILITY FUNCTIONS
		//======================================================================================================
		private function hideAllViews():void{
			view.presentationSelectionPanel.visible=false;
			view.presentationsListPanel.visible = false;
			view.resourcesListPanel.visible = false;
			view.previewView.visible=false;
			view.externalAppsListPanel.visible = false;
			view.helpListPanel.visible = false;
		}
		
		private function arraysCombined(presentationSlidesToLoad:Array,optionalSlidesToLoad:Array):Array{
			var combinedArray:Array = new Array();
			var i:uint;
			for ( i=0; i < presentationSlidesToLoad.length; i++)
			{
				combinedArray.push(presentationSlidesToLoad[i]);
			}
			if ( optionalSlidesToLoad && optionalSlidesToLoad.length > 0 )
			{
				for ( i=0; i < optionalSlidesToLoad.length; i++)
				{
					combinedArray.push(optionalSlidesToLoad[i]);
				}
			}
			return combinedArray;
		}
		//======================================================================================================
		//   GETTERS AND SETTERS
		//======================================================================================================
		
		private function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
		
		
	}
}
