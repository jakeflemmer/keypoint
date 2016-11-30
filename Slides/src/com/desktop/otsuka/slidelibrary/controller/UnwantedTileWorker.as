package com.desktop.otsuka.slidelibrary.controller
{
	
	
	import com.desktop.otsuka.slidelibrary.controller.SlidesEvent;
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.CustomizeView;
	import com.desktop.otsuka.slidelibrary.view.OptionalDecksManager;
	import com.desktop.otsuka.slidelibrary.view.UnwantedCoreTile;
	import com.desktop.otsuka.slidelibrary.view.UnwantedOptionalTile;
	import com.desktop.otsuka.slidelibrary.view.UnwantedSlideRenderer;
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.utils.setTimeout;
	
	import mx.collections.ArrayCollection;
	import mx.core.DragSource;
	import mx.core.UIComponent;
	import mx.managers.DragManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Image;
	import spark.components.Scroller;
	import spark.components.VGroup;
	import spark.skins.spark.ScrollerSkin;
	
	import flashx.textLayout.formats.WhiteSpaceCollapse;
	
	
	
	public class UnwantedTileWorker extends EventDispatcher
	{
		
//		[Bindable]
//		public var unwantedSlidesVGroupVisible:Boolean;
		
		private var _presentationObject:Object;
		public var _unwantedSlidesAC:ArrayCollection;
		public var _loadedAnySlidesMap:Object;
		private var unwantedSlidesVGroup:VGroup;
		private var arrowImage:Image;
		private var unwantedRenderersMap:Object = new Object();
		private var optionalDeckId:uint;
		
	//	public var OptionalActive:Boolean = false;//NOTE
		
		
		public function UnwantedTileWorker($unwantedSlidesVGroup:VGroup,$arrowImage:spark.components.Image, $presentationObject:Object,optional_deck_id:uint)
		{
			unwantedSlidesVGroup = $unwantedSlidesVGroup;
			arrowImage = $arrowImage;
			_presentationObject = $presentationObject;
			optionalDeckId = optional_deck_id;
			if ( ! $presentationObject) {
				throw new Error("error");
			}
		}
		
		public function populateUnwantedSlides():void{
			
			unwantedSlidesVGroup.removeAllElements();
			
			// JAKE LEFT SIDE SEQUENCE SORT CODE BELOW
			_unwantedSlidesAC.source.sortOn("sequence", Array.NUMERIC);
			_unwantedSlidesAC.refresh();
			// END
			
			var rowsArray:Array = new Array();
			var row:HGroup = makeUnwantedHGroupRow();
			var rowCounter:uint = 0;				
			var unfinishedRow:Boolean = true;
			
			rowsArray.push(row);
			
			for ( var i:uint = 0 ; i < _unwantedSlidesAC.length; i++ )
			{
				
				unfinishedRow = true;
				
				// TODO OPTIMIZE ( by making maps so we don't create new renderers when we already have them )
				//make the renderer
				var bitmap:Bitmap = _loadedAnySlidesMap[_unwantedSlidesAC[i].slide_id] as Bitmap;
				var unwantedSlide:Object = _unwantedSlidesAC[i];
				
				if ( optionalDeckId > 0 )
				{	//dbModel._optionalActive=true;
					if ( unwantedSlide.optional_deck_id != optionalDeckId )
					{
						continue;
					}
					
				}
			
			//	trace("Optional DECK ID "+optionalDeckId); //Acive when the Optional Button is pressed to open its TAB
				
				var unwantedRenderer:UnwantedSlideRenderer;
				if ( unwantedRenderersMap[unwantedSlide.sec_slide_id_plus_cust_pres_id] == null )
				{
					unwantedRenderer = makeNewUnwantedRendererAndAddListeners();
					unwantedRenderer.init(unwantedSlide);
					unwantedRenderersMap[unwantedSlide.sec_slide_id_plus_cust_pres_id] = unwantedRenderer;
				}else{
					unwantedRenderer = unwantedRenderersMap[unwantedSlide.sec_slide_id_plus_cust_pres_id];
					unwantedRenderer.init(unwantedSlide);
				}
				
				unwantedRenderer.updateSource(bitmap);
				
				row = rowsArray[rowCounter] as HGroup;
				
				if ( row.numChildren < 1 )
				{
					row.addElement(unwantedRenderer);
				}
				else if ( row.numChildren == 1 )
				{
					unfinishedRow = false;
					row.addElement(unwantedRenderer);
					unwantedSlidesVGroup.addElement(row);	
					rowsArray.push(makeUnwantedHGroupRow());
					rowCounter++;
				}
			}
			if ( unfinishedRow && _unwantedSlidesAC.length > 0 )
			{
				unwantedSlidesVGroup.addElement(row);	
			}
			
			//unwantedSlidesVGroup.dispatchEvent(new Event('hidingSlides'));
			//unwantedSlidesVGroup.dispatchEvent(new Event('showingSlides'));
		}
		private function makeNewUnwantedRendererAndAddListeners():UnwantedSlideRenderer{
			var unwantedRenderer:UnwantedSlideRenderer = new UnwantedSlideRenderer();
			unwantedRenderer.addEventListener("REMOVE_ME", onRemoveUnwantedSlide);
			unwantedRenderer.addEventListener("PREVIEW_ME", onZoomInOnUnwantedSlide);
			unwantedRenderer.addEventListener(MouseEvent.MOUSE_MOVE,mouseMoveHandler);
			return unwantedRenderer;
		}
		protected function baseClassRepopulate():void{
			unwantedSlidesVGroup.removeAllElements();
			populateUnwantedSlides();
			arrowImage_clickHandler(null); // so scroll bar can adjust
			arrowImage_clickHandler(null);
		}
		
		protected function removeUnwantedSlideAndRepopulate(slide:Object):void{
			for ( var i :uint = 0 ; i < _unwantedSlidesAC.length; i++)
			{
				var coreSlide:Object = _unwantedSlidesAC.getItemAt(i);
				if ( coreSlide.sec_slide_id_plus_cust_pres_id == slide.sec_slide_id_plus_cust_pres_id)
				{
					_unwantedSlidesAC.removeItemAt(i);
					break;
				}
			}
			unwantedSlidesVGroup.removeAllElements();
			populateUnwantedSlides();
			arrowImage_clickHandler(null); // so scroll bar can adjust
			arrowImage_clickHandler(null);
			
		}
		
		//================================================================================================
		// DRAG DROP HANDLERS
		//================================================================================================
		
		public function onRemoveUnwantedSlideThroughDragDrop(slide:Object):void{
//			if ( slide.bundle_id && slide.bundle_id as int > 0 )
//			{
//				removeAllBundledSlides(slide);
//				return;
//			}
			removeUnwantedSlideAndRepopulate(slide);
			/*
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.ADD_SLIDE_TO_WANTED_GROUP);
			se.slide = slide;
			dispatchEvent(se);	*/
		}
		
		//================================================================================================
		// CLICK HANDLERS
		//================================================================================================
		
		protected function onRemoveUnwantedSlide(e:Event):void{
						
			if ( !_presentationObject.sequence_locked ) return;		// cause else we drag it instead
			 
			var unwantedSlideRenderer:UnwantedSlideRenderer = ( e.currentTarget as UnwantedSlideRenderer);
			var slide:Object = unwantedSlideRenderer.slide;
			
			// if this is a swappable slide then do swapping instead of removing
			if ( slide.is_swappable ) {
				
				if (SlidesUtilities.slideIsBundledSlide(slide))
				{
					removeAllBundledSlides(slide);
				}
				else
				{
					removeUnwantedSlideAndRepopulate(slide);
					var se:SlidesEvent = new SlidesEvent(SlidesEvent.ADD_SLIDE_TO_WANTED_GROUP);
					se.slide = slide;
					dispatchEvent(se);
				}
				
				//disptch a swap event to get the swap mate(s) off the grid
				var sse:SlidesEvent = new SlidesEvent(SlidesEvent.SWAP_EITHER_OR_BUNDLE);
				sse.slide = slide;
				dispatchEvent(sse);
				return;
				
			}
				
			if ( slide.bundle_id && slide.bundle_id as int > 0 && SlidesUtilities.bundledSlideIsInKeepWholeBundle(slide) )
			{
				removeAllBundledSlides(slide);
				return;
			}
			if ( SlidesUtilities.slideIsBundledSlide(slide) && SlidesUtilities.bundledSlideIsInKeepWholeBundle(slide) == false )
			{
				// if all the slides in this bundle are all unwanted clicking one should restore the whole bundle
				if ( SlidesUtilities.allSlidesInThisNonKeepWholeBundleAreAlreadyUnwanted(_unwantedSlidesAC.source, slide.bundle_id,_presentationObject.custom_presentation_id) )
				{
					removeAllBundledSlides(slide);
					return;
				}
			}
			removeUnwantedSlideAndRepopulate(slide);
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.ADD_SLIDE_TO_WANTED_GROUP);
			se.slide = slide;
			dispatchEvent(se);
		}
		
		protected function removeAllBundledSlides(slide:Object):void{
			var slidesToRemove:Array = new Array();
			for ( var i:uint = 0 ; i < _unwantedSlidesAC.length; i++)
			{
				var theSlide:Object = _unwantedSlidesAC.getItemAt(i);
				if ( theSlide.bundle_id as int == slide.bundle_id as int )
				{
					slidesToRemove.push(theSlide);	
				}
			}
//			for ( var j:uint = 0 ; j < slidesToRemove.length; j++)
//			{
//				var slideBeingRemoved:Object = slidesToRemove[j];
//				removeBundledSlideOneAtATime(slideBeingRemoved);
//			}
			removeBundledSlidesAllTogether(slidesToRemove);
			
		}
		protected function removeBundledSlidesAllTogether(slidesArray:Array):void{
			for ( var i:uint =0; i < slidesArray.length; i++)
			{
				removeUnwantedSlideAndRepopulate(slidesArray[i]);
			}			
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.ADD_SLIDE_TO_WANTED_GROUP);
			se.slides = slidesArray;
			dispatchEvent(se);
		}
//		protected function removeBundledSlideOneAtATime(slide:Object):void{
//			removeUnwantedSlideAndRepopulate(slide);
//			var se:SlidesEvent = new SlidesEvent(SlidesEvent.ADD_SLIDE_TO_WANTED_GROUP);
//			se.slide = slide;
//			dispatchEvent(se);
//		}
		
		protected function onZoomInOnUnwantedSlide(e:Event):void{
			var unwantedSlideRenderer:UnwantedSlideRenderer = ( e.currentTarget as UnwantedSlideRenderer);
			var slide:Object = unwantedSlideRenderer.slide;
			var se:SlidesEvent = new SlidesEvent(SlidesEvent.ZOOM_IN_ON_SLIDE);
			se.bitmap = unwantedSlideRenderer.thumbnailImage.source as Bitmap;
			se.slide = slide;
			dispatchEvent(se);
		}
		
		private function mouseMoveHandler(event:MouseEvent):void 
		{      
			//if ( _presentationObject.sequence_locked )return;
			var dragInitiator:Group = Group(event.currentTarget);
			var ds:DragSource = new DragSource();
			ds.addData(dragInitiator, "renderer");               
			
			if ( SlidesUtilities.pickUpWholeBundleForDrag(event,dragInitiator,ds,_unwantedSlidesAC,_loadedAnySlidesMap) )
			{
				// do nothing above function took care of it
			}else{
				DragManager.doDrag(dragInitiator as UIComponent, ds, event);	
			}
			
		}
		
		
		//================================================================================================
		// WORKER FUNCTIONS
		//================================================================================================
		
		
		protected function makeUnwantedHGroupRow():HGroup{
			var hgRow:HGroup= new HGroup();
			hgRow.width = 290;
			hgRow.gap = 7;
			return hgRow;
		}
		
		public function getVisibleHeight():Number{
			var visibleHeight:Number;
			var numberOfRows:uint = Math.floor(_unwantedSlidesAC.length / 2) 
				// if its just .5 make it 1
			if ( _unwantedSlidesAC.length == 1 )
			{
				numberOfRows = 1;
			}
			visibleHeight =  numberOfRows * (83 + 10); // thumbnail is 83 high and vertical gap = 10
			return visibleHeight;	
		}
		
		public function cleanSlate():void{
			unwantedSlidesVGroup.removeAllElements();
		}
		
		//================================================================================================
		// ARROW CLICK
		//================================================================================================
//		
//		[Embed(source="assets/images/whitearrow.png")]
//		public const WHITE_ARROW:Class;
//		
//		[Embed(source="assets/images/bluearrow.png")]
//		public const BLUE_ARROW:Class;
		
//		[Embed (source="assets/images/whitearrow_open.png")]
//		public const WHITE_ARROW_OPEN:Class;
//		
//		[Embed (source="assets/images/whitearrow_closed.png")]
//		public const WHITE_ARROW_CLOSED:Class;
		
		private var _index:Number;
		public function arrowImage_clickHandler(event:MouseEvent):void
		{
			unwantedSlidesVGroup.visible = ! unwantedSlidesVGroup.visible;
			var positionY:Number;
			var _scrollerHeight:*;
						
		  if(event!=null){
			if(unwantedSlidesVGroup.parent is ScrollerSkin)
			{ 
				if((unwantedSlidesVGroup.parent as ScrollerSkin).parent is Scroller){							
					if (((unwantedSlidesVGroup.parent as ScrollerSkin).parent as Scroller).parent is UnwantedOptionalTile){
				
	
							if((((unwantedSlidesVGroup.parent as ScrollerSkin).parent as Scroller).parent as UnwantedOptionalTile).parent is OptionalDecksManager){									
								
									var odm:OptionalDecksManager = ((((unwantedSlidesVGroup.parent as ScrollerSkin).parent as Scroller).parent as UnwantedOptionalTile).parent as OptionalDecksManager);
									var odmCustomize:CustomizeView = odm.parent.parent as CustomizeView;
								//	var odmCustomizeSpecs = odmCustomize.unwantedCoreTile.unwantedSlidesVGroup.height;//contentHeight;
								//	var odmCustomizeSpecs:* = odmCustomize.unwantedGroup.height;									
							
									for(_index=0; _index< odm._unwantedOptionalTilesAC.length;_index++){
										   																																	
											//if(_index==0){
											//	odm._unwantedOptionalTilesAC[_index].y = odmCustomizeSpecs;
										//	}
											if(_index>0){
												positionY = odm._unwantedOptionalTilesAC[_index-1].unwantedSlidesVGroup.contentHeight;
												//if(odm._unwantedOptionalTilesAC[_index-1].unwantedSlidesVGroup.contentHeight!=0){
												if( odm._unwantedOptionalTilesAC[_index-1].unwantedSlidesVGroup.visible == true){
													odm._unwantedOptionalTilesAC[_index].y =odm._unwantedOptionalTilesAC[_index-1].y+(odm._unwantedOptionalTilesAC[_index-1]._unwantedOptionalScroller.height+70);//(odm._unwantedOptionalTilesAC[_index-1].unwantedSlidesVGroup.contentHeight+70);
														//;
													
													//trace("Adding Numbers for Content Height INDEX : "+_index+"  "+(positionY+70));
												}
												else{
													odm._unwantedOptionalTilesAC[_index].y = odm._unwantedOptionalTilesAC[_index-1].y+70;
												}
												
											}											
									//		trace("*****8New Positions optionalDECK "+" "+odmCustomize.optionalDecksManager.y);
										//	trace("HEIGHT LOOP "+_index+" "+odm._unwantedOptionalTilesAC[_index].unwantedSlidesVGroup.contentHeight);
											//trace("CONTENT HEIGHT LOOP "+_index+" "+odm._unwantedOptionalTilesAC[_index].unwantedSlidesVGroup.height);
										}// for loop
									
										
								
							}// end if to check component for OptionalDeckManager
					}// end if checking UnwantedOptionalTile
					
				}//end if for checking for Scroller
			}// end if checkin for ScrollerSkin
		  }//end if statement for detecting mouse null
		
		
			//trace("unwanted slides vgroup.height = " + unwantedSlidesVGroup.height);
			if ( unwantedSlidesVGroup.visible == true )
			{
				populateUnwantedSlides();
				/*setTimeout(function():void{
				
				var se:SlidesEvent = new SlidesEvent(SlidesEvent.OPTIONAL_DECK_SHOWN);
				se.newHeight = unwantedSlidesVGroup.height;
				dispatchEvent(se);
				},300);*/
			}
			else
			{
				unwantedSlidesVGroup.removeAllElements();
			//	dispatchEvent(new SlidesEvent(SlidesEvent.OPTIONAL_DECK_HIDDEN));
			}
			
			
			//unwantedSlidesVGroup.includeInLayout = unwantedSlidesVGroup.visible;
		//	trace("Main unwantedVgroup Height "+unwantedSlidesVGroup.height);
		//	trace("Main unwantedVgroup visible "+ unwantedSlidesVGroup.visible );
		/*	if ( unwantedSlidesVGroup.visible && unwantedSlidesVGroup.height>0 )
			{				trace("Arrow is Open State");
				//arrowImage.rotation = 0;
				arrowImage.source = WHITE_ARROW_OPEN;
			}
			else
		{   
				trace("Arrow is closed State");
			//	arrowImage.rotation = 90;
				arrowImage.source = WHITE_ARROW_CLOSED;
			}			*/
		}		
		
		//================================================================================================
		// GETTERS AND SETTERS
		//================================================================================================
		protected function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}	
		
	}
}



				
			