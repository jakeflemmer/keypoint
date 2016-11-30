package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.MultipleSlideDragger;
	
	import flash.data.SQLStatement;
	import flash.display.Bitmap;
	import flash.events.MouseEvent;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;
	import mx.core.DragSource;
	import mx.core.UIComponent;
	import mx.events.DragEvent;
	import mx.managers.DragManager;
	
	import spark.components.Group;
	import spark.primitives.Graphic;
	import spark.primitives.supportClasses.GraphicElement;
	
	public class SlidesUtilities
	{
		public function SlidesUtilities()
		{
		}
		public static function slideIsVideo(slideObject:Object):Boolean{
			var slidesAlone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone", "slide_id" , slideObject.slide_id);
			var slideAlone:Object = slidesAlone[0];
			if ( slideAlone.hasOwnProperty("flv") && (slideAlone.flv as String).length > 0 && slideAlone.flv != "undefined")
			{
				return true;
			}
			else{
				return false;
			} 
		}
		public static function slideIsSwf(slideObject:Object):Boolean{
			var slidesAlone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone", "slide_id" , slideObject.slide_id);
			var slideAlone:Object = slidesAlone[0];
			if ( slideAlone.hasOwnProperty("swf") && (slideAlone.swf as String).length > 0 )
			{					
				return true;
			}else{
				return false;
			} 
		}
		
		public static function slideIsAnimatingSwf(slideObject:Object):Boolean{
			var slidesAlone:Array = dbModel.getWhere(dbModel.systemSQLConnection, "slides_alone", "slide_id" , slideObject.slide_id);
			var slideAlone:Object = slidesAlone[0];
			if ( slideAlone.hasOwnProperty("is_animated") && slideAlone.is_animated )
			{					
				return true;
			}else{
				return false;
			} 
		}
		
		public static function slideIsBundledSlide(slide:Object):Boolean{
			if ( slide.bundle_id && slide.bundle_id > 0 )
			{
				return true;
			}else{
				return false;
			}
		}
		public static function bundledSlideIsInKeepWholeBundle(slide:Object):Boolean{
			var bundlesFromDataBase:Array = dbModel.getWhere(dbModel.systemSQLConnection,"bundles","bundle_id",slide.bundle_id);
			if ( bundlesFromDataBase.length != 1 )
			{
				Alert.show("ERROR how can there be more than one bundle with this bundle id?","ERROR");
				throw new Error("ERROR how can there be more than one bundle with this bundle id?");
				return null;
			}
			var bundleFromDataBase:Object = bundlesFromDataBase[0];
			if ( bundleFromDataBase.keep_whole == true )
			{
				return true;
			}else{
				return false;
			}
		}
		public static function bundledSlideIsInSequentialBundle(slide:Object):Boolean{
			var bundlesFromDataBase:Array = dbModel.getWhere(dbModel.systemSQLConnection,"bundles","bundle_id",slide.bundle_id);
			if ( bundlesFromDataBase.length != 1 )
			{
				Alert.show("ERROR how can there be more than one bundle with this bundle id?","ERROR");
				throw new Error("ERROR how can there be more than one bundle with this bundle id?");
				return null;
			}
			var bundleFromDataBase:Object = bundlesFromDataBase[0];
			if ( bundleFromDataBase.is_sequential == true )
			{
				return true;
			}else{
				return false;
			}
		}
		public static function bundledSlideIsInAdjacentBundle(slide:Object):Boolean{
			var bundlesFromDataBase:Array = dbModel.getWhere(dbModel.systemSQLConnection,"bundles","bundle_id",slide.bundle_id);
			if ( bundlesFromDataBase.length != 1 )
			{
				Alert.show("ERROR how can there be more than one bundle with this bundle id?","ERROR");
				throw new Error("ERROR how can there be more than one bundle with this bundle id?");
				return null;
			}
			var bundleFromDataBase:Object = bundlesFromDataBase[0];
			if ( bundleFromDataBase.is_adjacent == true )
			{
				return true;
			}else{
				return false;
			}
		}
		public static function getAllSlidesWithBundleId(bundleId:uint,slidesArray:Array):Array{
			if ( ! slidesArray )
			{
				trace("whoa");
			}
			var slidesWBundleId:Array = new Array();
			for ( var i:uint = 0 ; i < slidesArray.length; i++ )
			{
				var wantedSlide:Object = slidesArray[i];
				if ( wantedSlide.bundle_id == bundleId )
				{
					slidesWBundleId.push(wantedSlide);
				}
			}
			return slidesWBundleId;			
		}
		public static function idIsBundleId(anId:Number):Boolean{
			var bundlesFromDataBase:Array = dbModel.getWhere(dbModel.systemSQLConnection,"bundles","bundle_id",anId);
			if ( bundlesFromDataBase.length > 0 )
			{
				return true;
			}else{
				return false;
			}
		}
		
		public static function bundleIsInWantedSide(bundleId:Number,wantedSlides:Array):Boolean{
			for ( var i:uint = 0 ; i < wantedSlides.length; i++)
			{
				var slide:Object = wantedSlides[i];
				if ( slide.bundle_id == bundleId)
				{
					return true;
				}
			}
			return false;
		}
		
		public static function getDropSpotColumn(newX:Number,dragDropRedLine:GraphicElement=null):uint{
			//trace("new x " + newX);
			if ( newX < 76 + 15 )
			{
				if (dragDropRedLine) dragDropRedLine.x = 300 + 26;
				return 0;
			}
			else if ( newX >= 76 + 15 && newX < 152 + 76 + 15 )
			{
				if (dragDropRedLine) dragDropRedLine.x = 300 + 167 + 26;
				return 2;
			}
			else if ( newX >= 152 + 76 + 15 && newX < (167*2) + 76 + 15 )
			{
				if (dragDropRedLine) dragDropRedLine.x = 300 + (167*2) + 26;
				return 4;
			}
			else if ( newX >= (167*2) + 76 + 15 && newX < (167*3) + 76 + 15 )
			{
				if (dragDropRedLine) dragDropRedLine.x = 300 + (167*3) + 26;
				return 6;
			}
			else if ( newX >= (167*3) + 76 + 15 )
			{
				if (dragDropRedLine) dragDropRedLine.x = 300 + (167*4) + 26;
				return 8;
			}	
			else return 1000;
		}
		
		public static function getDropSpotRow(newY:Number, localY:Number = 0 ,  dragDropRedLine:GraphicElement = null ):uint{
			if ( localY > 0 && dragDropRedLine ) dragDropRedLine.y = localY;
			var row:uint;
			row = Math.floor( newY / ( 93 + 15 ) ); 
			return row;
		}
		
		public static function getCustomSequenceNumberOfNewDropSpot(event:DragEvent):uint{
			
			var newX:Number = UIComponent(event.currentTarget).mouseX;
			var newY:Number = UIComponent(event.currentTarget).mouseY;
			
			var column:uint = getDropSpotColumn(newX);
			var row:uint = getDropSpotRow(newY);
			
			if ( row  < 1000 && column < 1000)
			{
				var potentialCustomSequence:uint = column + ( row * 8 );
				return potentialCustomSequence;
			}
			return 1000000;
		}
		
		public static function  slideIsOptionalSlide(unsplitSlide:Object):Boolean{
			if ( unsplitSlide.optional_deck_id > 0 )
			{
				return true;
			}
			else {
				return false;
			}
		}
		public static function  getSlideInBundleWithLowestCustomSequenceNumber(slides:Array):Object{
			var lowestCustomSequenceNumber:uint = 1000000;
			var slideWithLowestCustomSequence:Object;
			for ( var i :uint = 0 ; i < slides.length; i++ )
			{
				var slide:Object = slides[i];
				if ( slide.customSequence < lowestCustomSequenceNumber)
				{
					lowestCustomSequenceNumber = slide.customSequence;
					slideWithLowestCustomSequence = slide;
				}
			}
			return slideWithLowestCustomSequence;
		}
		public static function  getSlideInSequentialBundleWithLowestBundleSequenceNumber(slides:Array):Object{
			var lowestBundleSequenceNumber:uint = 1000000;
			var slideWithLowest:Object;
			for ( var i :uint = 0 ; i < slides.length; i++ )
			{
				var slide:Object = slides[i];
				if ( slide.bundle_position < lowestBundleSequenceNumber)
				{
					lowestBundleSequenceNumber = slide.bundle_position;
					slideWithLowest = slide;
				}
			}
			return slideWithLowest;
		}
		
		
		public static function slideIsBeingDroppedBetweenAdjacentBundledSlides(slide:Object, newCustomSequenceNumber:uint, slidesArray:Array):Boolean 
		{
			// is it an adjacent bundle ?
			var i:uint = 0;
			var slideWithNextHighestCustomSequence:Object;
			var slideWithNextLowestCustomSequence:Object;
			var wantedSlide:Object;
			// look at the slide on either side
			for ( i = 0 ; i < slidesArray.length; i++)
			{
				wantedSlide = slidesArray[i];									
				if ( wantedSlide.customSequence == newCustomSequenceNumber - 1 )
				{
					slideWithNextLowestCustomSequence = wantedSlide;
				}
				if ( wantedSlide.customSequence == newCustomSequenceNumber + 1 )
				{
					slideWithNextHighestCustomSequence = wantedSlide;
				}
			}
			if ( ! slideWithNextHighestCustomSequence || ! slideWithNextLowestCustomSequence )
			{
				return false;
			}
			// are they both in the same bundle ?
			if ( SlidesUtilities.slideIsBundledSlide(slideWithNextHighestCustomSequence) && slideWithNextHighestCustomSequence.bundle_id ==  slideWithNextLowestCustomSequence.bundle_id )
			{
				//is this bundle an adjacent bundle ?
				if ( bundledSlideIsInAdjacentBundle(slideWithNextHighestCustomSequence) )
				{
					// and the slide being dropped is not also in this bundel ?
					if ( slide.bundle_id != slideWithNextHighestCustomSequence.bundle_id )
					{
						return true;
					}					
				}				
			}
			return false;
		}
		
		
		public static function pickUpWholeBundleForDrag(event:MouseEvent,dragInitiator:Object,ds:DragSource,_slidesAC:ArrayCollection,_loadedSlidesMap:Object):Boolean{
			
			if ( dragInitiator.hasOwnProperty("slide"))
			{
				var slide:Object = dragInitiator.slide;				
				if ( SlidesUtilities.slideIsBundledSlide(slide) )
				{
					if ( SlidesUtilities.bundledSlideIsInSequentialBundle(slide) )
					{
						if ( SlidesUtilities.bundledSlideIsInAdjacentBundle(slide) )
						{
							var multipleSlideDragger:MultipleSlideDragger = new MultipleSlideDragger();
							
							// TODO
							// we need to get the real images
							// if its a keep whole bundle then just grab all the slides w same bundle id
							// if its not keep whole then if its wanted takke all the wanted slides w same bundle id
							// if its not keep whole then
							// if its wanted take all the wanted slides w same bundle id
							// if its unwanted core take all unwanted core w same bunble id
							// if its unwanted optional take all unwanted optional w same bundle id
							var arrayToGetTheOtherSlidesInBundleFrom:Array;
							//							if ( ! SlidesUtilities.bundledSlideIsInKeepWholeBundle(slide) )
							//							{
							//								if ( slide.unwanted == false )
							//								{
							//									arrayToGetTheOtherSlidesInBundleFrom = _wantedSlidesAC.source;
							//								}else{
							//									if ( SlidesUtilities.slideIsOptionalSlide(slide) )
							//									{
							//										arrayToGetTheOtherSlidesInBundleFrom = _unwantedOptionalSlidesAC.source;
							//									}else{
							//										arrayToGetTheOtherSlidesInBundleFrom = _unwantedCoreSlidesAC.source;
							//									}
							//								}
							//							}else{
							//								arrayToGetTheOtherSlidesInBundleFrom = _unsplitSlidesAC.source;
							//							}
							arrayToGetTheOtherSlidesInBundleFrom = _slidesAC.source;
							var otherSlidesInThisBundle:Array = SlidesUtilities.getAllSlidesWithBundleId(slide.bundle_id,arrayToGetTheOtherSlidesInBundleFrom);
							var imagesArray:Array = new Array();
							for ( var i:uint = 0 ; i < otherSlidesInThisBundle.length; i++)
							{
								var otherSlide:Object = otherSlidesInThisBundle[i];
								var bitmap:Bitmap = _loadedSlidesMap[otherSlide.slide_id] as Bitmap;
								imagesArray.push(bitmap);
							}
							multipleSlideDragger.addSlideImages(imagesArray);
							DragManager.doDrag(dragInitiator as UIComponent, ds, event, multipleSlideDragger,70,70,1.00);
							return true;
						}
					}
				}
			}
			return false;	
		}
		
		public static function removeSlideFromSlideArrayCollection(slide:Object,slideArray:ArrayCollection):void{
			for ( var i :uint = 0 ; i < slideArray.length; i++)
			{
				var nextSlide:Object = slideArray[i];
				if ( nextSlide.sec_slide_id_plus_cust_pres_id == slide.sec_slide_id_plus_cust_pres_id )
				{
					slideArray.removeItemAt(i);
					return;
				}
			}
		}
		
		public static function testSlidesAloneDataTableForV3Compatability(comingFromUpdatedCall:Boolean = false):Boolean{
			
			var slidesAloneArray:Array = dbModel.getAllSlides(dbModel.systemSQLConnection);
			if ( slidesAloneArray && slidesAloneArray.length > 0 )
			{
				// hey if one slide has the property then presumably they all do so we just have to check the first one
				var slide:Object = slidesAloneArray[0];
				if ( slide.hasOwnProperty("is_animated") && slide.is_animated != null )
				{
					return true;							
				}else{
					return false;
				}
				
			}else{
				if ( comingFromUpdatedCall )
				{
					Alert.show(DatabaseModel.MESSAGE_40,"Attention");
					//throw new Error(DatabaseModel.MESSAGE_40);
				}else{
					return false;	// okay there are no slides in the table so might as well drop
					// and create V3 compatible table for this new user to be on safe side
				}
			}
			return false;
		}
		
		///Aditional Slide Rules for New Bundle Rule  (AFTER VERSION 3)
		public static function  getSlideInBundleWithHighestCustomSequenceNumber(slides:Array):Object{
			var highestCustomSequenceNumber:uint = 0;
			var slideWithHighestCustomSequence:Object;
			for ( var i :uint = 0 ; i < slides.length; i++ )
			{
				var slide:Object = slides[i];
				if ( slide.customSequence > highestCustomSequenceNumber)
				{
					highestCustomSequenceNumber = slide.customSequence;
					slideWithHighestCustomSequence = slide;
				}
			}
			return slideWithHighestCustomSequence;
		}
		
		public static function isSlideInNonSequentiallyLockedBundle(slide:Object):Boolean{
			if ( slideIsBundledSlide(slide) )
			{
				if ( bundledSlideIsInSequentialBundle(slide) )
				{
					return false;
				}else{
					return true;
				}
			}else{
				return false;
			}
		}
		
		public static function  getSlideInBundleWithLowestSequenceNumber(slides:Array):Object{
			var lowestSequenceNumber:uint = 1000000;
			var slideWithLowestSequence:Object;
			for ( var i :uint = 0 ; i < slides.length; i++ )
			{
				var slide:Object = slides[i];
				if ( slide.sequence < lowestSequenceNumber)
				{
					lowestSequenceNumber = slide.sequence;
					slideWithLowestSequence = slide;
				}
			}
			return slideWithLowestSequence;
		}
		
		public static function  getSlideWithNextLowestSequenceNumber(sequenceNumber:uint,slides:Array):Object{
			var nextLowestSequenceNumber:uint = 0;
			var slideWithNextLowestSequence:Object;
			for ( var i :uint = 0 ; i < slides.length; i++ )
			{
				var slide:Object = slides[i];
				if ( slide.sequence > nextLowestSequenceNumber && slide.sequence < sequenceNumber )
				{
					nextLowestSequenceNumber = slide.sequence;
					slideWithNextLowestSequence = slide;
				}
			}
			return slideWithNextLowestSequence;
		}
		
		public static function returnNonSequenceLockedBundleInSequenceLockedDeckToOriginalSequence(allSlidesInBundle:Array,newCustomSequenceNumber:Number = 0):void{
			// ok so we have an array of slide in a bundle
			// the whole bundle must go at the spot of the lowest custom sequence number
			// and they must be returned to their original sequence within the bundle
			// so first find the lowest custom sequence number
			var lowestCustomSequenceSlide:Object = getSlideInBundleWithLowestCustomSequenceNumber(allSlidesInBundle);
			var lowestCustomSequenceNumber:Number = lowestCustomSequenceSlide.customSequence;
			
			// * NB : we lower the lowestCustomSequence number by one to prevent the whole bundle moving up the deck to the end (positionaly )
			lowestCustomSequenceNumber -= 1;
			
			// then order the array by their sequence number
			allSlidesInBundle.sortOn("sequence",Array.NUMERIC);
			
			// then make their new custom sequnce numbers reflect that order
			var i :uint = 0;
			for ( i = 0 ; i < allSlidesInBundle.length; i++)
			{
				var nextSlideInBundle:Object = allSlidesInBundle[i];
				if ( newCustomSequenceNumber > 0 )
				{
					nextSlideInBundle.customSequence = newCustomSequenceNumber + i*0.01 + 0.01;
				}else{
					nextSlideInBundle.customSequence = lowestCustomSequenceNumber + i*0.01 + 0.01;	
				}
				
			}
			
		}
		
		public static function allSlidesInThisNonKeepWholeBundleAreAlreadyUnwanted(unwantedSlidesArray:Array, bundleId:uint, presentationId:uint):Boolean{
			
			// okay we need to query the database to get all the slides in this custom presentation with the given bundle id
			var allSlidesInThisPresentation:Array = dbModel.getWhere(dbModel.customSQLConnection,"slides","presentation_id",presentationId);
			var allSlidesInThisBundle:Array = new Array();
			for ( var z:uint = 0 ; z < allSlidesInThisPresentation.length; z++)
			{
				var slide:Object = allSlidesInThisPresentation[z];
				if ( slide.bundle_id == bundleId )
				{
					allSlidesInThisBundle.push(slide);
				}
			}
			// we have the array of all the slides in this bundle
			// we need to check that every one of them is in the unwanted slides array
			var slideInBundleIsInUnwantedArray:Boolean = false;
			for ( var i:uint = 0 ; i < allSlidesInThisBundle.length; i++)
			{
				var slideInBundle:Object = allSlidesInThisBundle[i];
				slideInBundleIsInUnwantedArray = false;
				
				for ( var j:uint = 0 ; j < unwantedSlidesArray.length; j++)
				{
					var unwantedSlide:Object = unwantedSlidesArray[j];
					
					if ( unwantedSlide.sec_slide_id_plus_cust_pres_id == slideInBundle.sec_slide_id_plus_cust_pres_id )
					{
						// this bundled slide is already unwanted
						slideInBundleIsInUnwantedArray = true;
					}
				}
				if ( slideInBundleIsInUnwantedArray )
				{
					// continue - do nothing
				}else{
					// well this bundled slide must still be in wanted slide
					return false;
				}
			}
			return true;
		}
		
		public static function setCustomSequenceNumberOfSlideBeingAddedToWantedSideBasedOnOriginalSequenceNumber(slideBecomingWanted:Object,wantedSlidesArray:Array):void{
			// so we want to find the slide with the next lowest sequence number
			// and make the slide becoming wanted have a custom sequence number .01 higher than that slides customSequence number
			var slideWithNextLowestSequenceNumber:Object = getSlideWithNextLowestSequenceNumber(slideBecomingWanted.sequence, wantedSlidesArray);
			var newCustomSequenceNumber:Number = slideWithNextLowestSequenceNumber.customSequence;
			
			// but if this slide is in an adjacent bundle then put it after the last slide in the bundle
			if ( slideIsBundledSlide(slideWithNextLowestSequenceNumber))
			{
				if ( bundledSlideIsInAdjacentBundle(slideWithNextLowestSequenceNumber))
				{
					var allSlidesInThisBundle:Array = getAllSlidesWithBundleId(slideWithNextLowestSequenceNumber.bundle_id, wantedSlidesArray);
					var slideInBundleWithHighestCustomSequenceNumber:Object = getSlideInBundleWithHighestCustomSequenceNumber(allSlidesInThisBundle);
					newCustomSequenceNumber = slideInBundleWithHighestCustomSequenceNumber.customSequence;
				}
			}
			slideBecomingWanted.customSequence = newCustomSequenceNumber + 0.01;
		}
		
		public static function setCustomSequenceNumberOfSlidesBeingAddedToWantedSideBasedOnOriginalSequenceNumber(slidesArray:Array,wantedSlidesArray:Array):void{
			// so we want to find the slide with the next lowest sequence number
			// and make the slide becoming wanted have a custom sequence number .01 higher than that slides customSequence number
			var slideWithLowestSequenceNumber:Object = getSlideInBundleWithLowestSequenceNumber(slidesArray);
			
			var slideWithNextLowestSequenceNumber:Object = getSlideWithNextLowestSequenceNumber(slideWithLowestSequenceNumber.sequence, wantedSlidesArray);
			
			// if this slideWithNextLowestSequenceNumber is in a sequence unlocked bundle then rather take the highest custom sequence number 
			// of this sequence unlocked bundle
			if ( slideIsBundledSlide(slideWithNextLowestSequenceNumber) )
			{
				if ( bundledSlideIsInSequentialBundle(slideWithNextLowestSequenceNumber) == false )
				{
					var allTheSlidesInBundleBeingPlacedAfter:Array = getAllSlidesWithBundleId(slideWithNextLowestSequenceNumber.bundle_id,wantedSlidesArray);
					slideWithNextLowestSequenceNumber = getSlideInBundleWithHighestCustomSequenceNumber(allTheSlidesInBundleBeingPlacedAfter);
				}
			}
			
			var nextLowestCustomSequenceNumber:Number = slideWithNextLowestSequenceNumber.customSequence;
			
			slidesArray.sortOn("sequence", Array.NUMERIC);
			for ( var i : uint = 0 ; i < slidesArray.length; i++ )
			{
				var slide:Object = slidesArray[i];
				slide.customSequence = nextLowestCustomSequenceNumber + 0.01 + ( i * 0.01 );
			}
			
		}
		
		
		
		
		//====================================================
		
		
		public static function titleSlideNameHasBeenChanged(tsName:String):Boolean{
			if ( tsName == "<PRESENTER'S NAME>" )
			{
				return false;
			}else{
				return true;
			}
		}
		
		
		//==========================================================
		// V6 PRE PROCESS DECKS TO APPLY EITHER OR BUNDLE RULES
		
		public static function putTheWantedPropertyOntoEachSlideOfEitherOrBundle(allSlides:Array, allCombos:Array):void{
			// all slides in this case should only be optional slides that we loaded that match the presentation Id for this core deck
			// we put unwanted is false on all object two items an
			//var allCombos:Array = dbModel.getWhere(dbModel.systemSQLConnection, 'either_or_combinations', 'presentation_id' , _presentationObject.presentation_id);
			
			if ( allCombos && allCombos.length > 0 )
			{
				// first set all the slides unwanted to true - we will select the approprate ones to set false
				for ( var i:uint = 0 ; i < allSlides.length; i++)
				{
					var s:Object = allSlides[i];
					s.unwanted = true;
				}
				
				for ( var c:uint = 0 ; c < allCombos.length; c ++)
				{
					var eachCombo:Object = allCombos[c];
					
					// we also want to make the wanted property of the first slide / bundle true
					for ( var count:uint = 0 ; count < allSlides.length; count ++ )
					{
						var aSlide:Object = allSlides[count];
						if ( aSlide.optional_deck_id < 1 )
						{
							trace("error processing optional slides for either or bundles");
						}
						if ( SlidesUtilities.slideIsBundledSlide(aSlide) )
						{
							if ( aSlide.bundle_id == eachCombo.object_one_object_id)
							{
								aSlide.unwanted = false;	
							}
						}else if (aSlide.section_slide_id == eachCombo.object_one_object_id )
						{
							aSlide.unwanted = false;
						}	
					}
				}
			}else {
				return;
			}
			
		}
		
		public static function preProcessCoreDecksForEitherOrBundleRule(presentationsData:Object): void{
			/*
			// now we simply want to return an array of slides that are the object ones of the either or combo bundles
			var optionalSlideToAddToCoreDeck:Array = new Array();
			// get the combos associated to this presentation
			var combos:Array = dbModel.getWhere(dbModel.systemSQLConnection, "either_or_combinations", "presentation_id" , presentationId );
			if ( ! combos || combos.length < 1 )
			{
				return null;
			}
			// get all the optional slides associated to this presentation
			var optionalSlidesToLoad:Array = SlidesUtilities.getAllTheOptionalSlidesAssociatedToCorePresentation(presentationId);
			// walk through all the combos and pull out all the object one slides
			SlidesUtilities.putTheWantedPropertyOntoEachSlideOfEitherOrBundle(optionalSlidesToLoad,combos);
			
			// lastly walk through the optional slides and pull out those whose wnated property = true
			for ( var t:uint = 0 ; t < optionalSlidesToLoad.length; t++)
			{
				var topt:Object = optionalSlidesToLoad[t];
				if ( topt.unwanted == false )
				{	
					optionalSlideToAddToCoreDeck.push(topt);
				}
			} 							
			
			return optionalSlideToAddToCoreDeck;
			*/
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			
			//we need to pass in a presentation id
			//and pull the appropriate combinations in from database
			
			trace("pre processing core decks");
			
			if( presentationsData.Presentations.length > 0 ) { 
				var presentation:Object;
				for( i = 0; i < presentationsData.Presentations.length; i++ ) { 
					
					presentation = presentationsData.Presentations[i];
					
					var comboInsertStatement:SQLStatement = new SQLStatement();
					comboInsertStatement.sqlConnection = dbModel.systemSQLConnection;
					
					if ( presentation.combinations && presentation.combinations.length  > 0 )
					{
						//for ( j = 0; j < presentation.combinations.length; j++)
						//{
						//var combo:Object = presentation.combinations[j];
						
						// now we have a presentation in our hands that we need to preprocess
						var optionalSlidesToLoad:Array = SlidesUtilities.getAllTheOptionalSlidesAssociatedToCorePresentation(presentation.id);
						
						SlidesUtilities.putTheWantedPropertyOntoEachSlideOfEitherOrBundle(optionalSlidesToLoad,presentation.combinations as Array);
						
						SlidesUtilities.cleanAllSlidesMandatoryProperty(optionalSlidesToLoad);
						//INSERT THESE OPTIONAL SLIDES WITH THEIR ASSOCIATED PRESENTATION OBJECT ID
						
						var optionalObjectOnes:Array = new Array();
						for ( var t:uint = 0 ; t < optionalSlidesToLoad.length; t++)
						{
							var topt:Object = optionalSlidesToLoad[t];
							if ( topt.unwanted == false )
							{
								if ( topt.bundle_id > 0 )
								{
									trace("adding either or optional slide to core deck : bundle id : " + topt.bundle_id + "  : " + presentation.presentation_name);
								}
								else{
									trace("adding either or optional slide to core deck : slide id : " + topt.slide_id + "  : " + presentation.presentation_name);	
								}
								
								optionalObjectOnes.push(topt);
							}
						}
						//dbModel.insertAnArrayOfSlidesIntoCoreSlidesTable(optionalSlidesToLoad,0,presentation.id);
						dbModel.insertAnArrayOfSlidesIntoCoreSlidesTable(optionalObjectOnes,0,presentation.id);
						
						//}
					}
				}
			}
		}
		
		
		public static function getAllTheOptionalSlidesAssociatedToCorePresentation(presentationId:uint):Array{
			// get all the optional decks associated to this presentation
			// get all the slides from the optional_slides table that match those optional decks
			var allOptionalSlides:Array = new Array();			
			
			var optionalDeckAssociationsWithThisPresentationId:Array = dbModel.getWhere(dbModel.systemSQLConnection,"optional_deck_ids_relation_to_presentation_ids","presentation_id",presentationId);
			if ( optionalDeckAssociationsWithThisPresentationId && optionalDeckAssociationsWithThisPresentationId.length > 0)
			{
				for ( var i:uint = 0 ; i< optionalDeckAssociationsWithThisPresentationId.length; i++)
				{
					var optionalDeckAssoc:Object = optionalDeckAssociationsWithThisPresentationId[i];
					if ( optionalDeckAssoc.presentation_id == presentationId )
					{
						var optionalSlides:Array = dbModel.getWhere(dbModel.systemSQLConnection,"optional_slides","optional_deck_id",optionalDeckAssoc.optional_deck_id);
						if ( optionalSlides && optionalSlides.length > 0 )
						{
							for ( var j:uint = 0 ; j < optionalSlides.length; j++)
							{
								var optionalSlide:Object = optionalSlides[j];
								optionalSlide.optional_deck_id = optionalDeckAssoc.optional_deck_id; // TODO this should not be necessary
								allOptionalSlides.push(optionalSlide);
							}
						}
					}
				}
			}
			return allOptionalSlides;
		}
		
		
		public static function clonePresentationObject( po:Object):Object{
			var presentationObject:Object = new Object();
//			presentationObject.brand_id = po.brand_id;
//			presentationObject.custom_presentation_id = po.custom_presentation_id;
//			presentationObject.custom_title = po.custom_title;
			for (var item:* in po){
				presentationObject[item] = po[item];
			}
				
			
			return presentationObject;
		}
		
		
		
		
		
		
		
		//======================================================================================================
		//   GETTERS AND SETTERS
		//======================================================================================================
		
		public static function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
		//CLEAN MANDATORY SLIDE
		public static function cleanSlidesMandatoryProperty(slide:Object):void{
			if ( slide.hasOwnProperty("is_mandatory") && slide.hasOwnProperty("mandatory") )
			{
				// fine this slide is already clean
				return;
			}else if ( slide.hasOwnProperty("is_mandatory") )
			{
				slide.mandatory = slide.is_mandatory;
			}else if ( slide.hasOwnProperty("mandatory") )
			{
				slide.is_mandatory = slide.mandatory;
			}else{
				slide.is_mandatory = false;
				slide.mandatory = false;
			}
		}
		public static function cleanAllSlidesMandatoryProperty(allSlides:Array):void{
			for ( var i:uint = 0 ; i < allSlides.length ; i++ ) {
				var eachSlide:Object = allSlides[i];
				cleanSlidesMandatoryProperty(eachSlide);
			}
		}

		
	}
}